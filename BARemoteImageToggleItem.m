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
#import "BARemoteImageToggleItem.h"

@implementation BARemoteImageToggleItem

@synthesize imageView = _imageView;
@synthesize imageInsets = _imageInsets;
@synthesize selectedOutlineColor = _selectedOutlineColor;

- (void)dealloc {
	[_imageView release];
	[_selectedOutlineColor release];
	[super dealloc];
}

- (id)init {
	if ((self = [super init])) {
		_imageView = [[BARemoteImageView alloc] init];
		[self addSubview:_imageView];
	}
	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize viewSize = { 0, 0 };
	if (self.imageView.image) {
		viewSize = self.imageView.image.size;
	}
	CGSize maxViewSize = CGSizeMake(size.width - (self.imageInsets.left + self.imageInsets.right),
									size.height - (self.imageInsets.top + self.imageInsets.bottom));
	if (maxViewSize.width < viewSize.width && viewSize.width > 0 && maxViewSize.width > 0) {
		double scale = maxViewSize.width / viewSize.width;
		viewSize.width = roundf(maxViewSize.width);
		viewSize.height = roundf(scale * viewSize.height);
	}
	if (maxViewSize.height < viewSize.height && viewSize.height > 0 && maxViewSize.height > 0) {
		double scale = maxViewSize.height / viewSize.height;
		viewSize.width = roundf(scale * viewSize.width);
		viewSize.height = roundf(maxViewSize.height);
	}
	return CGSizeMake(viewSize.width + (self.imageInsets.left + self.imageInsets.right),
					  viewSize.height + (self.imageInsets.top + self.imageInsets.bottom));
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect r = UIEdgeInsetsInsetRect(self.bounds, self.imageInsets);
	if (self.imageView.image) {
		CGSize size = self.imageView.image.size;
		if (r.size.width < size.width && size.width > 0 && r.size.width > 0) {
			double scale = r.size.width / size.width;
			size.width = roundf(r.size.width);
			size.height = roundf(scale * size.height);
		}
		if (r.size.height < size.height && size.height > 0 && r.size.height > 0) {
			double scale = r.size.height / size.height;
			size.width = roundf(scale * size.width);
			size.height = roundf(r.size.height);
		}
		self.imageView.frame = CGRectMake(roundf(r.origin.x + (r.size.width - size.width) / 2),
										  roundf(r.origin.y + (r.size.height - size.height) / 2),
										  size.width, size.height);
	} else {
		self.imageView.frame = r;
	}
}

- (void)drawRect:(CGRect)rect {
	if (self.selected) {
		if (self.selectedOutlineColor) {
			[self.selectedOutlineColor set];
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			CGContextSetLineWidth(ctx, 1);
			CGRect r = self.imageView.frame;
			r = CGRectInset(r, -1, -1);
			UIRectFrame(r);
		}
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
