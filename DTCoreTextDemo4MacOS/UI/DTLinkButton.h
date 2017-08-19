//
//  DTLinkButton.h
//  quan4macos
//
//  Created by cntrump on 2017/8/7.
//  Copyright © 2017年 unnoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTLinkButton : NSButton

@property(nonatomic,strong) NSURL *URL;
@property(nonatomic,copy) NSString *GUID;
@property(nonatomic,strong) id userObject;

@end
