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

#import "BAJSONLoader.h"
#import <objc/message.h>

@implementation BAJSONLoader

@synthesize JSONValue = _JSONValue;

- (void)resetConnection {
	[super resetConnection];
	[_JSONValue release];
	_JSONValue = nil;
}

- (BOOL)prepareData:(NSData *)data {
	if (_JSONValue) {
		[_JSONValue release];
		_JSONValue = nil;
	}

//	NSString *text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//	NSLog(@"%@", [self.request URL]);
//	NSLog(@"%@", text);

	NSError *error = nil;
	_JSONValue = [[[self class] parseJSONData:data error:&error] retain];
	if (error) {
		NSLog(@"Error parsing JSON from %@: %@", [self.request URL], error);
	}
	return !error;
}

+ (id)parseJSONData:(NSData *)data error:(NSError **)error {
	if (!data || [data length] == 0) {
		return nil;
	}
	Class serClass = NSClassFromString(@"NSJSONSerialization");
	if (serClass) {
		// return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
		return objc_msgSend(serClass, @selector(JSONObjectWithData:options:error:),
							data, [NSNumber numberWithInt:NSJSONReadingAllowFragments], error);
	} else if ([data respondsToSelector:NSSelectorFromString(@"objectFromJSONData")]) {
		id JSONValue = nil;
		@try {
			JSONValue = [data performSelector:NSSelectorFromString(@"objectFromJSONData")];
		}
		@catch (NSException *e) {
			JSONValue = nil;
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		return JSONValue;
	} else {
		NSLog(@"JSON parser is not available");
	}
	return nil;
}

+ (NSString *)stringFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSString class]]) {
		return value;
	}
	return nil;
}

+ (NSArray *)arrayFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSArray class]]) {
		return value;
	}
	return nil;
}

+ (NSDictionary *)dictionaryFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSDictionary class]]) {
		return value;
	}
	return nil;
}

+ (BOOL)boolFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	return [self boolFromJSONValue:JSONValue forKey:key defaultValue:NO];
}

+ (BOOL)boolFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key defaultValue:(BOOL)defaultValue {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSString class]]) {
		return !![value intValue];
	} else if (value && [value isKindOfClass:[NSNumber class]]) {
		return !![value intValue];
	}
	return defaultValue;
}

+ (int)intFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	return [self intFromJSONValue:JSONValue forKey:key defaultValue:0];
}

+ (int)intFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key defaultValue:(int)defaultValue {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSString class]]) {
		return [value intValue];
	} else if (value && [value isKindOfClass:[NSNumber class]]) {
		return [value intValue];
	}
	return defaultValue;
}

+ (double)doubleFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key {
	return [self doubleFromJSONValue:JSONValue forKey:key defaultValue:0];
}

+ (double)doubleFromJSONValue:(NSDictionary *)JSONValue forKey:(NSString *)key defaultValue:(int)defaultValue {
	id value = [JSONValue objectForKey:key];
	if (value && [value isKindOfClass:[NSString class]]) {
		return [value doubleValue];
	} else if (value && [value isKindOfClass:[NSNumber class]]) {
		return [value doubleValue];
	}
	return defaultValue;
}

@end
