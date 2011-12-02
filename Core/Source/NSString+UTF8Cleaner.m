

#define DT_FAST_TRAILING_BYTES

#ifdef DT_USE_ZERO_WIDTH_NON_BREAKING_SPACE_FOR_REPLACEMENT
static const unsigned char sc_replacementCharUTF8[3] = "\357\273\277";
#else
static const unsigned char sc_replacementCharUTF8[3] = "\357\277\275";
#endif

typedef uint32_t UTF32; /* at least 32 bits */
typedef uint16_t UTF16; /* at least 16 bits */
typedef uint8_t  UTF8;  /* typically 8 bits */

typedef enum {
	conversionOK,           /* conversion successful */
	sourceExhausted,        /* partial character in source, but hit end */
	targetExhausted,        /* insuff. room in target for conversion */
	sourceIllegal           /* source sequence is illegal/malformed */
} ConversionResult;

#define UNI_REPLACEMENT_CHAR (UTF32)0x0000FFFD
#define UNI_MAX_BMP          (UTF32)0x0000FFFF
#define UNI_MAX_UTF16        (UTF32)0x0010FFFF
#define UNI_MAX_UTF32        (UTF32)0x7FFFFFFF
#define UNI_MAX_LEGAL_UTF32  (UTF32)0x0010FFFF
#define UNI_SUR_HIGH_START   (UTF32)0xD800
#define UNI_SUR_HIGH_END     (UTF32)0xDBFF
#define UNI_SUR_LOW_START    (UTF32)0xDC00
#define UNI_SUR_LOW_END      (UTF32)0xDFFF

#if !defined(DT_FAST_TRAILING_BYTES)
static const char trailingBytesForUTF8[256] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
};
#endif

static const UTF32 offsetsFromUTF8[6] = { 0x00000000UL, 0x00003080UL, 0x000E2080UL, 0x03C82080UL, 0xFA082080UL, 0x82082080UL };
static const UTF8  firstByteMark[7]   = { 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };

////////////
#pragma mark -
#pragma mark Unicode related functions

static __inline__ __attribute__((always_inline)) ConversionResult isValidCodePoint(UTF32 *u32CodePoint) {
	ConversionResult result = conversionOK;
	UTF32            ch     = *u32CodePoint;
	
	if((ch >= UNI_SUR_HIGH_START) && (ch <= UNI_SUR_LOW_END))                                    { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }
	if((ch >= 0xFDD0U) && ((ch <= 0xFDEFU) || ((ch & 0xFFFEU) == 0xFFFEU)) && (ch <= 0x10FFFFU)) { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }
	if( ch == 0U)                                                                                { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }
	
finished:
	*u32CodePoint = ch;
	return(result);
}


static __inline__ __attribute__((always_inline)) int isLegalUTF8(const UTF8 *source, size_t length) {
	const UTF8 *srcptr = source + length;
	UTF8 a;
	
	switch(length) {
		default: return(0); // Everything else falls through when "true"...
		case 4: if(((a = (*--srcptr)) < 0x80) || (a > 0xBF)) { return(0); }
		case 3: if(((a = (*--srcptr)) < 0x80) || (a > 0xBF)) { return(0); }
		case 2: if( (a = (*--srcptr)) > 0xBF               ) { return(0); }
			
			switch(*source) { // no fall-through in this inner switch
				case 0xE0: if(a < 0xA0) { return(0); } break;
				case 0xED: if(a > 0x9F) { return(0); } break;
				case 0xF0: if(a < 0x90) { return(0); } break;
				case 0xF4: if(a > 0x8F) { return(0); } break;
				default:   if(a < 0x80) { return(0); }
			}
			
		case 1: if((*source < 0xC2) && (*source >= 0x80)) { return(0); }
	}
	
	if(*source > 0xF4) { return(0); }
	
	return(1);
}

