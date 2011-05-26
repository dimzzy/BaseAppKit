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
#import "BAToggleItemLabel.h"

@implementation BAToggleItemLabel

@synthesize selectedBackgroundColor = _selectedBackgroundColor;
@synthesize selectedTextColor = _selectedTextColor;

- (void)dealloc {
	[_selectedBackgroundColor release];
	[_selectedTextColor release];
	[_normalTextColor release];
	[super dealloc];
}

- (void)drawRect:(CGRect)rect {
	if (self.selected && self.selectedBackgroundColor) {
		[self.selectedBackgroundColor set];
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
														cornerRadius:(self.bounds.size.height / 2)];
		CGContextAddPath(ctx, path.CGPath);
		CGContextFillPath(ctx);
	}
	[super drawRect:self.bounds];
}

- (BOOL)selected {
	return _selected;
}

- (void)setSelected:(BOOL)selected {
	if (_selected == selected) {
		return;
	}
	_selected = selected;
	if (_selected) {
		[_normalTextColor release];
		_normalTextColor = [self.textColor retain];
		self.textColor = _selectedTextColor;
	} else {
		self.textColor = _normalTextColor;
	}
	[self setNeedsDisplay];
}

@end
