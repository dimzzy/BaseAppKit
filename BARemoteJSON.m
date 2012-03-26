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


// Key for data loader to keep invocation ids and completion blocks
#define kCallbacksKey @"callbacks"

// Keys for local thread storage to keep serialized rpc calls and completion blocks
#define kBatchedCallsKey @"baseappkit.batchedCalls"
#define kBatchedCallbacksKey @"baseappkit.batchedCallbacks"


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

- (NSMutableArray *)batchedCalls {
	return [[NSThread currentThread].threadDictionary objectForKey:kBatchedCallsKey];
}

- (void)setBatchedCalls:(NSMutableArray *)batchedCalls {
	if (batchedCalls) {
		[[NSThread currentThread].threadDictionary setObject:batchedCalls forKey:kBatchedCallsKey];
	} else {
		[[NSThread currentThread].threadDictionary removeObjectForKey:kBatchedCallsKey];
	}
}

- (NSMutableDictionary *)batchedCallbacks {
	return [[NSThread currentThread].threadDictionary objectForKey:kBatchedCallbacksKey];
}

- (void)setBatchedCallbacks:(NSMutableDictionary *)batchedCallbacks {
	if (batchedCallbacks) {
		[[NSThread currentThread].threadDictionary setObject:batchedCallbacks forKey:kBatchedCallbacksKey];
	} else {
		[[NSThread currentThread].threadDictionary removeObjectForKey:kBatchedCallbacksKey];
	}
}

- (void)batchCalls:(void (^)())block {
	NSMutableArray *batchedCalls = [self batchedCalls]; // [rpc as serialized json:NSString]
	if (batchedCalls) {
		block();
		return;
	}
	batchedCalls = [NSMutableArray array];
	[self setBatchedCalls:batchedCalls];
	NSMutableDictionary *batchedCallbacks = [self batchedCallbacks]; // invocationId:NSNumber -> callback:block
	if (!batchedCallbacks) {
		batchedCallbacks = [NSMutableDictionary dictionary];
		[self setBatchedCallbacks:batchedCallbacks];
	}
	@try {
		block();
		if ([batchedCalls count] > 0) {
			__block NSMutableString *RPCString = [NSMutableString string];
			[batchedCalls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([RPCString length] == 0) {
					[RPCString appendString:@"["];
				} else {
					[RPCString appendString:@","];
				}
				[RPCString appendString:obj];
			}];
			if ([RPCString length] > 0) {
				[RPCString appendString:@"]"];
			}
			NSURLRequest *request = [self remoteJSON:self requestWithRPCString:RPCString];
			BADataLoader *loader = [[[BADataLoader alloc] initWithRequest:request] autorelease];
			loader.delegate = self;
			[loader.userInfo setObject:batchedCallbacks forKey:kCallbacksKey];
			[loader startIgnoreCache:NO];
		}
	}
	@finally {
		[self setBatchedCalls:nil];
		[self setBatchedCallbacks:nil];
	}
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
			completion(nil, error, nil);
			return;
		}
		[RPCString appendString:@",\"params\":"];
		[RPCString appendString:parametersString];
	}
	[RPCString appendString:@"}"];
	
	NSMutableArray *batchedCalls = [self batchedCalls];
	if (batchedCalls) {
		[batchedCalls addObject:RPCString];
		NSMutableDictionary *batchedCallbacks = [self batchedCallbacks];
		completion = Block_copy(completion);
		[batchedCallbacks setObject:completion forKey:[NSNumber numberWithInt:invocationId]];
		Block_release(completion);
	} else {
		NSURLRequest *request = [self remoteJSON:self requestWithRPCString:RPCString];
		BADataLoader *loader = [[[BADataLoader alloc] initWithRequest:request] autorelease];
		loader.delegate = self;
		completion = Block_copy(completion);
		NSDictionary *callbacks = [NSDictionary dictionaryWithObject:completion
															  forKey:[NSNumber numberWithInt:invocationId]];
		Block_release(completion);
		[loader.userInfo setObject:callbacks forKey:kCallbacksKey];
		[loader startIgnoreCache:NO];
	}
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
	
	NSMutableArray *batchedCalls = [self batchedCalls];
	if (batchedCalls) {
		[batchedCalls addObject:RPCString];
	} else {
		NSURLRequest *request = [self remoteJSON:self requestWithRPCString:RPCString];
		BADataLoader *loader = [[[BADataLoader alloc] initWithRequest:request] autorelease];
		loader.cache = nil;
		[loader startIgnoreCache:YES];
	}
}

