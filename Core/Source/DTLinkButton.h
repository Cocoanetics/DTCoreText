//
//  DTLinkButton.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//




@interface DTLinkButton : UIButton 

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *guid;

@property (nonatomic, assign) CGSize minimumHitSize;

@end
