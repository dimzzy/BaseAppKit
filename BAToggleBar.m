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

#define kToggleItemHMargin 8
#define kToggleItemVMargin 3
#define kToggleBarSpacing 4
#define kToggleTailWidth 30


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
@synthesize itemViews = _itemViews;
@synthesize itemTextColor = _itemTextColor;
@synthesize selectedItemTextColor = _selectedItemTextColor;
@synthesize selectedItemBackgroundColor = _selectedItemBackgroundColor;
@synthesize delegate = _delegate;

- (void)setupView {
	_scrollView = [[BAToggleScrollView alloc] initWithFrame:CGRectZero];
	_scrollView.scrollsToTop = NO;
	_scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	_scrollView.delegate = self;
	[self addSubview:_scrollView];
	_leftTailView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"togglebar-left.png"]];
	_leftTailView.userInteractionEnabled = NO;
	_leftTailView.opaque = NO;
	[self addSubview:_leftTailView];
	_rightTailView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"togglebar-right.png"]];
	_rightTailView.userInteractionEnabled = NO;
	_rightTailView.opaque = NO;
	_rightTailView.backgroundColor = [UIColor clearColor];
	[self addSubview:_rightTailView];

	_itemViews = [[NSMutableArray alloc] init];
	_items = [[NSMutableArray alloc] init];
	_itemTextColor = [[UIColor whiteColor] retain];
	_selectedItemTextColor = [[UIColor colorWithWhite:0.9 alpha:1.0] retain];
	_selectedItemBackgroundColor = [[UIColor colorWithWhite:0.0 alpha:0.3] retain];
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
	[_itemTextColor release];
	[_selectedItemTextColor release];
	[_selectedItemBackgroundColor release];
    [super dealloc];
}

- (void)updateTailViews {
	_leftTailView.hidden = (_scrollView.contentSize.width <= _scrollView.bounds.size.width ||
							_scrollView.contentOffset.x == 0);
	_rightTailView.hidden = (_scrollView.contentSize.width <= _scrollView.bounds.size.width ||
							 _scrollView.contentOffset.x + _scrollView.bounds.size.width == _scrollView.contentSize.width);
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
	const CGFloat maxItemHeight = height - kToggleItemVMargin * 2;
	CGFloat x = kToggleBarSpacing;
	for (UIView *subview in _scrollView.subviews) {
		if ([_itemViews indexOfObject:subview] != NSNotFound) {
			// item view
			CGSize itemSize = [subview sizeThatFits:CGSizeMake(CGFLOAT_MAX / 2, maxItemHeight)];
			itemSize.height = MIN(itemSize.height, maxItemHeight);
			itemSize.width += kToggleItemHMargin * 2;
			itemSize.height += kToggleItemVMargin * 2;
			CGFloat y = roundf((height - itemSize.height) / 2);
			subview.frame = CGRectMake(x, y, itemSize.width, itemSize.height);
			x += itemSize.width + kToggleBarSpacing;
		} else {
			// separator view
			subview.frame = CGRectMake(x, (height - subview.bounds.size.height) / 2,
									   subview.bounds.size.width, subview.bounds.size.height);
			x += subview.bounds.size.width + kToggleBarSpacing;
		}
	}
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
	[self updateTailViews];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	_scrollView.frame = self.bounds;
	_leftTailView.frame = CGRectMake(0, 0,
									 kToggleTailWidth, self.bounds.size.height);
	_rightTailView.frame = CGRectMake(self.bounds.size.width - kToggleTailWidth, 0,
									  kToggleTailWidth, self.bounds.size.height);
	[self updateTailViews];
}

- (BAToggleItemLabel *)createDefaultItemView:(NSString *)text {
	BAToggleItemLabel *itemView = [[[BAToggleItemLabel alloc] initWithFrame:CGRectZero] autorelease];
	itemView.text = text;
	itemView.font = [UIFont boldSystemFontOfSize:14];
	itemView.textAlignment = UITextAlignmentCenter;
	itemView.textColor = self.itemTextColor;
	itemView.shadowColor = [UIColor blackColor];
	itemView.shadowOffset = CGSizeMake(0, -1);
	itemView.selectedTextColor = self.selectedItemTextColor;
	itemView.backgroundColor = [UIColor clearColor];
	itemView.selectedBackgroundColor = self.selectedItemBackgroundColor;
	itemView.opaque = NO;
	itemView.userInteractionEnabled = YES;
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
		NSString *item = [_items objectAtIndex:itemIndex];
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
		NSString *item = (selectedItemIndex < 0) ? nil : [_items objectAtIndex:_selectedItemIndex];
		[self.delegate toggleBar:self didSelectItem:item atIndex:_selectedItemIndex];
	}
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex {
	[self setSelectedItemIndex:selectedItemIndex revealingItem:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self updateTailViews];
}

@end
