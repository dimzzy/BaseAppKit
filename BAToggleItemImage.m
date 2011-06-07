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

#import <QuartzCore/QuartzCore.h>
#import "BAToggleItemImage.h"

@implementation BAToggleItemImage

@synthesize image = _image;
@synthesize imagePadding = _imagePadding;
@synthesize selectedBackgroundColor = _selectedBackgroundColor;
@synthesize selectedOutlineColor = _selectedOutlineColor;

- (void)dealloc {
	[_image release];
	[_selectedBackgroundColor release];
	[_selectedOutlineColor release];
	[super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize viewSize;
	viewSize.width = viewSize.height = 0;
	if (self.image) {
		viewSize = self.image.size;
	}
	return CGSizeMake(viewSize.width + self.imagePadding, viewSize.height + self.imagePadding);
}

- (void)drawRect:(CGRect)rect {
	if (self.selected) {
		if (self.selectedBackgroundColor) {
			[self.selectedBackgroundColor set];
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5)
															cornerRadius:5];
			CGContextAddPath(ctx, path.CGPath);
			CGContextFillPath(ctx);
		}
		if (self.selectedOutlineColor) {
			[self.selectedOutlineColor set];
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			CGContextSetLineWidth(ctx, 1);
			UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5)
															cornerRadius:8];
			CGContextAddPath(ctx, path.CGPath);
			CGContextStrokePath(ctx);
		}
	}
	if (self.image) {
		CGSize viewSize = self.bounds.size;
		CGSize imageSize = self.image.size;
		[self.image drawAtPoint:CGPointMake((viewSize.width - imageSize.width) / 2,
											(viewSize.height - imageSize.height) / 2)];
	}
}

- (BOOL)selected {
	return _selected;
}

- (void)setSelected:(BOOL)selected {
	if (_selected == selected) {
		return;
	}
	_selected = selected;
	[self setNeedsDisplay];
}

@end
