//
//  DTAttributedTextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DTAttributedTextContentView;

@interface DTAttributedTextView : UIScrollView 
{
	DTAttributedTextContentView *contentView;
}

@property (nonatomic, retain) NSAttributedString *string;

@property (nonatomic, readonly) DTAttributedTextContentView *contentView;

@end
