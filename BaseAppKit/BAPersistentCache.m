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

@implementation BAPersistentCache

@synthesize path = _path;

+ (BAPersistentCache *)persistentCache {
	static BAPersistentCache *instance;
	if (!instance) {
		instance = [[BAPersistentCache alloc] init];
	}
    return instance;
}

- (id)init {
	if ((self = [super init])) {
		NSString *defaultPath = [@"~/Library/Caches/DataCache" stringByExpandingTildeInPath];
		if ([[NSFileManager defaultManager] fileExistsAtPath:defaultPath]) {
			self.path = defaultPath;
		} else {
			if ([[NSFileManager defaultManager] createDirectoryAtPath:defaultPath
										  withIntermediateDirectories:YES
														   attributes:nil
																error:NULL]) {
				self.path = defaultPath;
			} else {
				self.path = [@"~/Library/Caches" stringByExpandingTildeInPath];
			}
		}
	}
	return self;
}

- (NSString *)pathForKey:(NSString *)key {
	return [self.path stringByAppendingPathComponent:[key MD5Hash]];
}

- (NSDate *)modificationDateForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
	return attributes ? [attributes objectForKey:NSFileModificationDate] : nil;
}


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


- (void)clearOldData {
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-kBAPersistentCacheRetainInterval];
	[self clearDataOlderThan:date];
}

- (void)clearDataOlderThan:(NSDate *)date {
	@synchronized(self) {

		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
		for (NSString *file in files) {
			NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:self.path, file, nil]];
			NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
			if (attributes) {
				NSDate *modificationDate = [attributes objectForKey:NSFileModificationDate];
				if (modificationDate && [modificationDate compare:date] == NSOrderedAscending) {
					[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
				}
			}
		}

	}
}

@end
