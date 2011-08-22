/*
 Copyright 2011 Dmitry Stadnik. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list
 of conditions and the following disclaimer in the documentation and/or other materials
 provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY DMITRY STADNIK ``AS IS'' AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DMITRY STADNIK OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of Dmitry Stadnik.
*/

#import "BAHyperParser.h"

#define HYPERPARSER_IS_WHITESPACE(__c__) [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:__c__]


@interface BAHyperInput : NSObject {
@private
	NSString *_source;
	NSUInteger _position;
	NSUInteger _length;
}

- (id)initWithString:(NSString *)string;
- (BOOL)hasNext;
- (unichar)next;
- (BOOL)startsWithPrefix:(NSString *)prefix;
- (NSString *)substringToSuffix:(NSString *)suffix validateSuffix:(BOOL)validateSuffix;
- (NSString *)substringFromPrefix:(NSString *)prefix toSuffix:(NSString *)suffix validateSuffix:(BOOL)validateSuffix;

@end


@implementation BAHyperInput

- (id)initWithString:(NSString *)string {
	if ((self = [super init])) {
		_source = [string retain];
		_position = 0;
		_length = [_source length];
	}
	return self;
}

- (void)dealloc {
	[_source release];
	[super dealloc];
}

- (BOOL)hasNext {
	return _position < _length;
}

- (unichar)next {
	return [_source characterAtIndex:_position++];
}

- (BOOL)startsWithPrefix:(NSString *)prefix {
	if ([prefix length] > (_length - _position)) {
		return NO;
	}
	for (NSUInteger i = 0; i < [prefix length]; i++) {
		if ([prefix characterAtIndex:i] != [_source characterAtIndex:(_position + i)]) {
			return NO;
		}
	}
	return YES;
}

- (NSString *)substringToSuffix:(NSString *)suffix validateSuffix:(BOOL)validateSuffix {
	NSRange range = {_position, _length - _position};
	NSRange suffixRange = [_source rangeOfString:suffix options:NSLiteralSearch range:range];
	if (suffixRange.location == NSNotFound) {
        if (validateSuffix) {
            return nil;
        } else {
            _position = _length;
            return [_source substringFromIndex:_position];
        }
	}
	range.location = _position;
	range.length = suffixRange.location - range.location;
	NSString *content = [_source substringWithRange:range];
	_position = suffixRange.location + [suffix length];
	return content;
}

- (NSString *)substringFromPrefix:(NSString *)prefix toSuffix:(NSString *)suffix validateSuffix:(BOOL)validateSuffix {
	if (![self startsWithPrefix:prefix]) {
		return nil;
	}
	_position += [prefix length];
	return [self substringToSuffix:suffix validateSuffix:validateSuffix];
}

@end


@implementation BAHyperParser

@synthesize delegate = _delegate;

- (id)initWithString:(NSString *)string {
	if ((self = [super init])) {
		_input = [[BAHyperInput alloc] initWithString:string];
		_cancel = NO;
	}
	return self;
}

- (void)dealloc {
	[_input release];
	[super dealloc];
}

