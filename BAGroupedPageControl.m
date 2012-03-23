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

#import "BAGroupedPageControl.h"

#define kUnitSize 6.0
#define kArrowWidth 10.0
#define kArrowHeight 10.0
#define kArrowTrunkHeight 4.0
#define kUnitSpacing 10.0
#define kInactiveAlpha 0.3
#define kControlHeight MAX(kArrowHeight, kUnitSize)

@interface BAGroupedPageControl()

@property(nonatomic, readonly) NSUInteger numberOfGroups;
@property(nonatomic, readonly) NSUInteger displayedGroup;

- (NSUInteger)pagesInGroup:(NSUInteger)group;

@end


@implementation BAGroupedPageControl {
@private
	NSInteger _numberOfPages;
	NSInteger _currentPage;
	NSInteger _displayedPage;
	BOOL _hidesForSinglePage;
	BAGroupedPageControlMode _primaryMode;
	BAPageControlAlignment _alignment;
	CGFloat _inset;
	NSUInteger _pagesPerGroup;
}

@synthesize defersCurrentPageDisplay = _defersCurrentPageDisplay;
@synthesize activeColor = _activeColor;
@synthesize inactiveColor = _inactiveColor;

- (void)setupView {
	self.contentMode = UIViewContentModeRedraw;
	self.primaryMode = BAGroupedPageControlModeDots;
	self.alignment = BAPageControlAlignmentCenter;
	//self.inset = 6;
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
	[_activeColor release];
	[_inactiveColor release];
    [super dealloc];
}

- (CGSize)sizeForDisplayedGroup {
	if (self.numberOfGroups > 1) {
		CGSize size = [self sizeForNumberOfPages:[self pagesInGroup:self.displayedGroup]];
		size.width += (kArrowWidth + kUnitSpacing) * 2;
		return size;
	} else {
		return [self sizeForNumberOfPages:self.numberOfPages];
	}
}

- (void)updateCurrentPageDisplay {
	if (_displayedPage != _currentPage) {
		_displayedPage = _currentPage;
//		NSLog(@"display %d [%d/%d/%d]",
//			  _displayedPage, self.displayedGroup, [self pagesInGroup:self.displayedGroup], self.numberOfGroups);
		[self setNeedsDisplay];
	}
}

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount {
	if (pageCount == 0 || (pageCount == 1 && _hidesForSinglePage)) {
		return CGSizeZero;
	}
	return CGSizeMake((kUnitSize + kUnitSpacing) * pageCount - kUnitSpacing, kControlHeight);
}

- (NSInteger)numberOfPages {
	return _numberOfPages;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
	if (numberOfPages < 0) {
		numberOfPages = 0;
	}
	if (_numberOfPages == numberOfPages) {
		return;
	}
	_numberOfPages = numberOfPages;
	[self setNeedsDisplay];
	if (_currentPage >= _numberOfPages) {
		_currentPage = _numberOfPages - 1;
	}
	if (_currentPage < 0) {
		_currentPage = 0;
	}
	[self updateCurrentPageDisplay];
}

- (NSInteger)currentPage {
	return _currentPage;
}

- (void)setCurrentPage:(NSInteger)currentPage {
	if (currentPage >= _numberOfPages) {
		currentPage = _numberOfPages - 1;
	}
	if (currentPage < 0) {
		currentPage = 0;
	}
	if (_currentPage == currentPage) {
		return;
	}
	_currentPage = currentPage;
	[self updateCurrentPageDisplay];
}

- (BOOL)hidesForSinglePage {
	return _hidesForSinglePage;
}

- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage {
	if (_hidesForSinglePage != hidesForSinglePage) {
		return;
	}
	_hidesForSinglePage = hidesForSinglePage;
	[self setNeedsDisplay];
}

- (BAGroupedPageControlMode)primaryMode {
	return _primaryMode;
}

- (void)setPrimaryMode:(BAGroupedPageControlMode)mode {
	if (_primaryMode != mode) {
		_primaryMode = mode;
		[self setNeedsDisplay];
	}
}

- (BAPageControlAlignment)alignment {
	return _alignment;
}

- (void)setAlignment:(BAPageControlAlignment)alignment {
	if (_alignment == alignment) {
		return;
	}
	_alignment = alignment;
	[self setNeedsDisplay];
}

- (CGFloat)inset {
	return _inset;
}

- (void)setInset:(CGFloat)inset {
	if (_inset != inset) {
		_inset = inset;
		[self setNeedsDisplay];
	}
}

- (NSUInteger)pagesPerGroup {
	return _pagesPerGroup;
}

- (void)setPagesPerGroup:(NSUInteger)pagesPerGroup {
	if (_pagesPerGroup == pagesPerGroup) {
		return;
	}
	_pagesPerGroup = pagesPerGroup;
	[self setNeedsDisplay];
}

- (NSUInteger)numberOfGroups {
	if (self.pagesPerGroup == 0) {
		return 0;
	}
	return self.numberOfPages / self.pagesPerGroup + ((self.numberOfPages % self.pagesPerGroup > 0) ? 1 : 0);
}

- (NSUInteger)displayedGroup {
	if (self.pagesPerGroup == 0) {
		return 0;
	}
	return _displayedPage / self.pagesPerGroup;
}

