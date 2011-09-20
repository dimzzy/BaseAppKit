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

#import "BAPager.h"
#import "UIView+BACookie.h"

@implementation BAPager

@synthesize delegate = _delegate;

- (void)dealloc {
	self.delegate = nil;
	self.scrollView = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init])) {
		_currentPageIndex = -1;
	}
	return self;
}

- (UIView *)addPageAtIndex:(NSInteger)index cache:(NSMutableDictionary *)cache {
	id key = [NSNumber numberWithInteger:index];
	UIView *page = [cache objectForKey:key];
	if (page) {
		[[page retain] autorelease];
		[cache removeObjectForKey:key];
	} else {
		page = [self.delegate pager:self pageAtIndex:index];
		page.cookie = key;
		[self.scrollView addSubview:page];
	}
	return page;
}

- (void)reloadPages {
	if (!self.scrollView) {
		return;
	}

	NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithCapacity:[self.scrollView.subviews count]];
	for (UIView *view in [NSArray arrayWithArray:self.scrollView.subviews]) {
		id cookie = view.cookie;
		if (cookie && [cookie isKindOfClass:[NSNumber class]]) {
			[cache setObject:view forKey:cookie];
		} else {
			[view removeFromSuperview]; // should not reach this point though; do it just in case
		}
	}
	
	if (_numberOfPages > 0 && _currentPageIndex >= 0) {
		const CGFloat pageWidth = self.scrollView.bounds.size.width;
		const CGFloat pageHeight = self.scrollView.bounds.size.height;
		CGFloat offset = 0;
		CGFloat x = 0;
		CGFloat width = pageWidth;

		if (_currentPageIndex > 0) {
			// add prev page
			UIView *prevPage = [self addPageAtIndex:(_currentPageIndex - 1) cache:cache];
			prevPage.frame = CGRectMake(x, 0, pageWidth, pageHeight);
			offset = pageWidth;
			x += pageWidth;
			width += pageWidth;
		}

		// add curr page
		UIView *currPage = [self addPageAtIndex:_currentPageIndex cache:cache];
		currPage.frame = CGRectMake(x, 0, pageWidth, pageHeight);
		x += pageWidth;

		if (_currentPageIndex < (NSInteger)(_numberOfPages - 1)) {
			// add next page
			UIView *nextPage = [self addPageAtIndex:(_currentPageIndex + 1) cache:cache];
			nextPage.frame = CGRectMake(x, 0, pageWidth, pageHeight);
			width += pageWidth;
		}
		
		self.scrollView.contentOffset = CGPointMake(offset, 0);
		self.scrollView.contentSize = CGSizeMake(width, pageHeight);
		[cache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(pager:dropPageAtIndex:)]) {
				[self.delegate pager:self dropPageAtIndex:[key integerValue]];
			}
			[obj removeFromSuperview];
		}];
	}
}

- (NSUInteger)numberOfPages {
	return _numberOfPages;
}

- (void)setNumberOfPages:(NSUInteger)count {
	if (_numberOfPages == count) {
		return;
	}
	_numberOfPages = count;
	if (_currentPageIndex >= (NSInteger)count) {
		_currentPageIndex = count - 1;
		if (self.delegate && [self.delegate respondsToSelector:@selector(pager:currentPageDidChangeTo:)]) {
			[self.delegate pager:self currentPageDidChangeTo:_currentPageIndex];
		}
	}
	[self reloadPages];
}

- (NSInteger)currentPageIndex {
	return _currentPageIndex;
}

- (void)setCurrentPageIndex:(NSInteger)index {
	if (index < -1) {
		index = -1;
	} else if (index >= (NSInteger)self.numberOfPages) {
		index = self.numberOfPages - 1;
	}
	if (_currentPageIndex == index) {
		return;
	}
	_currentPageIndex = index;
	if (self.delegate && [self.delegate respondsToSelector:@selector(pager:currentPageDidChangeTo:)]) {
		[self.delegate pager:self currentPageDidChangeTo:_currentPageIndex];
	}
	[self reloadPages];
}

- (UIScrollView *)scrollView {
	return _scrollView;
}

- (void)setScrollView:(UIScrollView *)scrollView {
	if (_scrollView == scrollView) {
		return;
	}
	[_scrollView release];
	_scrollView = [scrollView retain];
	_scrollView.delegate = self;
	[self reloadPages];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	CGFloat offset = scrollView.contentOffset.x;
	NSInteger localIndex = offset / scrollView.bounds.size.width;
	if (self.currentPageIndex > 0) {
		localIndex--;
	}
	self.currentPageIndex += localIndex;
}

@end
