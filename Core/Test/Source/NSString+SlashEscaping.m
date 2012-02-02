//
//  NSString+SlashEscaping.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 02.02.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSString+SlashEscaping.h"

@implementation NSString (SlashEscaping)

- (NSString *)stringByAddingSlashEscapes
{
	NSUInteger length = [self length];
	
	unichar *characters = calloc(length, sizeof(unichar));
	unichar *final = calloc(length*2+1, sizeof(unichar));
	
	[self getCharacters:characters range:NSMakeRange(0, length)];
	
	NSUInteger outChars = 0;
	
	for (NSUInteger idx=0; idx<length;idx++)
	{
		unichar character = characters[idx];
		
		switch (character) 
		{
			case '\n':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'n';
				break;
			}
				
			case '\t':
			{
				final[outChars++] = '\\';
				final[outChars++] = 't';
				break;
			}
				
			case '\v':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'v';
				break;
			}
				
			case '\b':
			{
				final[outChars++] = '\\';
				final[outChars++] = 'b';
				break;
			}
				
			case '\r':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'r';
				break;
			}
				
			case '\f':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'f';
				break;
			}
				
			case '\a':
			{
				final[outChars++] = '\\';
				final[outChars++] =  'a';
				break;
			}
				
			case '\\':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\\';
				break;
			}
				
			case '\?':
			{
				final[outChars++] = '\\';
				final[outChars++] = '\?';
				break;
			}
				
			case '\'':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\'';
				break;
			}
				
			case '\"':
			{
				final[outChars++] = '\\';
				final[outChars++] =  '\"';
				break;
			}
				
			default:
			{
				final[outChars++] = character;
			}
		}
	}
	
	free(characters);
	NSString *clean = [[NSString alloc] initWithCharacters:final length:outChars];
	free(final);
	
	return clean;
}

@end
