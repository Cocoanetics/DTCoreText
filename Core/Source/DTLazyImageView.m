//
//  DTLazyImageView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "DTLazyImageView.h"
#import "DTCompatibility.h"

#import <DTFoundation/DTLog.h>

static NSCache *_imageCache = nil;

NSString * const DTLazyImageViewWillStartDownloadNotification = @"DTLazyImageViewWillStartDownloadNotification";
NSString * const DTLazyImageViewDidFinishDownloadNotification = @"DTLazyImageViewDidFinishDownloadNotification";

@interface DTLazyImageView ()
#if DTCORETEXT_USES_NSURLSESSION
<NSURLSessionDataDelegate>
#else
<NSURLConnectionDelegate>
#endif

- (void)_notifyDelegate;

@end

@implementation DTLazyImageView
{
	NSURL *_url;
	NSMutableURLRequest *_urlRequest;
	
	
#if DTCORETEXT_USES_NSURLSESSION
	NSURLSessionDataTask *_dataTask;
	NSURLSession *_session;
#else
	NSURLConnection *_connection;
#endif

	NSMutableData *_receivedData;

	/* For progressive download */
	CGImageSourceRef _imageSource;
	CGFloat _fullHeight;
	CGFloat _fullWidth;
	NSUInteger _expectedSize;
	
	BOOL shouldShowProgressiveDownload;
	
	DT_WEAK_VARIABLE id<DTLazyImageViewDelegate> _delegate;
}

- (void)dealloc
{
	_delegate = nil; // to avoid late notification
	
#if DTCORETEXT_USES_NSURLSESSION
	[_dataTask cancel];
#else
	[_connection cancel];
#endif
	
	if (_imageSource) CFRelease(_imageSource);
}

- (void)loadImageAtURL:(NSURL *)url
{
	// local files we don't need to get asynchronously
	if ([url isFileURL] || [url.scheme isEqualToString:@"data"])
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSData *data = [NSData dataWithContentsOfURL:url];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self completeDownloadWithData:data];
			});
		});
		
		return;
	}
	
	@autoreleasepool 
	{
		if (!_urlRequest)
		{
			_urlRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
		}
		else
		{
			[_urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
			[_urlRequest setTimeoutInterval:10.0];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTLazyImageViewWillStartDownloadNotification object:self];
		
#if DTCORETEXT_USES_NSURLSESSION
		
		if (!_session)
		{
			_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
		}
		
		_dataTask = [_session dataTaskWithRequest:_urlRequest];
		[_dataTask resume];
#else
		_connection = [[NSURLConnection alloc] initWithRequest:_urlRequest delegate:self startImmediately:NO];
		[_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[_connection start];
#endif
	}
}

- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	
	if (!self.image && (_url || _urlRequest) &&
#if DTCORETEXT_USES_NSURLSESSION
		 !_dataTask
#else
		 !_connection
#endif
		 && self.superview)
	{
		UIImage *image = [_imageCache objectForKey:_url];
		
		if (image)
		{
			self.image = image;
			_fullWidth = image.size.width;
			_fullHeight = image.size.height;
			
			// this has to be synchronous
			[self _notifyDelegate];
			
			return;
		}
		
		[self loadImageAtURL:_url];
	}	
}

- (void)cancelLoading
{
#if DTCORETEXT_USES_NSURLSESSION
	[_dataTask cancel];
	_dataTask = nil;
#else
	[_connection cancel];
	_connection = nil;
#endif
	
	_receivedData = nil;
}

#pragma mark Progressive Image
-(CGImageRef)newTransitoryImage:(CGImageRef)partialImg
{
	const size_t height = CGImageGetHeight(partialImg);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	size_t lFullWidth = (size_t)ceil(_fullWidth);
	size_t lFullHeight = (size_t)ceil(_fullHeight);
	CGContextRef bmContext = CGBitmapContextCreate(NULL, lFullWidth, lFullHeight, 8, lFullWidth * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	if (!bmContext)
	{
		// fail creating context
		return NULL;
	}
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _fullWidth, .size.height = height}, partialImg);
	CGImageRef goodImageRef = CGBitmapContextCreateImage(bmContext);
	CGContextRelease(bmContext);
	return goodImageRef;
}

- (void)createAndShowProgressiveImage
{
	if (!_imageSource)
	{
		return;
	}
	
	/* For progressive download */
	const NSUInteger totalSize = [_receivedData length];
	CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)_receivedData, (totalSize == _expectedSize) ? true : false);
	
	if (_fullHeight > 0 && _fullWidth > 0)
	{
		CGImageRef image = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
		if (image)
		{
			CGImageRef imgTmp = [self newTransitoryImage:image]; // iOS fix to correctly handle JPG see : http://www.cocoabyss.com/mac-os-x/progressive-image-download-imageio/
			if (imgTmp)
			{
				UIImage *uimage = [[UIImage alloc] initWithCGImage:imgTmp];
				CGImageRelease(imgTmp);

				dispatch_async(dispatch_get_main_queue(), ^{ self.image = uimage; } );
			}
			CGImageRelease(image);
		}
	}
	else
	{
		CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
		if (properties)
		{
			CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
			if (val)
				CFNumberGetValue(val, kCFNumberFloatType, &_fullHeight);
			val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
			if (val)
				CFNumberGetValue(val, kCFNumberFloatType, &_fullWidth);
			CFRelease(properties);
		}
	}
}

