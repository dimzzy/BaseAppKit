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

#import "BACustomPageControl.h"

#define kUnitSpacing 10

@implementation BACustomPageControl {
@private
	NSInteger _numberOfPages;
	NSInteger _currentPage;
	NSInteger _displayedPage;
	BOOL _hidesForSinglePage;
	BAPageControlAlignment _alignment;
	CGFloat _inset;
}

@synthesize defersCurrentPageDisplay = _defersCurrentPageDisplay;
@synthesize activeImage = _activeImage;
@synthesize inactiveImage = _inactiveImage;

- (void)setupView {
	self.opaque = NO;
	self.contentMode = UIViewContentModeRedraw;
	self.backgroundColor = [UIColor clearColor];
	self.alignment = BAPageControlAlignmentCenter;
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
	[_activeImage release];
	[_inactiveImage release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
	if (_numberOfPages == 0 || (_numberOfPages == 1 && _hidesForSinglePage)) {
		return;
	}
	CGSize size = [self sizeForNumberOfPages:_numberOfPages];
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
	const CGFloat top = rint((self.bounds.size.height - size.height) / 2);
	const CGFloat imageWidth = (size.width - kUnitSpacing * (_numberOfPages - 1)) / _numberOfPages;
	for (NSInteger page = 0; page < _numberOfPages; page++) {
		UIImage *image = (page == _displayedPage) ? self.activeImage : self.inactiveImage;
		if (image) {
			[image drawAtPoint:CGPointMake(rint(left + page * (imageWidth + kUnitSpacing)), top)];
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
	CGSize size = CGSizeMake(0, 0);
	if (self.activeImage) {
		size.width = self.activeImage.size.width;
		size.height = self.activeImage.size.height;
	}
	if (self.inactiveImage && _numberOfPages > 1) {
		size.width += self.inactiveImage.size.width * (_numberOfPages - 1);
		size.height = MAX(size.height, self.inactiveImage.size.height);
	}
	if (_numberOfPages > 1) {
		size.width += kUnitSpacing * (_numberOfPages - 1);
	}
	return size;
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
	CGSize size = [self sizeForNumberOfPages:_numberOfPages];
	const CGFloat imageWidth = (size.width - kUnitSpacing * (_numberOfPages - 1)) / _numberOfPages;
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
	displayedX = left + (imageWidth + kUnitSpacing) * _displayedPage + imageWidth / 2;
	
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
