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

// You are supposed to make a subclass of BARemoteJSON for each endpoint of your backend
// and override -remoteJSON:requestWithRPCString: method that creates requests for RPC strings.
// It's also recommended to add descriptive methods that pack their arguments and call
// the generic -invokeMethod:withParameters:completion method to define a meaningful backend API.

#import <Foundation/Foundation.h>
#import "BADataLoader.h"

typedef enum {
    BARemoteJSONParseError = -32700,
    BARemoteJSONInvalidRequest = -32600,
    BARemoteJSONMethodNotFound = -32601,
    BARemoteJSONInvalidParams = -32602,
    BARemoteJSONInternalError = -32603
} BARemoteJSONErrorCode;

extern NSInteger const BARemoteJSONMinErrorCode;
extern NSInteger const BARemoteJSONMaxErrorCode;

extern NSString * const BARemoteJSONErrorDomain;
extern NSString * const BARemoteJSONErrorDataKey;

// Normally backend replies with some result and no errors (nils).
// If a paticular method fails to execute then it's callback is called once with methodError.
// All other errors like connection failure, invalid JSON or invalid response stucture are passed as
// invocationError to all callbacks in the batch and they could be called several times.
// IOW when we can identify method which has failed then error is passed as methodError
// otherwise error passed as invocationError (to all callbacks in the batch).
typedef void (^BARemoteJSONCallback)(id result, NSError *methodError, NSError *invocationError);

@interface BARemoteJSON : NSObject <BADataLoaderDelegate>

// MUST override to enable communication.
- (NSURLRequest *)remoteJSON:(BARemoteJSON *)remoteJSON requestWithRPCString:(NSString *)RPCString;

// All method invocations made within the block will be batched.
// Nested invocations of this method execute within the current batch.
- (void)batchCalls:(void (^)())block;

// Clients call methods defined below to communicate with the backend.
// Completion block can't be nil.
- (void)invokeMethod:(NSString *)methodName completion:(BARemoteJSONCallback)completion;
- (void)invokeMethod:(NSString *)methodName withParameters:(id)parameters completion:(BARemoteJSONCallback)completion;
- (void)notifyMethod:(NSString *)methodName;
- (void)notifyMethod:(NSString *)methodName withParameters:(id)parameters;

@end
