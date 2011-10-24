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

#import "NSDictionary+BAHTTP.h"

@implementation NSDictionary (BAHTTP)

- (NSString *)HTTPQuery {
	return [self HTTPQueryUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)HTTPQueryUsingEncoding:(NSStringEncoding)encoding {
	return [self HTTPQueryUsingEncoding:encoding ordering:nil];
}

- (NSString *)escapedString:(NSString *)s encoding:(CFStringEncoding)e {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)s, NULL, (CFStringRef)@";:@&=/+", e) autorelease];
}

- (NSString *)HTTPQueryUsingEncoding:(NSStringEncoding)encoding ordering:(NSArray *)ordering {
	CFStringEncoding cfStrEnc = CFStringConvertNSStringEncodingToEncoding(encoding);
	NSMutableString *s = [NSMutableString stringWithCapacity:256];
	NSEnumerator *e = ordering ? [ordering objectEnumerator] : [self keyEnumerator];
	id key;
	while ((key = [e nextObject])) {
        id keyObject = [self objectForKey: key];
		// conform with rfc 1738 3.3, also escape URL-like characters that might be in the parameters
		NSString *escapedKey = [self escapedString:key encoding:cfStrEnc];
        if ([keyObject respondsToSelector:@selector(objectEnumerator)]) {
            NSEnumerator *multipleValueEnum = [keyObject objectEnumerator];
            id aValue;
            while ((aValue = [multipleValueEnum nextObject])) {
                NSString *escapedObject = [self escapedString:[aValue description] encoding:cfStrEnc];
                [s appendFormat:@"%@=%@&", escapedKey, escapedObject];
            }
        } else {
            NSString *escapedObject = [self escapedString:[keyObject description] encoding:cfStrEnc];
            [s appendFormat:@"%@=%@&", escapedKey, escapedObject];
        }
	}
	// delete final & from the string
	if (![s isEqualToString:@""]) {
		[s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];
	}
	return s;       
}

@end
