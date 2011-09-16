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

#import "BAToggleBar.h"
#import "BAToggleItemLabel.h"

#define kToggleTailWidth 30
#define kToggleAnimationDuration 1

@interface BAToggleBar ()

@property(nonatomic, readonly) NSArray *itemViews;

@end


@interface BAToggleScrollView : UIScrollView {
}

@end

@implementation BAToggleScrollView

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
	BAToggleBar *toggleBar = (BAToggleBar *)self.superview;
	NSUInteger itemViewIndex = [toggleBar.itemViews indexOfObject:view];
	if (itemViewIndex != NSNotFound) {
		[toggleBar setSelectedItemIndex:itemViewIndex revealingItem:NO];
	}
	return YES;
}

@end


@implementation BAToggleBar

@synthesize centered = _centered;
@synthesize spacing = _spacing;
@synthesize itemViews = _itemViews;
@synthesize delegate = _delegate;

- (void)setupView {
	_scrollView = [[BAToggleScrollView alloc] initWithFrame:self.bounds];
	_scrollView.backgroundColor = [UIColor clearColor];
	_scrollView.opaque = NO;
	_scrollView.scrollsToTop = NO;
	_scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	_scrollView.delegate = self;
	[self addSubview:_scrollView];
	
	_leftTailView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"togglebar-left.png"]];
	_leftTailView.userInteractionEnabled = NO;
	_leftTailView.opaque = NO;
	[self addSubview:_leftTailView];
	_leftTailState = BAToggleBarTailStateToggle;
	_leftTailHidden = NO;
	
	_rightTailView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"togglebar-right.png"]];
	_rightTailView.userInteractionEnabled = NO;
	_rightTailView.opaque = NO;
	_rightTailView.backgroundColor = [UIColor clearColor];
	[self addSubview:_rightTailView];
	_rightTailState = BAToggleBarTailStateToggle;
	_rightTailHidden = NO;

	_itemViews = [[NSMutableArray alloc] init];
	_items = [[NSMutableArray alloc] init];
}

- (id)initWithFrame:(CGRect)aRect {
	if ((self = [super initWithFrame:aRect])) {
		[self setupView];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setupView];
}

- (void)dealloc {
	[_scrollView release];
	[_leftTailView release];
	[_rightTailView release];
	[_itemViews release];
	[_items release];
    [super dealloc];
}

- (UIImage *)leftTailImage {
	return _leftTailView.image;
}

- (void)setLeftTailImage:(UIImage *)image {
	_leftTailView.image = image;
}

- (UIImage *)rightTailImage {
	return _rightTailView.image;
}

- (void)setRightTailImage:(UIImage *)image {
	_rightTailView.image = image;
}

- (void)updateLeftTailView:(BOOL)animated {
	BOOL hideLeft = (_scrollView.contentSize.width <= _scrollView.bounds.size.width ||
					 _scrollView.contentOffset.x <= 0);
	switch (self.leftTailState) {
//		case BAToggleBarTailStateToggleAnimated: {
//			_leftTailView.hidden = NO;
//			if (_leftTailHidden && !hideLeft) {
//				_leftTailHidden = NO;
//				if (animated) {
//					[UIView animateWithDuration:kToggleAnimationDuration
//										  delay:0
//										options:UIViewAnimationOptionCurveLinear
//									 animations:^(void) {
//										 CGRect r = _leftTailView.frame;
//										 r.origin.x += kToggleTailWidth;
//										 _leftTailView.frame = r;
//									 }
//									 completion:^(BOOL finished) {}];
//				} else {
//					CGRect r = _leftTailView.frame;
//					r.origin.x += kToggleTailWidth;
//					_leftTailView.frame = r;
//				}
//			} else if (!_leftTailHidden && hideLeft) {
//				_leftTailHidden = YES;
//				if (animated) {
//					[UIView animateWithDuration:kToggleAnimationDuration
//										  delay:0
//										options:UIViewAnimationOptionCurveLinear
//									 animations:^(void) {
//										 CGRect r = _leftTailView.frame;
//										 r.origin.x -= kToggleTailWidth;
//										 _leftTailView.frame = r;
//									 }
//									 completion:^(BOOL finished) {}];
//				} else {
//					CGRect r = _leftTailView.frame;
//					r.origin.x -= kToggleTailWidth;
//					_leftTailView.frame = r;
//				}
//			}
//			break;
//		}
		case BAToggleBarTailStateToggle: {
			_leftTailView.hidden = hideLeft;
			_leftTailHidden = hideLeft;
			break;
		}
		case BAToggleBarTailStateHidden: {
			_leftTailView.hidden = YES;
			_leftTailHidden = YES;
			break;
		}
		case BAToggleBarTailStateVisible: {
			_leftTailView.hidden = NO;
			_leftTailHidden = NO;
			break;
		}
	}
}

