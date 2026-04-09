import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
import ImageIO
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
private func _dtAnimatedGIFFrameDuration(_ source: CGImageSource, _ index: Int) -> Int {
    var frameDuration = 10
    guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
          let gifProperties = frameProperties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
        return frameDuration
    }

    if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
        frameDuration = Int(unclampedDelay.floatValue * 100)
    } else if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
        frameDuration = Int(delay.floatValue * 100)
    }

    if frameDuration < 1 { frameDuration = 10 }
    return frameDuration
}

private func _dtGCD(_ a: Int, _ b: Int) -> Int {
    var a = a, b = b
    if a < b { swap(&a, &b) }
    let r = a % b
    return r != 0 ? _dtGCD(b, r) : b
}

private func _dtAnimatedGIFFromFile(_ path: String) -> UIImage? {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

    let count = CGImageSourceGetCount(source)
    if count <= 1 {
        return nil
    }

    var gcf = _dtAnimatedGIFFrameDuration(source, 0)
    for i in 1..<count {
        gcf = _dtGCD(gcf, _dtAnimatedGIFFrameDuration(source, i))
    }

    var frames = [UIImage]()
    for i in 0..<count {
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
        let frame = UIImage(cgImage: cgImage)
        let repeatCount = _dtAnimatedGIFFrameDuration(source, i) / gcf
        for _ in 0..<repeatCount {
            frames.append(frame)
        }
    }

    let duration = TimeInterval(frames.count) * TimeInterval(gcf) / 100.0
    return UIImage.animatedImage(with: frames, duration: duration)
}
#endif

private let imageCache = NSCache<NSString, DTImage>()

/// A specialized subclass in the TextAttachment class cluster to represent an embedded image.
@objc(DTImageTextAttachment)
open class ImageTextAttachment: TextAttachment, TextAttachmentDrawing, TextAttachmentHTMLPersistence {

    private var _image: DTImage?

