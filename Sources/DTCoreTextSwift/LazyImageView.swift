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
public class LazyImageView: UIImageView {

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

	/// Deprecated. Progressive download is no longer supported; setting this has no effect.
	/// Kept for ABI compatibility.
	@objc public var shouldShowProgressiveDownload: Bool = false

	/// The delegate informed about image-size changes.
	@objc public weak var delegate: LazyImageViewDelegate?

	// MARK: - Private State

	private var loadTask: Task<Void, Never>?
	private var fullWidth: CGFloat = 0
	private var fullHeight: CGFloat = 0

	// MARK: - Lifecycle

	deinit {
		loadTask?.cancel()
	}

	// MARK: - Loading

	public override func didMoveToSuperview() {
		super.didMoveToSuperview()

		guard image == nil,
			  let url,
			  loadTask == nil,
			  superview != nil else { return }

		// Check cache first
		if let cached = Self.imageCache.object(forKey: url) {
			self.image = cached
			fullWidth = cached.size.width
			fullHeight = cached.size.height
			notifyDelegate()
			return
		}

		loadTask = Task { [weak self] in
			await self?.performLoad(url: url)
		}
	}

	/// Cancels the current download.
	@objc
	public func cancelLoading() {
		loadTask?.cancel()
		loadTask = nil
	}

	public override func removeFromSuperview() {
		super.removeFromSuperview()
		cancelLoading()
	}

	// MARK: - Async Loading

	/// Reads the bytes of a local-file or data-URL off the main actor.
	private nonisolated static func readLocalData(at url: URL) -> Data? {
		try? Data(contentsOf: url)
	}

	private func performLoad(url: NSURL) async {
		defer { loadTask = nil }

		// file:// and data: URLs: read off-actor, then complete on the main actor.
		if url.isFileURL || url.scheme == "data" {
			let data = await Task.detached(priority: .utility) {
				LazyImageView.readLocalData(at: url as URL)
			}.value

			guard !Task.isCancelled else { return }

			if let data {
				completeDownload(with: data, for: url)
			}
			return
		}

		// Build the request, defaulting to a 10s timeout that prefers cache.
		let request: URLRequest
		if let existing = urlRequest {
			existing.cachePolicy = .returnCacheDataElseLoad
			existing.timeoutInterval = 10.0
			request = existing as URLRequest
		} else {
			let mutable = NSMutableURLRequest(url: url as URL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
			urlRequest = mutable
			request = mutable as URLRequest
		}

		NotificationCenter.default.post(name: .dtLazyImageViewWillStartDownload, object: self)

		do {
			let (data, response) = try await URLSession.shared.data(for: request)

			try Task.checkCancellation()

			// Reject non-image responses (matches the old behavior).
			if let httpResponse = response as? HTTPURLResponse,
			   httpResponse.mimeType?.hasPrefix("image") != true {
				throw URLError(.cannotDecodeContentData)
			}

			completeDownload(with: data, for: url)
			NotificationCenter.default.post(name: .dtLazyImageViewDidFinishDownload, object: self)
		} catch is CancellationError {
			// Expected on cancel; no notification.
		} catch where (error as? URLError)?.code == .cancelled {
			// URLSession cancellation funnels here.
		} catch {
			handleDownloadFailure(error: error)
		}
	}

	// MARK: - Completion

	private func notifyDelegate() {
		delegate?.lazyImageView?(self, didChangeImageSize: CGSize(width: fullWidth, height: fullHeight))
	}

	private func completeDownload(with data: Data, for url: NSURL) {
		let downloadedImage = UIImage(data: data)
		self.image = downloadedImage
		fullWidth = downloadedImage?.size.width ?? 0
		fullHeight = downloadedImage?.size.height ?? 0

		notifyDelegate()

		if let downloadedImage {
			Self.imageCache.setObject(downloadedImage, forKey: url)
		} else {
			logger.warning("Did not get an image for \(url.absoluteString ?? "unknown")")
		}
	}

	private func handleDownloadFailure(error: Error) {
		let userInfo: [String: Any] = ["Error": error]
		NotificationCenter.default.post(name: .dtLazyImageViewDidFinishDownload, object: self, userInfo: userInfo)
	}
}

#endif