- (void)updateRightTailView:(BOOL)animated {
	BOOL hideRight = (_scrollView.contentSize.width <= _scrollView.bounds.size.width ||
					  _scrollView.contentOffset.x + _scrollView.bounds.size.width >= _scrollView.contentSize.width);
	switch (self.rightTailState) {
//		case BAToggleBarTailStateToggleAnimated: {
//			_rightTailView.hidden = NO;
//			if (_rightTailHidden && !hideRight) {
//				_rightTailHidden = NO;
//				if (animated) {
//					[UIView animateWithDuration:kToggleAnimationDuration
//										  delay:0
//										options:UIViewAnimationOptionCurveLinear
//									 animations:^(void) {
//										 CGRect r = _rightTailView.frame;
//										 r.origin.x -= kToggleTailWidth;
//										 _rightTailView.frame = r;
//									 }
//									 completion:^(BOOL finished) {}];
//				} else {
//					CGRect r = _rightTailView.frame;
//					r.origin.x -= kToggleTailWidth;
//					_rightTailView.frame = r;
//				}
//			} else if (!_rightTailHidden && hideRight) {
//				_rightTailHidden = YES;
//				if (animated) {
//					[UIView animateWithDuration:kToggleAnimationDuration
//										  delay:0
//										options:UIViewAnimationOptionCurveLinear
//									 animations:^(void) {
//										 CGRect r = _rightTailView.frame;
//										 r.origin.x += kToggleTailWidth;
//										 _rightTailView.frame = r;
//									 }
//									 completion:^(BOOL finished) {}];
//				} else {
//					CGRect r = _rightTailView.frame;
//					r.origin.x += kToggleTailWidth;
//					_rightTailView.frame = r;
//				}
//			}
//			break;
//		}
		case BAToggleBarTailStateToggle: {
			_rightTailView.hidden = hideRight;
			_rightTailHidden = hideRight;
			break;
		}
		case BAToggleBarTailStateHidden: {
			_rightTailView.hidden = YES;
			_rightTailHidden = YES;
			break;
		}
		case BAToggleBarTailStateVisible: {
			_rightTailView.hidden = NO;
			_rightTailHidden = NO;
			break;
		}
	}
}

- (void)updateTailViews:(BOOL)animated {
	[self updateLeftTailView:animated];
	[self updateRightTailView:animated];
}

- (BAToggleBarTailState)leftTailState {
	return _leftTailState;
}

- (void)setLeftTailState:(BAToggleBarTailState)tailState {
	if (_leftTailState == tailState) {
		return;
	}
	_leftTailState = tailState;
	[self updateTailViews:NO];
}

- (BAToggleBarTailState)rightTailState {
	return _rightTailState;
}

- (void)setRightTailState:(BAToggleBarTailState)tailState {
	if (_rightTailState == tailState) {
		return;
	}
	_rightTailState = tailState;
	[self updateTailViews:NO];
}

- (void)updateItemsState {
	for (NSUInteger index = 0; index < [_itemViews count]; index++) {
		UIView<BAToggleItem> *itemView = [_itemViews objectAtIndex:index];
		itemView.selected = (index == _selectedItemIndex);
	}
}

