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

#import "BARemoteJSON.h"
#import "BARuntime.h"
#import <libkern/OSAtomic.h>

NSInteger const BARemoteJSONMinErrorCode = -32099;
NSInteger const BARemoteJSONMaxErrorCode = -32000;

NSString * const BARemoteJSONErrorDomain = @"BARemoteJSON";
NSString * const BARemoteJSONErrorDataKey = @"BARemoteJSONErrorData";

#define kInvocationIdKey @"invocationId"
#define kCallbackKey @"callback"

@implementation BARemoteJSON {
@private
	volatile int32_t _nextInvocationId;
}

- (NSURLRequest *)remoteJSON:(BARemoteJSON *)remoteJSON requestWithRPCString:(NSString *)RPCString {
	@throw [NSException exceptionWithName:@"BARemoteJSONNotImplemented"
								   reason:@"Request factory method is not implemented"
								 userInfo:nil];
}

- (int32_t)nextInvocationId {
	return OSAtomicIncrement32(&_nextInvocationId);
}

+ (void)validateMethodName:(NSString *)methodName {
	if (!methodName || [methodName length] == 0 || [methodName hasPrefix:@"rpc."]) {
		@throw [NSException exceptionWithName:@"BARemoteJSONInvalidMethodName"
									   reason:@"Invalid method name"
									 userInfo:nil];
	}
}

- (void)invokeMethod:(NSString *)methodName completion:(BARemoteJSONCallback)completion {
	[self invokeMethod:methodName withParameters:nil completion:completion];
}

- (void)invokeMethod:(NSString *)methodName withParameters:(id)parameters completion:(BARemoteJSONCallback)completion {
	[[self class] validateMethodName:methodName];
	int32_t invocationId = [self nextInvocationId];
	NSMutableString *RPCString = [NSMutableString string];
	[RPCString appendFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"%@\",\"id\":\"%d\"", methodName, invocationId];
	if (parameters) {
		NSError *error = nil;
		NSString *parametersString = [BARuntime serializeJSONToString:parameters error:&error];
		if (!parametersString) {
			completion(nil, error);
			return;
		}
		[RPCString appendString:@",\"params\":"];
		[RPCString appendString:parametersString];
	}
	[RPCString appendString:@"}"];
	NSURLRequest *request = [self remoteJSON:self requestWithRPCString:RPCString];
	BADataLoader *loader = [[[BADataLoader alloc] initWithRequest:request] autorelease];
	loader.delegate = self;
	[loader.userInfo setObject:[NSNumber numberWithInt:invocationId] forKey:kInvocationIdKey];
	[loader.userInfo setObject:completion forKey:kCallbackKey];
	[loader startIgnoreCache:NO];
}

- (void)notifyMethod:(NSString *)methodName {
	[self notifyMethod:methodName withParameters:nil];
}

- (void)notifyMethod:(NSString *)methodName withParameters:(id)parameters {
	[[self class] validateMethodName:methodName];
	NSMutableString *RPCString = [NSMutableString string];
	[RPCString appendFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"%@\"", methodName];
	if (parameters) {
		NSError *error = nil;
		NSString *parametersString = [BARuntime serializeJSONToString:parameters error:&error];
		if (!parametersString) {
			return;
		}
		[RPCString appendString:@",\"params\":"];
		[RPCString appendString:parametersString];
	}
	[RPCString appendString:@"}"];
	NSURLRequest *request = [self remoteJSON:self requestWithRPCString:RPCString];
	BADataLoader *loader = [[[BADataLoader alloc] initWithRequest:request] autorelease];
	loader.cache = nil;
	[loader startIgnoreCache:YES];
}

- (void)loader:(BADataLoader *)loader didFinishLoadingData:(NSData *)data fromCache:(BOOL)fromCache {
	BARemoteJSONCallback completion = [loader.userInfo objectForKey:kCallbackKey];
	if (completion) {
		NSError *error = nil;
		id JSONValue = [BARuntime parseJSONData:data error:&error];
		if (!JSONValue) {
			completion(nil, error);
			return;
		}
		if (![JSONValue isKindOfClass:[NSDictionary class]]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error);
			return;
		}
		id versionObj = [JSONValue objectForKey:@"jsonrpc"];
		if (![@"2.0" isEqual:versionObj]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error);
			return;
		}
		id errorObj = [JSONValue objectForKey:@"error"];
		if (errorObj) {
			if (![errorObj isKindOfClass:[NSDictionary class]]) {
				error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
				completion(nil, error);
				return;
			}
			id errorCodeObj = [errorObj objectForKey:@"code"];
			if (![errorCodeObj isKindOfClass:[NSNumber class]]) {
				error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
				completion(nil, error);
				return;
			}
			id errorMessageObj = [errorObj objectForKey:@"message"];
			if (errorMessageObj && ![errorMessageObj isKindOfClass:[NSString class]]) {
				error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
				completion(nil, error);
				return;
			}
			id errorDataObj = [errorObj objectForKey:@"data"];
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
			if (errorMessageObj) {
				[userInfo setObject:errorMessageObj forKey:NSLocalizedDescriptionKey];
			}
			if (errorDataObj) {
				[userInfo setObject:errorDataObj forKey:BARemoteJSONErrorDataKey];
			}
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:[errorCodeObj intValue] userInfo:userInfo];
			completion(nil, error);
			return;
		}
		id invocationIdObj = [JSONValue objectForKey:@"id"];
		if (![invocationIdObj isKindOfClass:[NSNumber class]]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error);
			return;
		}
		int32_t invocationId = [invocationIdObj intValue];
		int32_t expectedInvocationId = -1;
		id expectedInvocationIdObj = [loader.userInfo objectForKey:kInvocationIdKey];
		if ([expectedInvocationIdObj isKindOfClass:[NSNumber class]]) {
			expectedInvocationId = [expectedInvocationIdObj intValue];
		}
		if (invocationId != expectedInvocationId) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error);
			return;
		}
		id result = [JSONValue objectForKey:@"result"];
		completion(result, nil);
	}
}

- (void)loader:(BADataLoader *)loader didFailWithError:(NSError *)error {
	BARemoteJSONCallback completion = [loader.userInfo objectForKey:kCallbackKey];
	if (completion) {
		completion(nil, error);
	}
}

@end