static __inline__ __attribute__((always_inline)) ConversionResult ConvertSingleCodePointInUTF8(const UTF8 *sourceStart, const UTF8 *sourceEnd, UTF8 const **nextUTF8, UTF32 *convertedUTF32) {
	ConversionResult  result = conversionOK;
	const UTF8       *source = sourceStart;
	UTF32             ch     = 0UL;
	
#if !defined(DT_FAST_TRAILING_BYTES)
	unsigned short extraBytesToRead = trailingBytesForUTF8[*source];
#else
	unsigned short extraBytesToRead = (unsigned short)__builtin_clz(((*source)^0xff) << 25);
#endif
	
	if(((source + extraBytesToRead + 1) > sourceEnd) || (!isLegalUTF8(source, extraBytesToRead + 1))) {
		source++;
		while((source < sourceEnd) && (((*source) & 0xc0) == 0x80) && ((source - sourceStart) < (extraBytesToRead + 1))) { source++; } 
		NSCParameterAssert(source <= sourceEnd);
		result = ((source < sourceEnd) && (((*source) & 0xc0) != 0x80)) ? sourceIllegal : ((sourceStart + extraBytesToRead + 1) > sourceEnd) ? sourceExhausted : sourceIllegal;
		ch = UNI_REPLACEMENT_CHAR;
		goto finished;
	}
	
	switch(extraBytesToRead) { // The cases all fall through.
		case 5: ch += *source++; ch <<= 6;
		case 4: ch += *source++; ch <<= 6;
		case 3: ch += *source++; ch <<= 6;
		case 2: ch += *source++; ch <<= 6;
		case 1: ch += *source++; ch <<= 6;
		case 0: ch += *source++;
	}
	ch -= offsetsFromUTF8[extraBytesToRead];
	
	result = isValidCodePoint(&ch);
	
finished:
	*nextUTF8       = source;
	*convertedUTF32 = ch;
	
	return(result);
}

@implementation NSString (MalformedUTF8Additions)

- (id)initWithPotentiallyMalformedUTF8Data:(NSData *)data
{
	NSString *returnString = NULL;
	if((returnString = [self initWithData:data encoding:NSUTF8StringEncoding]) == NULL) {
		// NSString failed to init with data, trying again by cleaning any malformed UTF8...
		NSMutableData *cleanUTF8Data  = [NSMutableData dataWithData:data];
		unsigned char *cleanUTF8Bytes = [cleanUTF8Data mutableBytes];
		NSUInteger cleanUTF8Idx = 0UL, cleanUTF8Length = [cleanUTF8Data length];
		
		while(cleanUTF8Idx < cleanUTF8Length) {
			if(cleanUTF8Bytes[cleanUTF8Idx] < 0x80) { cleanUTF8Idx++; continue; }
			
			unsigned char    *nextValidCharacter = NULL;
			UTF32             u32ch              = 0U;
			ConversionResult  result;
			
			if((result = ConvertSingleCodePointInUTF8(&cleanUTF8Bytes[cleanUTF8Idx], &cleanUTF8Bytes[cleanUTF8Length], (UTF8 const **)&nextValidCharacter, &u32ch)) == conversionOK) { cleanUTF8Idx = nextValidCharacter - cleanUTF8Bytes; }
			else {
				NSUInteger malformedUTF8Length = (nextValidCharacter - &cleanUTF8Bytes[cleanUTF8Idx]);
				NSUInteger moveLength = &cleanUTF8Bytes[cleanUTF8Length] - &cleanUTF8Bytes[cleanUTF8Idx + malformedUTF8Length];
				
				if(malformedUTF8Length < sizeof(sc_replacementCharUTF8)) {
					[cleanUTF8Data increaseLengthBy:(sizeof(sc_replacementCharUTF8) - malformedUTF8Length)];
					cleanUTF8Bytes  = [cleanUTF8Data mutableBytes];
					cleanUTF8Length = [cleanUTF8Data length];   
					memmove(&cleanUTF8Bytes[cleanUTF8Idx + sizeof(sc_replacementCharUTF8)], &cleanUTF8Bytes[cleanUTF8Idx + malformedUTF8Length], moveLength);
					memcpy(&cleanUTF8Bytes[cleanUTF8Idx], sc_replacementCharUTF8, sizeof(sc_replacementCharUTF8));
					cleanUTF8Idx += sizeof(sc_replacementCharUTF8);
				} else {
					if(moveLength > 3UL) {
						memmove(&cleanUTF8Bytes[cleanUTF8Idx + sizeof(sc_replacementCharUTF8)], &cleanUTF8Bytes[cleanUTF8Idx + malformedUTF8Length], moveLength);
						[cleanUTF8Data setLength:(malformedUTF8Length - sizeof(sc_replacementCharUTF8))];
						cleanUTF8Bytes  = [cleanUTF8Data mutableBytes];
						cleanUTF8Length = [cleanUTF8Data length];   
					}
					memcpy(&cleanUTF8Bytes[cleanUTF8Idx], sc_replacementCharUTF8, sizeof(sc_replacementCharUTF8));
					cleanUTF8Idx += sizeof(sc_replacementCharUTF8);
				}
			}
		}
		returnString = [[NSString alloc] initWithData:cleanUTF8Data encoding:NSUTF8StringEncoding];
	}
	return(returnString);
}

@end
