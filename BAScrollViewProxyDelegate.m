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

#import "BAScrollViewProxyDelegate.h"

@implementation BAScrollViewProxyDelegate

@synthesize delegate = _delegate;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[self.delegate scrollViewDidScroll:scrollView];
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
		[self.delegate scrollViewDidZoom:scrollView];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
		[self.delegate scrollViewWillBeginDragging:scrollView];
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
		[self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
		[self.delegate scrollViewWillBeginDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[self.delegate scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
		[self.delegate scrollViewDidEndScrollingAnimation:scrollView];
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
		[self.delegate viewForZoomingInScrollView:scrollView];
	}
	return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
		[self.delegate scrollViewWillBeginZooming:scrollView withView:view];
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
		[self.delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
		return [self.delegate scrollViewShouldScrollToTop:scrollView];
	}
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
		[self.delegate scrollViewDidScrollToTop:scrollView];
	}
}

@end
