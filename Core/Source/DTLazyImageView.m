//
//  DTLazyImageView.m
//  PagingTextScroller
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 . All rights reserved.
//

#import "DTLazyImageView.h"

static NSCache *_imageCache = nil;

@interface DTLazyImageView ()

- (void)notify;

@end

@implementation DTLazyImageView
{
	NSURL *_url;
	
	NSURLConnection *_connection;
	NSMutableData *_receivedData;

	/* For progressive download */
	CGImageSourceRef _imageSource;
	CGFloat _fullHeight;
	CGFloat _fullWidth;
	NSUInteger _expectedSize;
    
    BOOL shouldShowProgressiveDownload;
	
	__unsafe_unretained id<DTLazyImageViewDelegate> _delegate;
}
@synthesize delegate=_delegate;

- (void)dealloc
{	
	[_connection cancel];
	
	if (_imageSource) CFRelease(_imageSource);
}

- (void)loadImageAtURL:(NSURL *)url
{
	if ([NSThread isMainThread])
	{
		[self performSelectorInBackground:@selector(loadImageAtURL:) withObject:url];
		return;
	}
	
	@autoreleasepool 
	{
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
		
		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		[_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[_connection start];
	
		// necessary because otherwise otherwise the delegate methods would not get delivered
		CFRunLoopRun();
	}
}

- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	
	if (!self.image && _url && !_connection && self.superview)
	{
		UIImage *image = [_imageCache objectForKey:_url];
		
		if (image)
		{
			self.image = image;
			_fullWidth = image.size.width;
			_fullHeight = image.size.height;
			
			// for unknown reasons direct notify does not work below iOS 5
			[self performSelector:@selector(notify) withObject:nil afterDelay:0.0];
			return;
		}
		
		[self loadImageAtURL:_url];
	}	
}

- (void)cancelLoading
{
	[_connection cancel];
	_connection = nil;
	
	_receivedData = nil;
}

#pragma mark Progressive Image
-(CGImageRef)newTransitoryImage:(CGImageRef)partialImg
{
	const size_t height = CGImageGetHeight(partialImg);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	size_t lFullWidth = lrintf(_fullWidth);
	size_t lFullHeight = lrintf(_fullHeight);
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

- (void)notify
{
//	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:CGSizeMake(_fullWidth, _fullHeight)], @"ImageSize", _url, @"ImageURL", nil];
	
	if ([self.delegate respondsToSelector:@selector(lazyImageView:didChangeImageSize:)]) {
		[self.delegate lazyImageView:self didChangeImageSize:CGSizeMake(_fullWidth, _fullHeight)];
	}
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"DTLazyImageViewDidFinishLoading" object:nil userInfo:userInfo];
}

- (void)completeDownloadWithData:(NSData *)data
{
	UIImage *image = [[UIImage alloc] initWithData:data];
	
	self.image = image;
	_fullWidth = image.size.width;
	_fullHeight = image.size.height;
	
	self.bounds = CGRectMake(0, 0, _fullWidth, _fullHeight);
	
	[self notify];
	
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_imageCache = [[NSCache alloc] init];
	});
	
	if (_url)
	{
		// cache image
		[_imageCache setObject:image forKey:_url];
	}
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// every time we get an response it might be a forward, so we discard what data we have
	_receivedData = nil;
	
	// does not fire for local file URLs
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *httpResponse = (id)response;
		
		if (![[httpResponse MIMEType] hasPrefix:@"image"])
		{
			[self cancelLoading];
			return;
		}
	}
	
	/* For progressive download */
	_fullWidth = _fullHeight = -1.0f;
	_expectedSize = (NSUInteger)[response expectedContentLength];
	
	_receivedData = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
	
	if (!CGImageSourceCreateIncremental || !shouldShowProgressiveDownload)
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
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_receivedData)
	{
		[self performSelectorOnMainThread:@selector(completeDownloadWithData:) withObject:_receivedData waitUntilDone:YES];
		
		_receivedData = nil;
	}
	
	_connection = nil;
	
	/* For progressive download */
	if (_imageSource)
		CFRelease(_imageSource), _imageSource = NULL;
	
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_connection = nil;
	_receivedData = nil;
	
	/* For progressive download */
	if (_imageSource)
		CFRelease(_imageSource), _imageSource = NULL;
	
	CFRunLoopStop(CFRunLoopGetCurrent());
}

#pragma mark Properties

@synthesize url = _url;
@synthesize shouldShowProgressiveDownload;

@end
