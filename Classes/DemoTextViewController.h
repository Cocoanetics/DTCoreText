//
//  DemoTextViewController.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"


@interface DemoTextViewController : UIViewController <UIActionSheetDelegate, DTAttributedTextContentViewDelegate>
{

	NSString *_fileName;
	
	UISegmentedControl *_segmentedControl;
	DTAttributedTextView *_textView;
	UITextView *_rangeView;
	UITextView *_charsView;
	UITextView *_dataView;

	NSURL *baseURL;
	
	// private
	NSURL *lastActionLink;
	NSMutableSet *mediaPlayers;
}

@property (nonatomic, retain) NSString *fileName;

@property (nonatomic, retain) NSURL *lastActionLink;

@property (nonatomic, retain) NSURL *baseURL;


@end
