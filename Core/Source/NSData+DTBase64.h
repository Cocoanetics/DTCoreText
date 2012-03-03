//
//  NSData+Base64.h
//  base64
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//


void *NewDTBase64Decode(
	const char *inputBuffer,
	size_t length,
	size_t *outputLength);

char *NewDTBase64Encode(
	const void *inputBuffer,
	size_t length,
	bool separateLines,
	size_t *outputLength);

/**
 Category to deal with base64-strings.
*/
@interface NSData (DTBase64)

/** 
 Retrieve the NSData of a string encoded in Base64 encoding. 
 @param aString The base 64 string.
 @returns An NSData representation of a string that was Base64 encoded. 
 */
+ (NSData *)dataFromBase64String:(NSString *)aString;


/** 
 Retrive an NSString in Base64 encoding from an NSData object. 
 @returns An NSString representation of this NSData instance, encoded in Base64. 
 */
- (NSString *)base64EncodedString;

@end
