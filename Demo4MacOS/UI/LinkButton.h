//
//  LinkButton.h
//
//  Created by cntrump on 2017/8/7.
//

#import <Cocoa/Cocoa.h>

@interface LinkButton : NSButton

@property(nonatomic,strong) NSURL *URL;
@property(nonatomic,copy) NSString *GUID;
@property(nonatomic,strong) id userObject;

@end
