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

#import "BALabel.h"

@implementation BALabel

- (UIEdgeInsets)textInsets {
	return _textInsets;
}

- (void)setTextInsets:(UIEdgeInsets)textInsets {
	if (UIEdgeInsetsEqualToEdgeInsets(_textInsets, textInsets)) {
		return;
	}
	_textInsets = textInsets;
	[self setNeedsDisplay];
}

- (BAVerticalAlignment)verticalAlignment {
	return _verticalAlignment;
}

- (void)setVerticalAlignment:(BAVerticalAlignment)verticalAlignment {
	if (_verticalAlignment == verticalAlignment) {
		return;
	}
	_verticalAlignment = verticalAlignment;
	[self setNeedsDisplay];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
	CGRect r = bounds;
	const CGFloat wd = self.textInsets.left + self.textInsets.right;
	const CGFloat hd = self.textInsets.top + self.textInsets.bottom;
	r.size.width -= wd;
	r.size.height -= hd;
	r = [super textRectForBounds:r limitedToNumberOfLines:numberOfLines];
	r.size.width += wd;
	r.size.height += hd;
	return r;
}

- (void)drawTextInRect:(CGRect)rect {
	CGRect tr = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
	const CGFloat hd = self.bounds.size.height - tr.size.height;
	if (self.verticalAlignment == BAVerticalAlignmentCenter) {
		tr.origin.y += rint(hd / 2);
	} else if (self.verticalAlignment == BAVerticalAlignmentBottom) {
		tr.origin.y += rint(hd);
	}
	tr = UIEdgeInsetsInsetRect(tr, self.textInsets);
	[super drawTextInRect:tr];
}

@end
