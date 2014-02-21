//
//  DTCrossPlatformScrollView.h
//  DTCoreText
//
//  Created by Michael Markowski on 21/02/14.
//

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DTCrossPlatformScrollView : UIScrollView {
}
@end

#else

#import <Cocoa/Cocoa.h>

@class DTCrossPlatformScrollView;

@protocol DTCrossPlatformScrollViewDelegate <NSObject>

- (void)scrollViewDidScroll:(DTCrossPlatformScrollView *)scrollView;

@end

@interface DTCrossPlatformScrollView : NSScrollView {
    
}

@property (nonatomic, weak) id<DTCrossPlatformScrollViewDelegate> delegate;

- (CGPoint)contentOffset;

@end

#endif
