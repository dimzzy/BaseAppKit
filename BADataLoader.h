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
- (void)loaderDidReceiveResponse:(BADataLoader *)loader;
- (void)loaderDidReceiveData:(BADataLoader *)loader;

@end

// Quick note on caching
// 
// By default loader uses shared persistent cache.
// You can set it to nil to completely disable caching.
// When you ask for data ignoring cache the loader does not check
// if data is in cache but loaded data is saved in the cache.

@interface BADataLoader : NSObject

@property(nonatomic, readonly) NSURLRequest *request;
@property(nonatomic, readonly) NSURLResponse *response;
@property(nonatomic, readonly) NSHTTPURLResponse *HTTPResponse;
@property(nonatomic, retain) BAPersistentCache *cache;
@property(nonatomic, readonly) NSUInteger expectedBytesCount;
@property(nonatomic, readonly) NSUInteger receivedBytesCount;
@property(nonatomic, readonly) float progress; // 0..1
@property(nonatomic, assign) id<BADataLoaderDelegate> delegate;
@property(nonatomic, readonly) NSMutableDictionary *userInfo;
@property(nonatomic, readonly) NSStringEncoding dataEncoding;

- (id)initWithRequest:(NSURLRequest *)request;
- (void)startIgnoreCache:(BOOL)ignoreCache;
- (void)cancel;
- (float)progressWithExpectedBytesCount:(NSUInteger)expectedBytesCount;

+ (void)addHTTPQueryToString:(NSMutableString *)query
			   forDictionary:(NSDictionary *)dict
			   usingEncoding:(NSStringEncoding)encoding;

+ (void)addHTTPQueryToString:(NSMutableString *)query
					forArray:(NSArray *)array
			   withParameter:(NSString *)parameter
			   usingEncoding:(NSStringEncoding)encoding;

+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)URL;
+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL data:(NSData *)data;
+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL form:(NSDictionary *)form;
+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL JSON:(NSData *)JSONData;


// Subclasses API

- (void)resetConnection;
// If returns YES then received data is cached, otherwise received data is considered invalid and not cached.
- (BOOL)prepareData:(NSData *)data;

@end