- (NSUInteger)pagesInGroup:(NSUInteger)group {
	if (group >= self.numberOfGroups) {
		return 0;
	}
	if (group == self.numberOfGroups - 1) {
		const NSUInteger count = self.numberOfPages % self.pagesPerGroup;
		return count ? count : self.pagesPerGroup;
	} else {
		return self.pagesPerGroup;
	}
}

- (void)drawArrowAtLocation:(CGPoint)p {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	const CGFloat arrowWing = (kArrowHeight - kArrowTrunkHeight) / 2;
	CGContextMoveToPoint(ctx, p.x, p.y + (CGFloat)kArrowHeight / 2);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth / 2, p.y);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth / 2, p.y + arrowWing);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth, p.y + arrowWing);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth, p.y + kArrowHeight - arrowWing);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth / 2, p.y + kArrowHeight - arrowWing);
	CGContextAddLineToPoint(ctx, p.x + (CGFloat)kArrowWidth / 2, p.y + kArrowHeight);
	CGContextClosePath(ctx);
	CGContextFillPath(ctx);
}

- (void)drawRect:(CGRect)rect {
	if (_numberOfPages == 0 || (_numberOfPages == 1 && _hidesForSinglePage)) {
		return;
	}
	UIColor *activeColor = self.activeColor ? self.activeColor : [UIColor whiteColor];
	UIColor *inactiveColor = self.inactiveColor ? self.inactiveColor : [activeColor colorWithAlphaComponent:kInactiveAlpha];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGSize size = [self sizeForDisplayedGroup];
	CGFloat left;
	switch (self.alignment) {
		case BAPageControlAlignmentLeft:
			left = self.inset;
			break;
		case BAPageControlAlignmentCenter:
			left = (self.bounds.size.width - size.width) / 2;
			break;
		case BAPageControlAlignmentRight:
			left = (self.bounds.size.width - size.width - self.inset);
			break;
	}
	const BAGroupedPageControlMode mode = self.primaryMode;
	const CGFloat arrowTop = (self.bounds.size.height - kArrowHeight) / 2;
	const CGFloat unitTop = (self.bounds.size.height - kUnitSize) / 2;
	NSUInteger pageCount;
	NSUInteger pageOffset;
	if (self.numberOfGroups > 1) {
		if (self.displayedGroup > 0) {
			[inactiveColor set];
			[self drawArrowAtLocation:CGPointMake(left, arrowTop)];
		}
		left += kArrowWidth + kUnitSpacing;
		pageCount = [self pagesInGroup:self.displayedGroup];
		pageOffset = self.pagesPerGroup * self.displayedGroup;
	} else {
		pageCount = self.numberOfPages;
		pageOffset = 0;
	}
	for (NSInteger relativePage = 0; relativePage < pageCount; relativePage++) {
		NSInteger page = pageOffset + relativePage;
		(page == _displayedPage) ? [activeColor set] : [inactiveColor set];
		if (mode == BAGroupedPageControlModeDots) {
			CGContextAddEllipseInRect(ctx, CGRectMake(left + relativePage * (kUnitSize + kUnitSpacing), unitTop,
													  kUnitSize, kUnitSize));
		} else if (mode == BAGroupedPageControlModeBlocks) {
			CGContextAddRect(ctx, CGRectMake(left + relativePage * (kUnitSize + kUnitSpacing), unitTop,
											 kUnitSize, kUnitSize));
		}
		CGContextFillPath(ctx);
	}
	if (self.numberOfGroups > 1 && (self.displayedGroup < self.numberOfGroups - 1)) {
		left += (kUnitSize + kUnitSpacing) * pageCount + kUnitSpacing;
		[inactiveColor set];
		CGContextTranslateCTM(ctx, left * 2, 0);
		CGContextScaleCTM(ctx, -1, 1);
		[self drawArrowAtLocation:CGPointMake(left, arrowTop)];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_numberOfPages == 0 || (_numberOfPages == 1 && _hidesForSinglePage)) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	BOOL updated = NO;
	
	CGSize size = [self sizeForDisplayedGroup];
	CGFloat left;
	switch (self.alignment) {
		case BAPageControlAlignmentLeft:
			left = self.inset;
			break;
		case BAPageControlAlignmentCenter:
			left = (self.bounds.size.width - size.width) / 2;
			break;
		case BAPageControlAlignmentRight:
			left = (self.bounds.size.width - size.width - self.inset);
			break;
	}
	NSInteger relativePage;
	if (self.numberOfGroups > 1) {
		left += kArrowWidth + kUnitSpacing;
		relativePage = _displayedPage - self.pagesPerGroup * self.displayedGroup;
	} else {
		relativePage = _displayedPage;
	}
	CGFloat displayedX = left + (kUnitSize + kUnitSpacing) * relativePage + kUnitSize / 2;
	
	if (location.x < displayedX && _displayedPage > 0) {
		_currentPage = _displayedPage - 1;
		updated = YES;
	}
	if (location.x > displayedX && _displayedPage < (_numberOfPages - 1)) {
		_currentPage = _displayedPage + 1;
		updated = YES;
	}
	if (updated) {
		if (!_defersCurrentPageDisplay) {
			[self updateCurrentPageDisplay];
		}
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
	[super touchesEnded:touches withEvent:event];
}

@end
