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

#import "BADataLoader.h"
#import "BANetworkActivity.h"
#import "NSDictionary+BAHTTP.h"

@interface BADataLoader()

@property(nonatomic, retain) NSMutableData *receivedData;

@end


@implementation BADataLoader

@synthesize request = _request;
@synthesize cache = _cache;
@synthesize receivedData = _receivedData;
@synthesize expectedBytesCount = _expectedBytesCount;
@synthesize statusCode = _statusCode;
@synthesize delegate = _delegate;
@synthesize dataEncoding = _dataEncoding;

- (id)initWithRequest:(NSURLRequest *)request {
	if ((self = [super init])) {
		_request = [request retain];
		_cache = [[BAPersistentCache persistentCache] retain];
	}
	return self;
}

- (void)resetConnection {
	if (_currentConnection) {
		[_currentConnection cancel];
		[_currentConnection release];
		_currentConnection = nil;
	}
	self.receivedData = nil;
	_expectedBytesCount = 0;
}

- (void)dealloc {
	self.delegate = nil;
	[self resetConnection];
	[_request release];
	[_cache release];
	[_userInfo release];
	[super dealloc];
}

- (void)prepareData:(NSData *)data {
}

- (void)loadIgnoreCache:(NSNumber *)ignoreCacheWrapper {
	BOOL ignoreCache = [ignoreCacheWrapper boolValue];
	[self resetConnection];
	if (_request) {
		NSData *cachedData = nil;
		if (!ignoreCache && self.cache) {
			NSString *key = [_request.URL absoluteString];
			cachedData = [self.cache dataForKey:key];
		}
		if (cachedData) {
			//NSLog(@"#> %@", [_request URL]);
			[self prepareData:cachedData];
			if (_delegate) {
				[_delegate loader:self didFinishLoadingData:cachedData fromCache:YES];
			}
		} else {
			//NSLog(@">> %@", [_request URL]);
			_currentConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
			if (_currentConnection) {
				self.receivedData = [NSMutableData data];
				[[BANetworkActivity networkActivity] start];
			} else {
				if (_delegate) {
					[_delegate loader:self didFailWithError:nil];
				}
			}
		}
	} else {
		if (_delegate) {
			[_delegate loader:self didFailWithError:nil];
		}
	}
}

- (void)startIgnoreCache:(BOOL)ignoreCache {
	// Defer actual loading so delegate methods are not invoked immediately
	// thus giving the callee a chance to prepare to handle them
	[self performSelector:@selector(loadIgnoreCache:)
			   withObject:[NSNumber numberWithBool:ignoreCache]
			   afterDelay:0];
}

- (void)cancel {
	if (_currentConnection) {
		[[BANetworkActivity networkActivity] stop];
	}
	[self resetConnection];
}

- (NSUInteger)receivedBytesCount {
	return [self.receivedData length];
}

- (float)progressWithExpectedBytesCount:(NSUInteger)expectedBytesCount {
	if (expectedBytesCount == 0 || self.receivedBytesCount == 0) {
		return 0;
	}
	if (self.receivedBytesCount >= expectedBytesCount) {
		return 1;
	}
	return (double)self.receivedBytesCount / (double)expectedBytesCount;
}

- (float)progress {
	return [self progressWithExpectedBytesCount:self.expectedBytesCount];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [_receivedData setLength:0];
	long long length = [response expectedContentLength];
	_expectedBytesCount = (length <= 0) ? 0 : length;
	_dataEncoding = NSUTF8StringEncoding;
	if ([response textEncodingName]) {
		CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]);
		if (encoding != kCFStringEncodingInvalidId) {
			_dataEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
		}
	}
	_statusCode = 200;
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
		_statusCode = [HTTPResponse statusCode];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_receivedData appendData:data];
	if (_delegate && [_delegate respondsToSelector:@selector(loaderDidReceiveData:)]) {
		[_delegate loaderDidReceiveData:self];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (_delegate) {
		[_delegate loader:self didFailWithError:error];
	}

	[[BANetworkActivity networkActivity] stop];
    [_currentConnection release];
	_currentConnection = nil;
	[self resetConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (self.cache) {
		[self.cache setData:self.receivedData forKey:[_request.URL absoluteString]];
	}
	[self prepareData:self.receivedData];
	if (_delegate) {
		[_delegate loader:self didFinishLoadingData:self.receivedData fromCache:NO];
	}

	[[BANetworkActivity networkActivity] stop];
    [_currentConnection release];
	_currentConnection = nil;
	[self resetConnection];
}

- (NSMutableDictionary *)userInfo {
	if (!_userInfo) {
		_userInfo = [[NSMutableDictionary alloc] init];
	}
	return _userInfo;
}

+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)URL {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	return request;
}

+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL form:(NSDictionary *)form {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"POST"];
	NSString *post = [form HTTPQueryUsingEncoding:NSUTF8StringEncoding];
	NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	return request;
}

+ (NSMutableURLRequest *)POSTRequestWithURL:(NSURL *)URL JSON:(NSData *)JSON {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"POST"];
	NSString *postLength = [NSString stringWithFormat:@"%d", [JSON length]];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:JSON];
	return request;
}

@end
