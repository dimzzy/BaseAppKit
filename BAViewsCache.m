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

#import "BAViewsCache.h"

@implementation BAViewsCache {
	NSMutableDictionary *_allViews; // reuseIdentifier -> NSMutableArray:UIView
	NSUInteger _capacityPerType;
}

@synthesize capacityPerType = _capacityPerType;

- (id)init {
	if ((self = [super init])) {
		_allViews = [[NSMutableDictionary alloc] init];
		_capacityPerType = 8;
	}
	return self;
}

+ (BAViewsCache *)sharedCache {
	static BAViewsCache *cache;
	if (!cache) {
		cache = [[BAViewsCache alloc] init];
	}
	return cache;
}

- (UIView<BAReusableView> *)dequeueReusableViewWithIdentifier:(NSString *)reuseIdentifier {
	if (!reuseIdentifier) {
		return nil;
	}
	NSMutableArray *views = [_allViews objectForKey:reuseIdentifier];
	UIView<BAReusableView> *view = [views lastObject];
	if (view) {
		[[view retain] autorelease];
		[views removeLastObject];
		return view;
	}
	return nil;
}

- (void)enqueueReusableView:(UIView<BAReusableView> *)view {
	if (![view reuseIdentifier]) {
		return;
	}
	NSMutableArray *views = [_allViews objectForKey:[view reuseIdentifier]];
	if (views) {
		if ([views count] < self.capacityPerType) {
			[views addObject:view];
		}
	} else {
		views = [NSMutableArray arrayWithObject:view];
		[_allViews setObject:views forKey:[view reuseIdentifier]];
	}
}

- (void)removeReusableView:(UIView<BAReusableView> *)view {
	if (![view reuseIdentifier]) {
		return;
	}
	NSMutableArray *views = [_allViews objectForKey:[view reuseIdentifier]];
	if (views) {
		[views removeObjectIdenticalTo:view];
	}
}

- (void)clear {
	[_allViews removeAllObjects];
}

@end