- (void)reportInvocationError:(NSError *)error callbacks:(NSDictionary *)callbacks {
	if (!error) {
		error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
	}
	[callbacks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		BARemoteJSONCallback completion = obj;
		completion(nil, nil, error);
	}];
}

- (void)handleResponse:(id)JSONValue callbacks:(NSDictionary *)callbacks {
	NSError *error = nil;
	if (![JSONValue isKindOfClass:[NSDictionary class]]) {
		[self reportInvocationError:nil callbacks:callbacks];
		return;
	}
	id versionObj = [JSONValue objectForKey:@"jsonrpc"];
	if (![@"2.0" isEqual:versionObj]) {
		[self reportInvocationError:nil callbacks:callbacks];
		return;
	}
	id invocationIdObj = [JSONValue objectForKey:@"id"];
	if (![invocationIdObj isKindOfClass:[NSNumber class]] && ![invocationIdObj isKindOfClass:[NSString class]]) {
		[self reportInvocationError:nil callbacks:callbacks];
		return;
	}
	int32_t invocationId = [invocationIdObj intValue];
	BARemoteJSONCallback completion = [callbacks objectForKey:[NSNumber numberWithInt:invocationId]];
	if (!completion) {
		[self reportInvocationError:nil callbacks:callbacks];
		return;
	}
	
	// Now we know the particular invocation and can report error for a particular method
	
	id errorObj = [JSONValue objectForKey:@"error"];
	if (errorObj) {
		if (![errorObj isKindOfClass:[NSDictionary class]]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error, nil);
			return;
		}
		id errorCodeObj = [errorObj objectForKey:@"code"];
		if (![errorCodeObj isKindOfClass:[NSNumber class]]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error, nil);
			return;
		}
		id errorMessageObj = [errorObj objectForKey:@"message"];
		if (errorMessageObj && ![errorMessageObj isKindOfClass:[NSString class]]) {
			error = [NSError errorWithDomain:BARemoteJSONErrorDomain code:BARemoteJSONInternalError userInfo:nil];
			completion(nil, error, nil);
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
		completion(nil, error, nil);
		return;
	}
	id result = [JSONValue objectForKey:@"result"];
	completion(result, nil, nil);
}

- (void)loader:(BADataLoader *)loader didFinishLoadingData:(NSData *)data fromCache:(BOOL)fromCache {
	NSDictionary *callbacks = [loader.userInfo objectForKey:kCallbacksKey];
	NSError *error = nil;
	id JSONValue = [BARuntime parseJSONData:data error:&error];
	if (!JSONValue) {
		[self reportInvocationError:error callbacks:callbacks];
		return;
	}
//	NSLog(@"response: %@", JSONValue);
	if ([JSONValue isKindOfClass:[NSDictionary class]]) {
		// Response to a single call
		[self handleResponse:JSONValue callbacks:callbacks];
	} else if ([JSONValue isKindOfClass:[NSArray class]]) {
		// Response to a batch call
		for (id JSONResponse in JSONValue) {
			[self handleResponse:JSONResponse callbacks:callbacks];
		}
	}
}

- (void)loader:(BADataLoader *)loader didFailWithError:(NSError *)error {
	NSDictionary *callbacks = [loader.userInfo objectForKey:kCallbacksKey];
	[self reportInvocationError:error callbacks:callbacks];
}

@end
