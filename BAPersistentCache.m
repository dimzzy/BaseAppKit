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

#import "BAPersistentCache.h"
#import "NSString+BACoding.h"

@interface BAPersistencePolicyKeepForever : NSObject <BAPersistencePolicy>

@end

@implementation BAPersistencePolicyKeepForever

- (BOOL)staleContentAtPath:(NSString *)path {
	return NO;
}

@end


@interface BAPersistencePolicyKeepForSomeTime : NSObject <BAPersistencePolicy> {
@private
	NSTimeInterval _timeInterval;
}

@end

@implementation BAPersistencePolicyKeepForSomeTime

- (id)initWithTimeInterval:(NSTimeInterval)timeInterval {
	if ((self = [super init])) {
		_timeInterval = timeInterval;
	}
	return self;
}

- (BOOL)staleContentAtPath:(NSString *)path {
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
	if (!attributes) {
		return YES;
	}
	NSDate *modificationDate = [attributes objectForKey:NSFileModificationDate];
	if (!modificationDate) {
		return YES;
	}
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-_timeInterval];
	if ([modificationDate compare:date] == NSOrderedAscending) {
		return YES;
	}
	return NO;
}

@end


@implementation BAPersistentCache

@synthesize path = _path;
@synthesize defaultPolicy = _defaultPolicy;

+ (BAPersistentCache *)persistentCache {
	static BAPersistentCache *instance;
	if (!instance) {
		instance = [[BAPersistentCache alloc] init];
	}
    return instance;
}

+ (id<BAPersistencePolicy>)keepForeverPolicy {
	static BAPersistencePolicyKeepForever *keepForeverPolicy;
	if (!keepForeverPolicy) {
		keepForeverPolicy = [[BAPersistencePolicyKeepForever alloc] init];
	}
	return keepForeverPolicy;
}

+ (id<BAPersistencePolicy>)keepForSomeTimePolicy:(NSTimeInterval)timeInterval {
	return [[[BAPersistencePolicyKeepForSomeTime alloc] initWithTimeInterval:timeInterval] autorelease];
}

- (void)dealloc {
	[_path release];
	[_policiesByKeyHashes release];
	[_defaultPolicy release];
	[super dealloc];
}

- (id)initWithPath:(NSString *)defaultPath {
	if ((self = [super init])) {
		if (![[NSFileManager defaultManager] fileExistsAtPath:defaultPath]) {
			if (![[NSFileManager defaultManager] createDirectoryAtPath:defaultPath
										   withIntermediateDirectories:YES
															attributes:nil
																 error:NULL]) {
				NSLog(@"Error creating cache at %@", defaultPath);
			}
		}
		_path = [defaultPath retain];
		_defaultPolicy = [[[self class] keepForSomeTimePolicy:kBAPersistentCacheRetainInterval] retain];
	}
	return self;
}

- (id)init {
	NSString *defaultPath = [@"~/Library/Caches/DataCache" stringByExpandingTildeInPath];
	return [self initWithPath:defaultPath];
}

- (id<BAPersistencePolicy>)policyForKey:(NSString *)key {
	return [_policiesByKeyHashes objectForKey:[key MD5Hash]];
}

- (void)setPolicy:(id<BAPersistencePolicy>)policy forKey:(NSString *)key {
	if (!_policiesByKeyHashes) {
		_policiesByKeyHashes = [[NSMutableDictionary alloc] init];
	}
	[_policiesByKeyHashes setObject:policy forKey:[key MD5Hash]];
}

- (void)flush {
	@synchronized(self) {
		
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
		for (NSString *file in files) {
			NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:self.path, file, nil]];
			id<BAPersistencePolicy> policy = [_policiesByKeyHashes objectForKey:file];
			if (!policy) {
				policy = _defaultPolicy;
			}
			if (!policy || [policy staleContentAtPath:path]) {
				[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
			}
		}
		
	}
}

- (NSString *)pathForKey:(NSString *)key {
	return [self.path stringByAppendingPathComponent:[key MD5Hash]];
}

//- (NSDate *)modificationDateForKey:(NSString *)key {
//	NSString *path = [self pathForKey:key];
//	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
//	return attributes ? [attributes objectForKey:NSFileModificationDate] : nil;
//}


- (BOOL)hasDataForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSData *)dataForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	return [NSData dataWithContentsOfFile:path];
}

- (void)setData:(id)data forKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	[data writeToFile:path atomically:YES];
}

- (void)clearDataForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	}
}


- (id)objectForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

- (void)setObject:(id)object forKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	[NSKeyedArchiver archiveRootObject:object toFile:path];
}


- (UIImage *)imageForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	return [UIImage imageWithContentsOfFile:path];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	NSData *data = UIImageJPEGRepresentation(image, 1.0);
	[data writeToFile:path atomically:YES];
}

@end
