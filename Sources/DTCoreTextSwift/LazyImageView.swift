//
//  LazyImageView.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import ImageIO
import DTCoreText
import os.log

private let logger = Logger(subsystem: "com.cocoanetics.DTCoreText", category: "LazyImageView")

// MARK: - Notifications

public extension Notification.Name {
	/// Posted before a lazy image view starts downloading.
	static let dtLazyImageViewWillStartDownload = Notification.Name("DTLazyImageViewWillStartDownloadNotification")
	/// Posted when a lazy image view finishes downloading (check userInfo for errors).
	static let dtLazyImageViewDidFinishDownload = Notification.Name("DTLazyImageViewDidFinishDownloadNotification")
}

// MARK: - Delegate

/// Delegate protocol for `LazyImageView` to report downloaded image dimensions.
@objc(DTLazyImageViewDelegate)
public protocol LazyImageViewDelegate: AnyObject {
	/// Called when the image size becomes known.
	@objc optional func lazyImageView(_ lazyImageView: LazyImageView, didChangeImageSize size: CGSize)
}

// MARK: - LazyImageView

/// A `UIImageView` subclass that lazily loads an image from a URL
/// and informs its delegate once the image size is known.
@objc(DTLazyImageView)
public class LazyImageView: UIImageView, URLSessionDataDelegate {

	// MARK: - Static Cache

	private static let imageCache = NSCache<NSURL, UIImage>()

	// MARK: - Properties

	/// The URL of the remote image.
	@objc public var url: NSURL?

	/// The URL request used for downloading. If nil, one is created from `url`.
	@objc public var urlRequest: NSMutableURLRequest? {
		didSet {
			if let request = urlRequest {
				self.url = request.url as NSURL?
			}
		}
	}

	/// The content view that owns this image view.
	@objc public weak var contentView: AttributedTextContentView?

	/// Whether to display the image progressively as it downloads.
	@objc public var shouldShowProgressiveDownload: Bool = false

	/// The delegate informed about image-size changes.
	@objc public weak var delegate: LazyImageViewDelegate?

	// MARK: - Private State

	private var dataTask: URLSessionDataTask?
	private var session: URLSession?
	private var receivedData: NSMutableData?

	// Progressive download
	private var imageSource: CGImageSource?
	private var fullWidth: CGFloat = -1
	private var fullHeight: CGFloat = -1
	private var expectedSize: Int = 0

	// MARK: - Lifecycle

	deinit {
		delegate = nil
		dataTask?.cancel()
		// imageSource is a class type in Swift; ARC handles it
	}

	// MARK: - Loading

