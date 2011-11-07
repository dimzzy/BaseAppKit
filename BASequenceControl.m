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

#import "BASequenceControl.h"

@interface BASequenceControl()

@property(nonatomic, readonly) NSMutableArray *segments;

@end


@implementation BASequenceControl {
@private
    NSMutableArray *_segments;
    NSInteger _selectedSegmentIndex;
}

@synthesize activeSegmentImage = _activeSegmentImage, passiveSegmentImage = _passiveSegmentImage;
@synthesize leftMargin = _leftMargin, rightMargin = _rightMargin, overlapWidth = _overlapWidth;
@synthesize titleFont = _titleFont, activeTitleColor = _activeTitleColor, passiveTitleColor = _passiveTitleColor;

- (void)dealloc {
	[_segments release];
	[_activeSegmentImage release];
	[_passiveSegmentImage release];
	[_titleFont release];
	[_activeTitleColor release];
	[_passiveTitleColor release];
	[super dealloc];
}

- (void)awakeFromNib {
	_selectedSegmentIndex = -1;
	[super awakeFromNib];
}

- (id)init {
	if ((self = [super init])) {
		_selectedSegmentIndex = -1;
	}
	return self;
}

- (NSMutableArray *)segments {
	if (!_segments) {
		_segments = [[NSMutableArray alloc] init];
	}
	return _segments;
}

- (NSUInteger)numberOfSegments {
	return [self.segments count];
}

- (NSInteger)selectedSegmentIndex {
	return _selectedSegmentIndex;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
	if (selectedSegmentIndex >= [self.segments count]) {
		selectedSegmentIndex = -1;
	} else if (selectedSegmentIndex < -1) {
		selectedSegmentIndex = -1;
	}
	if (_selectedSegmentIndex == selectedSegmentIndex) {
		return;
	}
	_selectedSegmentIndex = selectedSegmentIndex;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)segmentsDidChange {
	[self setNeedsDisplay];
}

- (void)addSegmentWithTitle:(NSString *)title animated:(BOOL)animated {
	if (!title) {
		title = @"";
	}
	[self.segments addObject:title];
	[self segmentsDidChange];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated {
	if (!title) {
		title = @"";
	}
	[self.segments insertObject:title atIndex:segment];
	[self segmentsDidChange];
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated {
	[self.segments removeObjectAtIndex:segment];
	[self segmentsDidChange];
}

- (void)removeAllSegments {
	[self.segments removeAllObjects];
	[self segmentsDidChange];
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment {
	if (!title) {
		title = @"";
	}
	[self.segments replaceObjectAtIndex:segment withObject:title];
	[self segmentsDidChange];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment {
	return [self.segments objectAtIndex:segment];
}

- (void)drawRect:(CGRect)rect {
	UIImage *activeSegmentImage = self.activeSegmentImage;
	if (!activeSegmentImage) {
		activeSegmentImage = [[UIImage imageNamed:@"ba-sequence-item-active.png"] stretchableImageWithLeftCapWidth:20
																									  topCapHeight:22];
	}
	UIImage *passiveSegmentImage = self.passiveSegmentImage;
	if (!passiveSegmentImage) {
		passiveSegmentImage = [[UIImage imageNamed:@"ba-sequence-item-passive.png"] stretchableImageWithLeftCapWidth:20
																										topCapHeight:22];
	}
	UIFont *titleFont = self.titleFont;
	if (!titleFont) {
		titleFont = [UIFont boldSystemFontOfSize:18];
	}
	UIColor *activeTitleColor = self.activeTitleColor;
	if (!activeTitleColor) {
		activeTitleColor = [UIColor whiteColor];
	}
	UIColor *passiveTitleColor = self.passiveTitleColor;
	if (!passiveTitleColor) {
		passiveTitleColor = [UIColor grayColor];
	}
	const CGFloat w = self.bounds.size.width;
	const CGFloat h = self.bounds.size.height;
	const CGFloat p = self.overlapWidth;
	
	[passiveSegmentImage drawInRect:CGRectMake(-passiveSegmentImage.size.width, 0,
											   w + 2 * passiveSegmentImage.size.width, h)];
	if (self.numberOfSegments > 0) {
		const CGFloat sw = rint((w - self.leftMargin - self.rightMargin - p) / self.numberOfSegments);
		if (sw > 0) {
			CGFloat right = w - self.rightMargin;
			for (NSInteger segment = (self.numberOfSegments - 1); segment >= 0; segment--) {
				UIImage *image = nil;
				if (self.selectedSegmentIndex == segment) {
					image = activeSegmentImage;
					[activeTitleColor set];
				} else {
					image = passiveSegmentImage;
					[passiveTitleColor set];
				}
				[image drawInRect:CGRectMake(right - sw - p, 0, p + sw, h)];
				NSString *title = [self titleForSegmentAtIndex:segment];
				const CGSize titleSize = [title sizeWithFont:titleFont];
				const CGFloat titleWidth = MIN(sw - p, titleSize.width);
				CGRect titleFrame = CGRectMake(rint(right - sw + (sw - p - titleWidth) / 2),
											   rint((h - titleSize.height) / 2),
											   titleWidth, titleSize.height);
				//UIRectFrame(titleFrame);
				[title drawAtPoint:titleFrame.origin
						  forWidth:titleFrame.size.width
						  withFont:titleFont
					 lineBreakMode:UILineBreakModeTailTruncation];
				right -= sw;
			}
			[passiveSegmentImage drawInRect:CGRectMake(-p, 0, p + self.leftMargin + p, h)];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	if (self.numberOfSegments > 0) {
		const CGFloat w = self.bounds.size.width;
		const CGFloat p = self.overlapWidth;
		const CGFloat sw = rint((w - self.leftMargin - self.rightMargin - p) / self.numberOfSegments);
		if (sw > 0) {
			UITouch *touch = [touches anyObject];
			const CGFloat x = [touch locationInView:self].x;
			if (x >= self.leftMargin && x <= (w - self.rightMargin)) {
				NSInteger segment = (x - self.leftMargin - p / 2) / sw;
				if (segment >= self.numberOfSegments) {
					segment = self.numberOfSegments - 1;
				} else if (segment < 0) {
					segment = 0;
				}
				self.selectedSegmentIndex = segment;
			}
		}
	}
}

@end
