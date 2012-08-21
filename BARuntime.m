/*
 Copyright 2012 Dmitry Stadnik. All rights reserved.
 
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

#import "BARuntime.h"
#import <objc/message.h>

@implementation BARuntime

+ (id)parseJSONData:(NSData *)data error:(NSError **)error {
	if (!data || [data length] == 0) {
		return nil;
	}
	Class serClass = NSClassFromString(@"NSJSONSerialization");
	if (serClass) {
		id JSONValue = nil;
		@try {
			return objc_msgSend(serClass, @selector(JSONObjectWithData:options:error:),
								data, [NSNumber numberWithInt:NSJSONReadingAllowFragments], error);
		}
		@catch (NSException *e) {
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		return JSONValue;
	} else if ([data respondsToSelector:NSSelectorFromString(@"objectFromJSONData")]) {
		id JSONValue = nil;
		@try {
			JSONValue = [data performSelector:NSSelectorFromString(@"objectFromJSONData")];
		}
		@catch (NSException *e) {
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

+ (NSData *)serializeJSONToData:(id)JSONValue error:(NSError **)error {
	if (!JSONValue) {
		return nil;
	}
	Class serClass = NSClassFromString(@"NSJSONSerialization");
	if (serClass) {
		NSData *data = nil;
		@try {
			data = objc_msgSend(serClass, @selector(dataWithJSONObject:options:error:),
								JSONValue, 0, error);
		}
		@catch (NSException *e) {
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		return data;
	} else if ([JSONValue respondsToSelector:@selector(JSONDataWithOptions:error:)]) {
		NSData *data = nil;
		@try {
			data = [JSONValue performSelector:@selector(JSONDataWithOptions:error:)
								   withObject:[NSNumber numberWithInt:0]
								   withObject:(id)error];
		}
		@catch (NSException *e) {
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		return data;
	} else {
		NSLog(@"JSON parser is not available");
	}
	return nil;
}

+ (NSString *)serializeJSONToString:(id)JSONValue error:(NSError **)error {
	return [self serializeJSONToString:JSONValue formatted:NO error:error];
}

+ (NSString *)serializeJSONToString:(id)JSONValue formatted:(BOOL)formatted error:(NSError **)error {
	if (!JSONValue) {
		return nil;
	}
	Class serClass = NSClassFromString(@"NSJSONSerialization");
	if (serClass) {
		NSData *data = nil;
		@try {
			data = objc_msgSend(serClass, @selector(dataWithJSONObject:options:error:),
								JSONValue, (formatted ? NSJSONWritingPrettyPrinted : 0), error);
		}
		@catch (NSException *e) {
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		if (!data) {
			return nil;
		}
		return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	} else if ([JSONValue respondsToSelector:@selector(JSONStringWithOptions:error:)]) {
		NSString *data = nil;
		@try {
			data = [JSONValue performSelector:@selector(JSONStringWithOptions:error:)
								   withObject:[NSNumber numberWithInt:(formatted ? 1 /*JKSerializeOptionPretty*/ : 0)]
								   withObject:(id)error];
		}
		@catch (NSException *e) {
			if (error) {
				*error = [NSError errorWithDomain:@"BaseAppKit"
											 code:0
										 userInfo:[NSDictionary dictionaryWithObject:e.reason
																			  forKey:NSLocalizedDescriptionKey]];
			}
		}
		return data;
	} else {
		NSLog(@"JSON parser is not available");
	}
	return nil;
}

@end