#pragma mark NSURL Loading

- (void)_notifyDelegate
{
	if ([self.delegate respondsToSelector:@selector(lazyImageView:didChangeImageSize:)]) {
		[self.delegate lazyImageView:self didChangeImageSize:CGSizeMake(_fullWidth, _fullHeight)];
	}
}

- (void)completeDownloadWithData:(NSData *)data
{
	UIImage *image = [[UIImage alloc] initWithData:data];
	
	self.image = image;
	_fullWidth = image.size.width;
	_fullHeight = image.size.height;

	[self _notifyDelegate];
	
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_imageCache = [[NSCache alloc] init];
	});
	
	if (_url)
	{
		if (image)
		{
			// cache image
			[_imageCache setObject:image forKey:_url];
		}
		else
		{
			DTLogWarning(@"Warning, %@ did not get an image for %@", NSStringFromClass([self class]), [_url absoluteString]);
		}
	}
}

#if DTCORETEXT_USES_NSURLSESSION
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
#else
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
#endif
{
	// every time we get an response it might be a forward, so we discard what data we have
	_receivedData = nil;
	
	// does not fire for local file URLs
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *httpResponse = (id)response;
		
		if (![[httpResponse MIMEType] hasPrefix:@"image"])
		{
#if DTCORETEXT_USES_NSURLSESSION
			completionHandler(NSURLSessionResponseCancel);
#else
			[self cancelLoading];
#endif
			return;
		}
		
#if DTCORETEXT_USES_NSURLSESSION
		completionHandler(NSURLSessionResponseAllow);
#endif
	}
	
	/* For progressive download */
	_fullWidth = _fullHeight = -1.0f;
	_expectedSize = (NSUInteger)[response expectedContentLength];
	
	_receivedData = [[NSMutableData alloc] init];
}

#if DTCORETEXT_USES_NSURLSESSION
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
	 didReceiveData:(NSData *)data
#else
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
#endif
{
	[_receivedData appendData:data];
	
	if (!&CGImageSourceCreateIncremental || !shouldShowProgressiveDownload)
	{
		// don't show progressive
		return;
	}
	
	if (!_imageSource)
	{
		_imageSource = CGImageSourceCreateIncremental(NULL);
	}
	
	[self createAndShowProgressiveImage];
}


- (void)removeFromSuperview
{
	[super removeFromSuperview];
	
#if DTCORETEXT_USES_NSURLSESSION
	[_dataTask cancel];
	[_session invalidateAndCancel];
#else
	[_connection cancel];
#endif
}

#if DTCORETEXT_USES_NSURLSESSION
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
#else
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
#endif
{
#if DTCORETEXT_USES_NSURLSESSION
	if (error)
	{
		[self connection:nil didFailWithError:error];
		return;
	}
#endif
	
	if (_receivedData)
	{
		[self performSelectorOnMainThread:@selector(completeDownloadWithData:) withObject:_receivedData waitUntilDone:YES];
		
		_receivedData = nil;
	}
	
#if DTCORETEXT_USES_NSURLSESSION
	[_session finishTasksAndInvalidate];
	_dataTask = nil;
#else
	_connection = nil;
#endif
	
	/* For progressive download */
	if (_imageSource)
		CFRelease(_imageSource), _imageSource = NULL;
	
	CFRunLoopStop(CFRunLoopGetCurrent());

	// success = no userInfo
	[[NSNotificationCenter defaultCenter] postNotificationName:DTLazyImageViewDidFinishDownloadNotification object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#if DTCORETEXT_USES_NSURLSESSION
	[_session invalidateAndCancel];
	_dataTask = nil;
#else
	_connection = nil;
#endif
	
	_receivedData = nil;
	
	/* For progressive download */
	if (_imageSource)
		CFRelease(_imageSource), _imageSource = NULL;
	
	CFRunLoopStop(CFRunLoopGetCurrent());

	// send completion notification, pack in error as well
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:@"Error"];
	[[NSNotificationCenter defaultCenter] postNotificationName:DTLazyImageViewDidFinishDownloadNotification object:self userInfo:userInfo];
}

#pragma mark Properties

- (void) setUrlRequest:(NSMutableURLRequest *)request
{
	_urlRequest = request;
	self.url = [_urlRequest URL];
}

@synthesize delegate=_delegate;
@synthesize shouldShowProgressiveDownload;
@synthesize url = _url;
@synthesize urlRequest = _urlRequest;

@end
