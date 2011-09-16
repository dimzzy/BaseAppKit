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

#import <Foundation/Foundation.h>
#import "BAPersistentCache.h"

@class BADataLoader;


@protocol BADataLoaderDelegate <NSObject>

- (void)loader:(BADataLoader *)loader didFinishLoadingData:(NSData *)data fromCache:(BOOL)fromCache;
- (void)loader:(BADataLoader *)loader didFailWithError:(NSError *)error;

@optional
- (void)loaderDidReceiveData:(BADataLoader *)loader;

@end

// Quick note on caching
// 
// There are two options: disable cache and ignore cache.
// When cache is disabled the loader does not use it in any way.
// When you ask for data ignoring cache the loader does not check
// if data is in cache but loaded data is saved in the cache.

@interface BADataLoader : NSObject {
@private
	NSURLRequest *_request;
	BAPersistentCache *_cache;
	NSInteger _statusCode;
    NSMutableData *_receivedData;
	NSStringEncoding _dataEncoding;
	NSUInteger _expectedBytesCount;
    NSURLConnection *_currentConnection;
	id<BADataLoaderDelegate> _delegate;
	NSMutableDictionary *_userInfo;
	
}

@property(nonatomic, readonly) NSURLRequest *request;
@property(nonatomic, retain) BAPersistentCache *cache;
@property(nonatomic, readonly) NSUInteger expectedBytesCount;
@property(nonatomic, readonly) NSUInteger receivedBytesCount;
@property(nonatomic, readonly) float progress; // 0..1
@property(nonatomic, readonly) NSInteger statusCode;
@property(nonatomic, assign) id<BADataLoaderDelegate> delegate;
@property(nonatomic, readonly) NSMutableDictionary *userInfo;

- (id)initWithRequest:(NSURLRequest *)request; // initially uses shared persistent cache
- (void)startIgnoreCache:(BOOL)ignoreCache;
- (void)cancel;
- (float)progressWithExpectedBytesCount:(NSUInteger)expectedBytesCount;

+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)URL;
+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL form:(NSDictionary *)form;
+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL JSON:(NSData *)JSONData;


// Subclasses API

@property(nonatomic, readonly) NSStringEncoding dataEncoding;
- (void)resetConnection;
- (void)prepareData:(NSData *)data;

@end