    // MARK: - NSCoding

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _image = aDecoder.decodeObject(forKey: "image") as? DTImage
    }

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(_image, forKey: "image")
    }

    public override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }

    @objc public init(image: DTImage) {
        super.init(data: nil, ofType: nil)
        self.image = image
    }

    @objc open override func configured(with element: HTMLElement, options: NSDictionary?) -> Self {
        let result = super.configured(with: element, options: options)
        result._decodeImage(from: element, options: options as? [String: Any])
        return result
    }

    // MARK: - Image Decoding

    private func _decodeImage(from element: HTMLElement, options: [String: Any]?) {
        let baseURL = options?[NSAttributedString.documentReadingOptionKey_baseURL] as? URL
            ?? (options as NSDictionary?)?[NSBaseURLDocumentOption as String] as? URL
        let src = (element.attributes as? [String: Any])?["src"] as? String

        var contentURL: URL? = nil

        // decode content URL
        if let src = src, !src.isEmpty {
            if src.hasPrefix("data:") {
                let cleanStr = src.components(separatedBy: .whitespacesAndNewlines).joined()

                let dataURL = URL(string: cleanStr)

                // try native decoding first
                var decodedData: Data? = nil
                if let dataURL = dataURL {
                    decodedData = try? Data(contentsOf: dataURL)
                }

                // try own base64 decoding
                if decodedData == nil {
                    if let range = cleanStr.range(of: "base64,") {
                        let encodedData = String(cleanStr[range.upperBound...])
                        decodedData = Data(base64Encoded: encodedData, options: .ignoreUnknownCharacters)
                    }
                }

                // if we have image data, get the default display size
                if let decodedData = decodedData {
                    var decodedImage = DTImage(data: decodedData)

                    // we don't know the content scale from such images, need to infer it from size in style
                    if let stylesStr = (element.attributes as? [String: Any])?["style"] as? String {
                        let attributes = (stylesStr as NSString).dictionaryOfCSSStyles() as? [String: String]

                        if let widthStr = attributes?["width"],
                           let heightStr = attributes?["height"],
                           widthStr.hasSuffix("px"), heightStr.hasSuffix("px") {

                            var sizeAccordingToStyle = CGSize.zero
                            sizeAccordingToStyle.width = (widthStr as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: 0, textScale: 1)
                            sizeAccordingToStyle.height = (heightStr as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: 0, textScale: 1)

                            if let decodedImage = decodedImage,
                               sizeAccordingToStyle.width != 0, sizeAccordingToStyle.width < decodedImage.size.width,
                               sizeAccordingToStyle.height != 0, sizeAccordingToStyle.height < decodedImage.size.height {

                                let scale = round(decodedImage.size.width / sizeAccordingToStyle.width)

                                if scale >= 2.0 && scale <= 5.0 {
                                    #if canImport(UIKit)
                                    decodedImage = DTImage(cgImage: decodedImage.cgImage!, scale: scale, orientation: decodedImage.imageOrientation)
                                    #else
                                    decodedImage?.size = sizeAccordingToStyle
                                    #endif
                                }
                            }
                        }
                    }

                    self.image = decodedImage
                    // prevent remote loading of image
                    self.contentURL = nil
                }
            } else {
                // normal URL
                contentURL = URL(string: src)

                if contentURL == nil {
                    let encoded = (src as NSString).stringByAddingHTMLEntities()
                    contentURL = URL(string: encoded, relativeTo: baseURL)
                }

                if contentURL == nil {
                    let encoded = src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    if let encoded = encoded {
                        contentURL = URL(string: encoded)
                    }
                }

                if contentURL?.scheme == nil {
                    // possibly a relative url
                    if let baseURL = baseURL {
                        contentURL = URL(string: src, relativeTo: baseURL)
                    } else {
                        // file in app bundle
                        let bundle = Bundle(for: type(of: self))
                        if let path = bundle.path(forResource: src, ofType: nil) {
                            contentURL = URL(fileURLWithPath: path)
                        } else {
                            let bundle2 = Bundle(for: TextAttachment.self)
                            if let path = bundle2.path(forResource: src, ofType: nil) {
                                contentURL = URL(fileURLWithPath: path)
                            }
                        }
                    }
                }
            }
        }

        // if it's a local file we need to inspect it to get its dimensions
        if displaySize.width == 0 || displaySize.height == 0 {
            var checkImage = _image

            // let's check if we have a cached image
            if _image == nil, let urlStr = contentURL?.absoluteString {
                checkImage = imageCache.object(forKey: urlStr as NSString)
            }

            if checkImage == nil {
                // only local files we can directly load without punishment
                if let contentURL = contentURL, contentURL.isFileURL {
                    #if canImport(UIKit)
                    let ext = contentURL.pathExtension.lowercased()
                    if ext == "gif" {
                        checkImage = _dtAnimatedGIFFromFile(contentURL.path)
                    }
                    #endif
                    if checkImage == nil {
                        checkImage = DTImage(contentsOfFile: contentURL.path)
                    }
                }

                // cache that for later
                if let checkImage = checkImage, let urlStr = contentURL?.absoluteString {
                    imageCache.setObject(checkImage, forKey: urlStr as NSString)
                }
            }

            // we have an image, so we can set the original size and default display size
            if let checkImage = checkImage {
                self.contentURL = nil
                _updateSizes(from: checkImage)
            }
        }

        // only remote images should have a URL
        self.contentURL = contentURL
    }

    private func _updateSizes(from image: DTImage) {
        // set original size if there is none set yet
        if _originalSize.equalTo(.zero) {
            _originalSize = image.size
        } else {
            if _originalSize.width == 0 && _originalSize.height != 0 {
                let factor = _originalSize.height / image.size.height
                _originalSize.width = image.size.width * factor
            } else if _originalSize.width != 0 && _originalSize.height == 0 {
                let factor = _originalSize.width / image.size.width
                _originalSize.height = image.size.height * factor
            }
        }

        // initial display size matches original
        if displaySize.equalTo(.zero) {
            setDisplaySize(_originalSize, withMaxDisplaySize: _maxImageSize)
        } else {
            if displaySize.width == 0 && displaySize.height != 0 {
                var newDisplaySize = displaySize
                let factor = displaySize.height / _originalSize.height
                newDisplaySize.width = _originalSize.width * factor
                setDisplaySize(newDisplaySize, withMaxDisplaySize: _maxImageSize)
            } else if displaySize.width != 0 && displaySize.height == 0 {
                var newDisplaySize = displaySize
                let factor = displaySize.width / _originalSize.width
                newDisplaySize.height = _originalSize.height * factor
                setDisplaySize(newDisplaySize, withMaxDisplaySize: _maxImageSize)
            }
        }
    }

    // MARK: - Alternative Representations

    /// Returns a data URL representation (base64 PNG) of the image.
    @objc open func dataURLRepresentation() -> String? {
        guard let image = self.image else { return nil }

        guard let data = image.dataForPNGRepresentation() else { return nil }
        let encoded = data.base64EncodedString()

        return "data:image/png;base64," + encoded
    }

    // MARK: - TextAttachmentDrawing

    @objc open func draw(in rect: CGRect, context: CGContext) {
        self.image?.draw(in: rect)
    }

    // MARK: - TextAttachmentHTMLPersistence

    @objc open func stringByEncodingAsHTML() -> String {
        var retString = ""
        var urlString: String?

        if let contentURL = contentURL {
            if contentURL.isFileURL {
                let path = contentURL.path

                if let range = path.range(of: ".app/") {
                    urlString = String(path[range.upperBound...])
                } else {
                    urlString = contentURL.absoluteString
                }
            } else {
                urlString = contentURL.relativeString
            }
        } else {
            urlString = dataURLRepresentation()
        }

        // output tag start
        retString += "<img"

        // build style for img/video
        var styleString = ""

        switch verticalAlignment {
        case .baseline:
            break
        case .top:
            styleString += "vertical-align:text-top;"
        case .center:
            styleString += "vertical-align:middle;"
        case .bottom:
            styleString += "vertical-align:text-bottom;"
        }

        if _originalSize.width > 0 {
            styleString += String(format: "width:%.0fpx;", _originalSize.width)
        }

        if _originalSize.height > 0 {
            styleString += String(format: "height:%.0fpx;", _originalSize.height)
        }

        // add local style for size, since sizes might vary quite a bit
        if !styleString.isEmpty {
            retString += " style=\"\(styleString)\""
        }

        if let urlString = urlString {
            retString += " src=\"\(urlString)\""
        }

        // attach the attributes dictionary
        if let attrs = attributes as? [String: Any] {
            var tmpAttributes = attrs
            tmpAttributes.removeValue(forKey: "src")
            tmpAttributes.removeValue(forKey: "style")
            tmpAttributes.removeValue(forKey: "width")
            tmpAttributes.removeValue(forKey: "height")

            for key in tmpAttributes.keys {
                let encodedKey = (key as NSString).stringByAddingHTMLEntities()
                let value = "\(tmpAttributes[key]!)"
                let encodedValue = (value as NSString).stringByAddingHTMLEntities()
                retString += " \(encodedKey)=\"\(encodedValue)\""
            }
        }

        // end
        retString += " />"

        return retString
    }

    // MARK: - Properties

    @objc open var image: DTImage? {
        get {
            if _image == nil {
                if let contentURL = contentURL {
                    var cachedImage = imageCache.object(forKey: contentURL.absoluteString as NSString)

                    // only local files can be loaded into cache
                    if cachedImage == nil && contentURL.isFileURL {
                        cachedImage = DTImage(contentsOfFile: contentURL.path)

                        if let cachedImage = cachedImage {
                            imageCache.setObject(cachedImage, forKey: contentURL.absoluteString as NSString)
                        }
                    }

                    return cachedImage
                }
            }
            return _image
        }
        set {
            if _image !== newValue {
                _image = newValue
                if let newValue = newValue {
                    _updateSizes(from: newValue)
                }
            }
        }
    }

    @objc open override var displaySize: CGSize {
        get { return super.displaySize }
        set { super.displaySize = newValue }
    }
}
