//
//  DTCSSListStyle.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

typedef enum
{
    DTCSSListStyleTypeInherit = 0,
    DTCSSListStyleTypeNone,
    DTCSSListStyleTypeCircle,
    DTCSSListStyleTypeDecimal,
    DTCSSListStyleTypeDecimalLeadingZero,
    DTCSSListStyleTypeDisc,
    DTCSSListStyleTypeUpperAlpha,
    DTCSSListStyleTypeUpperLatin,
    DTCSSListStyleTypeLowerAlpha,
    DTCSSListStyleTypeLowerLatin,
    DTCSSListStyleTypePlus,
    DTCSSListStyleTypeUnderscore
} DTCSSListStyleType;

typedef enum
{
	DTCSSListStylePositionInherit = 0,
	DTCSSListStylePositionInside,
	DTCSSListStylePositionOutside
} DTCSSListStylePosition;

@interface DTCSSListStyle : NSObject
{
	BOOL _inherit;
	
	DTCSSListStyleType _type;
	DTCSSListStylePosition _position;
}

@property (nonatomic, assign) BOOL inherit; 
@property (nonatomic, assign) DTCSSListStyleType type;
@property (nonatomic, assign) DTCSSListStylePosition position;

+ (DTCSSListStyle *)listStyleWithStyles:(NSDictionary *)styles;
+ (DTCSSListStyle *)decimalListStyle;
+ (DTCSSListStyle *)discListStyle;
+ (DTCSSListStyle *)inheritedListStyle;

- (id)initWithStyles:(NSDictionary *)styles;

@end
