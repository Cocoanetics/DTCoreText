//
//  DTAttributedLabel.h
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"

@interface DTAttributedLabel : DTAttributedTextContentView

@property(nonatomic, assign) NSInteger numberOfLines;
@property(nonatomic, assign) NSLineBreakMode lineBreakMode;
@property(nonatomic, strong)NSAttributedString *truncationString;

@end
