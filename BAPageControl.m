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

#import "BAPageControl.h"

#define kUnitSize 6
#define kUnitSpacing 10
#define kPillLineWidth 2
#define kPillSpacing 1
#define kInactiveAlpha 0.3

@implementation BAPageControl

@synthesize defersCurrentPageDisplay = _defersCurrentPageDisplay;
@synthesize activeColor = _activeColor;
@synthesize inactiveColor = _inactiveColor;

- (void)setupView {
	self.opaque = NO;
	self.contentMode = UIViewContentModeRedraw;
	self.backgroundColor = [UIColor clearColor];
	self.primaryMode = BAPageControlModeDots;
	self.fitMode = BAPageControlModeProgress;
	self.alignment = BAPageControlAlignmentCenter;
	self.inset = kPillLineWidth + kPillSpacing + kUnitSize / 2; // make sure that we fit for any mode by default
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

- (void)addPillPathAroundRect:(CGRect)r toContext:(CGContextRef)ctx {
	if (r.size.width == 0) {
		return;
	}
	const CGFloat d = r.size.height / 2;
	CGContextMoveToPoint(ctx, r.origin.x, r.origin.y + r.size.height);
	CGContextAddArc(ctx, r.origin.x, r.origin.y + d, d, M_PI_2, -M_PI_2, 0);
	CGContextAddLineToPoint(ctx, r.origin.x + r.size.width, r.origin.y);
	CGContextAddArc(ctx, r.origin.x + r.size.width, r.origin.y + d, d, -M_PI_2, M_PI_2, 0);
	CGContextAddLineToPoint(ctx, r.origin.x, r.origin.y + r.size.height);
}

- (void)drawRect:(CGRect)rect {
	if (_numberOfPages == 0 || (_numberOfPages == 1 && _hidesForSinglePage)) {
		return;
	}
	UIColor *activeColor = self.activeColor ? self.activeColor : [UIColor whiteColor];
	UIColor *inactiveColor = self.inactiveColor ? self.inactiveColor : [activeColor colorWithAlphaComponent:kInactiveAlpha];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	const BAPageControlMode mode = self.displayMode;
	if (mode == BAPageControlModeDots || mode == BAPageControlModeBlocks) {
		CGSize size = [self sizeForNumberOfPages:_numberOfPages];
		CGFloat left;
		switch (self.alignment) {
			case BAPageControlAlignmentLeft:
				left = 0;
				break;
			case BAPageControlAlignmentCenter:
				left = (self.bounds.size.width - size.width) / 2;
				break;
			case BAPageControlAlignmentRight:
				left = (self.bounds.size.width - size.width);
				break;
		}
		const CGFloat top = (self.bounds.size.height - size.height) / 2;
		for (NSInteger page = 0; page < _numberOfPages; page++) {
			(page == _displayedPage) ? [activeColor set] : [inactiveColor set];
			if (mode == BAPageControlModeDots) {
				CGContextAddEllipseInRect(ctx, CGRectMake(left + page * (kUnitSize + kUnitSpacing), top, kUnitSize, kUnitSize));
			} else if (mode == BAPageControlModeBlocks) {
				CGContextAddRect(ctx, CGRectMake(left + page * (kUnitSize + kUnitSpacing), top, kUnitSize, kUnitSize));
			}
			CGContextFillPath(ctx);
		}
	} else if (mode == BAPageControlModeProgress ||
			   mode == BAPageControlModeBlock ||
			   mode == BAPageControlModePill)
	{
		CGRect r = self.bounds;
		r.origin.x += self.inset;
		r.size.width -= self.inset * 2;
		r.origin.y = (r.size.height - kUnitSize) / 2;
		r.size.height = kUnitSize;
		float progress = (_numberOfPages > 1) ? (float)_displayedPage / (float)(_numberOfPages - 1) : 0;
		if (mode == BAPageControlModeProgress) {
			[inactiveColor set];
			[self addPillPathAroundRect:r toContext:ctx];
			CGContextFillPath(ctx);
			r.size.width *= progress;
			[activeColor set];
			[self addPillPathAroundRect:r toContext:ctx];
			CGContextFillPath(ctx);
		} else if (mode == BAPageControlModeBlock) {
			[inactiveColor set];
			CGContextAddRect(ctx, r);
			CGContextFillPath(ctx);
			r.size.width *= progress;
			[activeColor set];
			CGContextAddRect(ctx, r);
			CGContextFillPath(ctx);
		} else if (mode == BAPageControlModePill) {
			[activeColor set];
			CGRect b = CGRectInset(r, -kPillSpacing / 2, -(kPillLineWidth + kPillSpacing));
			[self addPillPathAroundRect:b toContext:ctx];
			CGContextSetLineWidth(ctx, kPillLineWidth);
			CGContextStrokePath(ctx);
			r.size.width *= progress;
			[self addPillPathAroundRect:r toContext:ctx];
			CGContextFillPath(ctx);
		}
	}
}

- (void)updateCurrentPageDisplay {
	if (_displayedPage != _currentPage) {
		_displayedPage = _currentPage;
		[self setNeedsDisplay];
	}
}

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount {
	if (pageCount == 0 || (pageCount == 1 && _hidesForSinglePage)) {
		return CGSizeZero;
	}
	return CGSizeMake((kUnitSize + kUnitSpacing) * pageCount - kUnitSpacing, kUnitSize);
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
	if (_currentPage >= _numberOfPages) {
		_currentPage = _numberOfPages - 1;
	}
	if (_currentPage < 0) {
		_currentPage = 0;
	}
	if (_displayedPage >= _numberOfPages) {
		_displayedPage = _numberOfPages - 1;
	}
	if (_displayedPage < 0) {
		_displayedPage = 0;
	}
	[self setNeedsDisplay];
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
	_displayedPage = currentPage;
	[self setNeedsDisplay];
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

- (BAPageControlMode)primaryMode {
	return _primaryMode;
}

- (void)setPrimaryMode:(BAPageControlMode)mode {
	if (_primaryMode != mode) {
		_primaryMode = mode;
		[self setNeedsDisplay];
	}
}

- (BAPageControlMode)fitMode {
	return _fitMode;
}

- (void)setFitMode:(BAPageControlMode)mode {
	if (_fitMode != mode) {
		_fitMode = mode;
		[self setNeedsDisplay];
	}
}

- (BAPageControlMode)displayMode {
	if (self.primaryMode == BAPageControlModeDots || self.primaryMode == BAPageControlModeBlocks) {
		CGSize size = [self sizeForNumberOfPages:_numberOfPages];
		if (kUnitSpacing + size.width + kUnitSpacing > self.bounds.size.width) {
			return self.fitMode;
		}
	}
	return self.primaryMode;
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_numberOfPages == 0 || (_numberOfPages == 1 && _hidesForSinglePage)) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	BOOL updated = NO;
	CGFloat displayedX = self.bounds.size.width / 2;
	
	const BAPageControlMode mode = self.displayMode;
	if (mode == BAPageControlModeDots || mode == BAPageControlModeBlocks) {
		CGSize size = [self sizeForNumberOfPages:_numberOfPages];
		CGFloat left;
		switch (self.alignment) {
			case BAPageControlAlignmentLeft:
				left = 0;
				break;
			case BAPageControlAlignmentCenter:
				left = (self.bounds.size.width - size.width) / 2;
				break;
			case BAPageControlAlignmentRight:
				left = (self.bounds.size.width - size.width);
				break;
		}
		displayedX = left + (kUnitSize + kUnitSpacing) * _displayedPage + kUnitSize / 2;
	} else if (mode == BAPageControlModeProgress ||
			   mode == BAPageControlModeBlock ||
			   mode == BAPageControlModePill)
	{
		CGRect r = self.bounds;
		r.origin.x += self.inset;
		r.size.width -= self.inset * 2;
		float progress = (_numberOfPages > 1) ? (float)_displayedPage / (float)(_numberOfPages - 1) : 0;
		displayedX = r.origin.x + progress * r.size.width;
	}
	
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
