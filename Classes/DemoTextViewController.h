//
//  DemoTextViewController.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTAttributedTextView;

@interface DemoTextViewController : UIViewController {

	NSString *_fileName;
	
	UISegmentedControl *_segmentedControl;
	DTAttributedTextView *_textView;
	UITextView *_rangeView;
	UITextView *_charsView;
	UITextView *_dataView;
}

@property (nonatomic, retain) NSString *fileName;

@end
