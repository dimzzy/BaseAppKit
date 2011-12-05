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

#import "BAKeyboardTracker.h"

@interface BAKeyboardTracker (Private)

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

@end


@implementation BAKeyboardTracker

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[_scrollView release];
	[super dealloc];
}

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
	}
    return self;
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
	_priorFrame = CGRectZero;
    if (CGSizeEqualToSize(_scrollView.contentSize, CGSizeZero)) {
        _scrollView.contentSize = _scrollView.bounds.size;
    }
}

- (UIView *)findFirstResponderBeneathView:(UIView *)view {
    // Search recursively for first responder
    for (UIView *childView in view.subviews) {
        if ([childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder]) {
			return childView;
		}
        UIView *result = [self findFirstResponderBeneathView:childView];
        if (result) {
			return result;
		}
    }
    return nil;
}

- (void)scrollViewFrameDidChange {
}

- (CGFloat)bottomSpacing {
	return 0;
}

- (void)keyboardWillShow:(NSNotification *)notification {
	if (!self.scrollView) {
		return;
	}
    if (!CGRectEqualToRect(_priorFrame, CGRectZero)) {
		return;
	}
	
    UIView *firstResponder = [self findFirstResponderBeneathView:self.scrollView];
//    if (!firstResponder) {
//        // No child view is the first responder - nothing to do here
//        return;
//    }
    
    _priorFrame = self.scrollView.frame;
    
    // Use this view's coordinate system
    CGRect keyboardBounds = [self.scrollView convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGRect screenBounds = [self.scrollView convertRect:[UIScreen mainScreen].bounds fromView:nil];
    if (keyboardBounds.origin.y == 0) {
		keyboardBounds.origin = CGPointMake(0, screenBounds.size.height - keyboardBounds.size.height);
	}
    
    CGFloat spaceAboveKeyboard = keyboardBounds.origin.y - self.scrollView.bounds.origin.y;
    CGFloat offset = -1;
    
    CGRect newFrame = self.scrollView.frame;
	const CGFloat keyboardBottom = keyboardBounds.origin.y + keyboardBounds.size.height;
	const CGFloat scrollViewBottom = self.scrollView.bounds.origin.y + self.scrollView.bounds.size.height;
    newFrame.size.height -= keyboardBounds.size.height - (keyboardBottom - scrollViewBottom) + [self bottomSpacing];

    if (firstResponder) {
		
    CGRect firstResponderFrame = [firstResponder convertRect:firstResponder.bounds toView:self.scrollView];
    if (firstResponderFrame.origin.y + firstResponderFrame.size.height >= screenBounds.origin.y + screenBounds.size.height - keyboardBounds.size.height) {
        // Prepare to scroll to make sure the view is above the keyboard
        offset = firstResponderFrame.origin.y + self.scrollView.contentOffset.y;
        if (self.scrollView.contentSize.height - offset < newFrame.size.height) {
            // Scroll to the bottom
            offset = self.scrollView.contentSize.height - newFrame.size.height;
        } else {
            if (firstResponder.bounds.size.height < spaceAboveKeyboard) {
                // Center vertically if there's room
                offset -= floor((spaceAboveKeyboard - firstResponder.bounds.size.height) / 2.0);
            }
            if (offset + newFrame.size.height > self.scrollView.contentSize.height) {
                // Clamp to content size
                offset = self.scrollView.contentSize.height - newFrame.size.height;
            }
        }
    }
    
	} else {
		
		// Maintain visible portion of scroll view at the bottom
		if (self.scrollView.contentSize.height > newFrame.size.height) {
			CGFloat bottomY;
			if (self.scrollView.contentSize.height > self.scrollView.bounds.size.height) {
				bottomY = self.scrollView.contentOffset.y + self.scrollView.bounds.size.height;
			} else {
				bottomY = self.scrollView.contentSize.height;
			}
			offset = bottomY - newFrame.size.height;
		}
	}
	
    // Shrink view's height by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    self.scrollView.frame = newFrame;
    if (offset != -1) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, offset) animated:YES];
    }
	[self scrollViewFrameDidChange];
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	if (!self.scrollView) {
		return;
	}
    if (CGRectEqualToRect(_priorFrame, CGRectZero)) {
		return;
	}
    
    // Restore dimensions to prior size
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    self.scrollView.frame = _priorFrame;
    _priorFrame = CGRectZero;
	[self scrollViewFrameDidChange];
    [UIView commitAnimations];
}

@end