- (void)layoutItemViews {
	const CGFloat width = self.bounds.size.width;
	const CGFloat height = self.bounds.size.height;
	CGFloat x = kToggleTailWidth;
	for (UIView *subview in _scrollView.subviews) {
		if ([_itemViews indexOfObject:subview] != NSNotFound) {
			// item view
			CGSize itemSize = [subview sizeThatFits:CGSizeMake(CGFLOAT_MAX / 2, height)];
			subview.frame = CGRectMake(x, 0, itemSize.width, height);
			x += itemSize.width + self.spacing;
		} else {
			// separator view
			subview.frame = CGRectMake(x, (height - subview.bounds.size.height) / 2,
									   subview.bounds.size.width, subview.bounds.size.height);
			x += subview.bounds.size.width + self.spacing;
		}
	}
	x += kToggleTailWidth - self.spacing;
	if (x < width && self.centered) {
		const CGFloat offset = roundf((width - x) / 2);
		x = width;
		for (UIView *subview in _scrollView.subviews) {
			CGRect subviewFrame = subview.frame;
			subview.frame = CGRectMake(subviewFrame.origin.x + offset, subviewFrame.origin.y,
									   subviewFrame.size.width, subviewFrame.size.height);
		}
	}
	[_scrollView setContentSize:CGSizeMake(x, height)];
	[self updateTailViews:NO];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// position scroll view in a way to prevent bounce bug
	if (!CGRectEqualToRect(self.bounds, _scrollView.frame)) {
        _scrollView.frame = self.bounds;
	}
	
	CGRect leftFrame = CGRectMake(0, 0, kToggleTailWidth, self.bounds.size.height);
//	if (_leftTailState == BAToggleBarTailStateToggleAnimated && _leftTailHidden) {
//		leftFrame.origin.x -= kToggleTailWidth;
//	}
	_leftTailView.frame = leftFrame;
	CGRect rightFrame = CGRectMake(self.bounds.size.width - kToggleTailWidth, 0,
								   kToggleTailWidth, self.bounds.size.height);
//	if (_rightTailState == BAToggleBarTailStateToggleAnimated && _rightTailHidden) {
//		rightFrame.origin.x += kToggleTailWidth;
//	}
	_rightTailView.frame = rightFrame;
	[self updateTailViews:NO];
}

- (BAToggleItemLabel *)createDefaultItemView:(id)item {
	BAToggleItemLabel *itemView = [[[BAToggleItemLabel alloc] initWithFrame:CGRectZero] autorelease];
	itemView.text = [item description];
	itemView.font = [UIFont boldSystemFontOfSize:14];
	itemView.textColor = [UIColor whiteColor];
	itemView.shadowColor = [UIColor blackColor];
	itemView.shadowOffset = CGSizeMake(0, -1);
	return itemView;
}

- (NSArray *)items {
	return [NSArray arrayWithArray:_items];
}

- (void)setItems:(NSArray *)items {
	[_items removeAllObjects];
	if (items) {
		[_items addObjectsFromArray:items];
	}

	NSArray *oldSubviews = [[NSArray alloc] initWithArray:_scrollView.subviews];
	for (UIView *subiew in oldSubviews) {
		[subiew removeFromSuperview];
	}
	[oldSubviews release];
	[_itemViews removeAllObjects];

	for (NSUInteger itemIndex = 0; itemIndex < [_items count]; itemIndex++) {
		if (itemIndex > 0 && self.delegate && [self.delegate respondsToSelector:@selector(toggleBarSeparatorView:)]) {
			UIView *separatorView = [self.delegate toggleBarSeparatorView:self];
			if (separatorView) {
				[_scrollView addSubview:separatorView];
			}
		}
		id item = [_items objectAtIndex:itemIndex];
		UIView<BAToggleItem> *itemView = nil;
		if (self.delegate && [self.delegate respondsToSelector:@selector(toggleBar:viewForItem:atIndex:)]) {
			itemView = [self.delegate toggleBar:self viewForItem:item atIndex:itemIndex];
		}
		if (!itemView) {
			itemView = [self createDefaultItemView:item];
		}
		[_scrollView addSubview:itemView];
		[_itemViews addObject:itemView];
	}
	[self updateItemsState];
	[self layoutItemViews];
}

- (NSInteger)selectedItemIndex {
	return _selectedItemIndex;
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex revealingItem:(BOOL)revealingItem {
	if (selectedItemIndex < 0 || selectedItemIndex >= [_items count]) {
		selectedItemIndex = -1;
	}
	if (_selectedItemIndex == selectedItemIndex) {
		return;
	}
	_selectedItemIndex = selectedItemIndex;
	[self updateItemsState];
	if (self.delegate) {
		id item = (selectedItemIndex < 0) ? nil : [_items objectAtIndex:_selectedItemIndex];
		[self.delegate toggleBar:self didSelectItem:item atIndex:_selectedItemIndex];
	}
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex {
	[self setSelectedItemIndex:selectedItemIndex revealingItem:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	if (self.leftTailState != BAToggleBarTailStateToggleAnimated) {
//		[self updateLeftTailView:YES];
//	}
//	if (self.rightTailState != BAToggleBarTailStateToggleAnimated) {
//		[self updateRightTailView:YES];
//	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//	if (self.leftTailState == BAToggleBarTailStateToggleAnimated) {
//		[self updateLeftTailView:YES];
//	}
//	if (self.rightTailState == BAToggleBarTailStateToggleAnimated) {
//		[self updateRightTailView:YES];
//	}
}

@end
