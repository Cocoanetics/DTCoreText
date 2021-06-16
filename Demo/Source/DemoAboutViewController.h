//
//  DemoAboutViewController.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 3/4/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>

@interface DemoAboutViewController : UIViewController

@property (nonatomic, DT_WEAK_PROPERTY) IBOutlet DTAttributedTextView *attributedTextView;

@end