- (void)parseElement {
	NSString *elementName = nil;
	NSMutableDictionary *attributeDict = [NSMutableDictionary dictionary];
	NSString *attributeName = nil;
	BOOL endOfElement = NO; // starts with slash; closing part
	BOOL emptyElement = NO; // ends with slash; element without content
    BOOL tagCompleted = NO; // final '>' found after attribute value without quotes
	NSMutableString *buffer = [NSMutableString string];
	unichar chars[1];
	while ([_input hasNext]) {
		unichar c = [_input next];
		if (HYPERPARSER_IS_WHITESPACE(c)) {
			// word border; buffer contains a token
			if ([buffer length] == 0) {
				continue; // subsequent spaces
			}
			if (!elementName) {
				// first token is element name
				elementName = buffer;
				buffer = [NSMutableString string];
			} else {
				// must be attribute name
				attributeName = buffer;
				buffer = [NSMutableString string];
			}
		} else if (c == '=') {
			if ([buffer length] > 0) {
				attributeName = buffer;
				buffer = [NSMutableString string];
			}
			// now goes attribute value
			unichar firstQuote = '\0';
			while ([_input hasNext]) {
				c = [_input next];
				if (HYPERPARSER_IS_WHITESPACE(c)) {
					if (firstQuote != '\0') {
						// space inside quotes
						chars[0] = c;
						[buffer appendString:[NSString stringWithCharacters:chars length:1]];
					} else if ([buffer length] > 0) {
						// end of unquoted attribute value
						if (attributeName) {
							[attributeDict setObject:buffer forKey:attributeName];
							attributeName = nil;
						}
						buffer = [NSMutableString string];
						break;
					}
					// else leading spaces - ignore
				} else if (c == '\'' || c == '"') {
					if (firstQuote == c) {
						// last quote
						if (attributeName) {
							[attributeDict setObject:buffer forKey:attributeName];
							attributeName = nil;
						}
						buffer = [NSMutableString string];
						break;
					}
					if ([buffer length] == 0 && firstQuote == '\0') {
						// first quote
						firstQuote = c;
					} else {
						// nested quote; add as normal char
						// it's error if firstQuote == '\0' but we will ignore this
						chars[0] = c;
						[buffer appendString:[NSString stringWithCharacters:chars length:1]];
					}
                } else if (c == '>'){
                    if (firstQuote != '\0') {
                        // character inside quotes
                        chars[0] = c;
                        [buffer appendString:[NSString stringWithCharacters:chars length:1]];
                    } else {
                        // end of tag and end of attribute value without quotes
                        tagCompleted = YES;
                        break;
                    }
				} else {
					chars[0] = c;
					[buffer appendString:[NSString stringWithCharacters:chars length:1]];
				}
			}
			// try to recover incomplete attribute value
			if (attributeName) {
				[attributeDict setObject:buffer forKey:attributeName];
				attributeName = nil;
			}
			buffer = [NSMutableString string];
            if (tagCompleted) {
				break;
			}
		} else if (c == '/') {
			// buffer may contain element name
			if ([buffer length] > 0) {
				if (!elementName) {
					elementName = buffer;
				}
				buffer = [NSMutableString string];
			}
			if (elementName) {
				emptyElement = YES;
			} else {
				endOfElement = YES;
			}
		} else if (c == '>') {
			// element has ended but buffer may contain element name
			if ([buffer length] > 0) {
				if (!elementName) {
					elementName = buffer;
				}
				// no need to empty buffer
			}
			break;
		} else {
			chars[0] = c;
			[buffer appendString:[NSString stringWithCharacters:chars length:1]];
			emptyElement = NO;
		}
	}
	if (elementName) {
		if (endOfElement) {
			if ([self.delegate respondsToSelector:@selector(parser:didEndElement:)]) {
				[self.delegate parser:self didEndElement:elementName];
			}
		} else {
			if ([self.delegate respondsToSelector:@selector(parser:didStartElement:attributes:)]) {
				[self.delegate parser:self didStartElement:elementName attributes:attributeDict];
			}
			if (emptyElement && !_cancel) {
				if ([self.delegate respondsToSelector:@selector(parser:didEndElement:)]) {
					[self.delegate parser:self didEndElement:elementName];
				}
			}
		}
	}
}

- (void)parse {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger poolCycle = 0;
	while ([_input hasNext]) {
		if (_cancel) {
			break;
		}
		if ((++poolCycle % 100) == 0) {
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];
		}
		NSString *string = [_input substringToSuffix:@"<" validateSuffix:NO];
		if ([string length] > 0) {
			if ([self.delegate respondsToSelector:@selector(parser:foundCharacters:)]) {
				[self.delegate parser:self foundCharacters:string];
				if (_cancel) {
					break;
				}
			}
		}
		// CDATA
		string = [_input substringFromPrefix:@"![CDATA[" toSuffix:@"]]>" validateSuffix:NO];
		if (string) {
			if ([self.delegate respondsToSelector:@selector(parser:foundCDATA:)]) {
				[self.delegate parser:self foundCDATA:string];
			}
			continue;
		}
		// Comment
		string = [_input substringFromPrefix:@"!--" toSuffix:@"-->" validateSuffix:YES];
		if (string) {
			if ([self.delegate respondsToSelector:@selector(parser:foundComment:)]) {
				[self.delegate parser:self foundComment:string];
			}
			continue;
		}
		// Processing Instruction... ignore for now
		string = [_input substringFromPrefix:@"?" toSuffix:@"?>" validateSuffix:NO];
		if (string) {
			continue;
		}
		// DOCTYPE... ignore for now
		string = [_input substringFromPrefix:@"!" toSuffix:@">" validateSuffix:NO];
		if (string) {
			continue;
		}
		[self parseElement];
	}
	[pool drain];
}

- (void)cancel {
	_cancel = YES;
}

- (NSError *)parserError {
	return nil;
}

- (BOOL)string:(NSString *)string startsWithPrefix:(NSString *)prefix atOffset:(NSUInteger)offset {
	if ([prefix length] > ([string length] - offset)) {
		return NO;
	}
	for (NSUInteger i = 0; i < [prefix length]; i++) {
		if ([prefix characterAtIndex:i] != [string characterAtIndex:(offset + i)]) {
			return NO;
		}
	}
	return YES;
}

@end