	private func loadImage(at url: NSURL) {
		// Handle local files and data URLs synchronously
		if url.isFileURL || url.scheme == "data" {
			DispatchQueue.global().async { [weak self] in
				guard let data = try? Data(contentsOf: url as URL) else { return }
				DispatchQueue.main.async {
					self?.completeDownload(with: data)
				}
			}
			return
		}

		if urlRequest == nil {
			urlRequest = NSMutableURLRequest(url: url as URL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
		} else {
			urlRequest?.cachePolicy = .returnCacheDataElseLoad
			urlRequest?.timeoutInterval = 10.0
		}

		NotificationCenter.default.post(name: .dtLazyImageViewWillStartDownload, object: self)

		if session == nil {
			session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
		}

		dataTask = session?.dataTask(with: urlRequest! as URLRequest)
		dataTask?.resume()
	}

	public override func didMoveToSuperview() {
		super.didMoveToSuperview()

		guard image == nil,
			  let url,
			  dataTask == nil,
			  superview != nil else { return }

		// Check cache first
		if let cached = Self.imageCache.object(forKey: url) {
			self.image = cached
			fullWidth = cached.size.width
			fullHeight = cached.size.height
			notifyDelegate()
			return
		}

		loadImage(at: url)
	}

	/// Cancels the current download.
	@objc
	public func cancelLoading() {
		dataTask?.cancel()
		dataTask = nil
		receivedData = nil
	}

	// MARK: - Progressive Image

	private func newTransitoryImage(from partialImage: CGImage) -> CGImage? {
		let height = CGFloat(partialImage.height)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let lFullWidth = Int(ceil(fullWidth))
		let lFullHeight = Int(ceil(fullHeight))

		guard let ctx = CGContext(
			data: nil,
			width: lFullWidth,
			height: lFullHeight,
			bitsPerComponent: 8,
			bytesPerRow: lFullWidth * 4,
			space: colorSpace,
			bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
		) else { return nil }

		ctx.draw(partialImage, in: CGRect(x: 0, y: 0, width: fullWidth, height: height))
		return ctx.makeImage()
	}

	private func createAndShowProgressiveImage() {
		guard let imageSource else { return }

		let totalSize = receivedData?.length ?? 0
		CGImageSourceUpdateData(imageSource, (receivedData ?? NSMutableData()) as CFData, totalSize == expectedSize)

		if fullHeight > 0 && fullWidth > 0 {
			guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return }

			if let transitoryImage = newTransitoryImage(from: cgImage) {
				let uiImage = UIImage(cgImage: transitoryImage)
				DispatchQueue.main.async { [weak self] in
					self?.image = uiImage
				}
			}
		} else {
			guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else { return }

			if let h = properties[kCGImagePropertyPixelHeight] as? CGFloat {
				fullHeight = h
			}
			if let w = properties[kCGImagePropertyPixelWidth] as? CGFloat {
				fullWidth = w
			}
		}
	}

	// MARK: - Completion

	private func notifyDelegate() {
		delegate?.lazyImageView?(self, didChangeImageSize: CGSize(width: fullWidth, height: fullHeight))
	}

	private func completeDownload(with data: Data) {
		let downloadedImage = UIImage(data: data)
		self.image = downloadedImage
		fullWidth = downloadedImage?.size.width ?? 0
		fullHeight = downloadedImage?.size.height ?? 0

		notifyDelegate()

		if let url {
			if let downloadedImage {
				Self.imageCache.setObject(downloadedImage, forKey: url)
			} else {
				logger.warning("Did not get an image for \(url.absoluteString ?? "unknown")")
			}
		}
	}

	// MARK: - Remove from Superview

	public override func removeFromSuperview() {
		super.removeFromSuperview()

		dataTask?.cancel()
		session?.invalidateAndCancel()
	}

	// MARK: - URLSessionDataDelegate

	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		receivedData = nil

		if let httpResponse = response as? HTTPURLResponse {
			guard httpResponse.mimeType?.hasPrefix("image") == true else {
				completionHandler(.cancel)
				return
			}
		}

		completionHandler(.allow)

		fullWidth = -1
		fullHeight = -1
		expectedSize = Int(response.expectedContentLength)
		receivedData = NSMutableData()
	}

	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		receivedData?.append(data)

		guard shouldShowProgressiveDownload else { return }

		if imageSource == nil {
			imageSource = CGImageSourceCreateIncremental(nil)
		}

		createAndShowProgressiveImage()
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error {
			handleDownloadFailure(error: error)
			return
		}

		if let data = receivedData as Data? {
			DispatchQueue.main.sync { [weak self] in
				self?.completeDownload(with: data)
			}
			receivedData = nil
		}

		self.session?.finishTasksAndInvalidate()
		self.dataTask = nil

		imageSource = nil

		NotificationCenter.default.post(name: .dtLazyImageViewDidFinishDownload, object: self)
	}

	private func handleDownloadFailure(error: Error) {
		session?.invalidateAndCancel()
		dataTask = nil
		receivedData = nil
		imageSource = nil

		let userInfo: [String: Any] = ["Error": error]
		NotificationCenter.default.post(name: .dtLazyImageViewDidFinishDownload, object: self, userInfo: userInfo)
	}
}

#endif
