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

#define kDefaultPadding 10

@implementation BAToggleItemLabel

@synthesize selectedBackgroundColor = _selectedBackgroundColor;
@synthesize selectedTextColor = _selectedTextColor;
@synthesize insets = _insets;
@synthesize padding = _padding;

- (void)dealloc {
	[_selectedBackgroundColor release];
	[_selectedTextColor release];
	[_normalTextColor release];
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_selectedTextColor = [[UIColor colorWithWhite:0.9 alpha:1.0] retain];
		_selectedBackgroundColor = [[UIColor colorWithWhite:0.0 alpha:0.3] retain];
		self.insets = UIEdgeInsetsMake(kDefaultPadding / 2, kDefaultPadding, kDefaultPadding / 2, kDefaultPadding);
		self.padding = kDefaultPadding;
		self.textAlignment = UITextAlignmentCenter;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	size.width -= (self.insets.left + self.insets.right);
	size.height -= (self.insets.top + self.insets.bottom);
	size = [super sizeThatFits:size];
	size.width += (self.insets.left + self.insets.right);
	size.height += (self.insets.top + self.insets.bottom);
	return size;
}

- (void)drawRect:(CGRect)rect {
	if (self.selected && self.selectedBackgroundColor) {
		CGSize textSize = UIEdgeInsetsInsetRect(self.bounds, self.insets).size;
		textSize = [self.text sizeWithFont:self.font
						 constrainedToSize:textSize
							 lineBreakMode:self.lineBreakMode];
		[self.selectedBackgroundColor set];
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGRect plateRect = CGRectMake((self.bounds.size.width - textSize.width) / 2,
									  (self.bounds.size.height - textSize.height) / 2,
									  textSize.width, textSize.height);
		plateRect = UIEdgeInsetsInsetRect(plateRect, UIEdgeInsetsMake(-self.padding / 2, -self.padding,
																	  -self.padding / 2, -self.padding));
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:plateRect
														cornerRadius:(plateRect.size.height / 2)];
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
