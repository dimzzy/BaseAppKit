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
#import "BAGradientView.h"

@interface BAGradientView (Private)

@property(nonatomic, readonly) CAGradientLayer *gradientLayer;

- (void)updateGradientDirection;
- (void)updateGradientColors;

@end


@implementation BAGradientView

- (void)dealloc {
    [super dealloc];
}

- (void)setupView {
	_gradientDirection = BAGradientViewDirectionDown;
	[self updateGradientDirection];
	_startColor = [[UIColor clearColor] retain];
	_endColor = [[UIColor blackColor] retain];
	[self updateGradientColors];
}

- (void)awakeFromNib {
	[self setupView];
	[super awakeFromNib];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		[self setupView];
    }
    return self;
}

- (UIColor *)startColor {
	return _startColor;
}

- (void)setStartColor:(UIColor *)color {
	if (_startColor == color) {
		return;
	}
	[_startColor release];
	_startColor = [color retain];
	[self updateGradientColors];
}

- (UIColor *)endColor {
	return _endColor;
}

- (void)setEndColor:(UIColor *)color {
	if (_endColor == color) {
		return;
	}
	[_endColor release];
	_endColor = [color retain];
	[self updateGradientColors];
}

- (void)updateGradientColors {
	UIColor *startColor = self.startColor;
	if (!startColor) {
		startColor = [UIColor clearColor];
	}
	UIColor *endColor = self.endColor;
	if (!endColor) {
		endColor = [UIColor clearColor];
	}
	self.gradientLayer.colors = [NSArray arrayWithObjects:(id)startColor.CGColor, (id)endColor.CGColor, nil];
}

- (BAGradientViewDirection)gradientDirection {
	return _gradientDirection;
}

- (void)setGradientDirection:(BAGradientViewDirection)gradientDirection {
	if (_gradientDirection != gradientDirection) {
		_gradientDirection = gradientDirection;
		[self updateGradientDirection];
	}
}

- (void)updateGradientDirection {
	switch (self.gradientDirection) {
		case BAGradientViewDirectionDown: {
			self.gradientLayer.startPoint = CGPointMake(0.5, 0);
			self.gradientLayer.endPoint = CGPointMake(0.5, 1);
			break;
		}
		case BAGradientViewDirectionUp: {
			self.gradientLayer.startPoint = CGPointMake(0.5, 1);
			self.gradientLayer.endPoint = CGPointMake(0.5, 0);
			break;
		}
		case BAGradientViewDirectionRight: {
			self.gradientLayer.startPoint = CGPointMake(0, 0.5);
			self.gradientLayer.endPoint = CGPointMake(1, 0.5);
			break;
		}
		case BAGradientViewDirectionLeft: {
			self.gradientLayer.startPoint = CGPointMake(1, 0.5);
			self.gradientLayer.endPoint = CGPointMake(0, 0.5);
			break;
		}
	}
}

+ (Class)layerClass {
	return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer {
	return (CAGradientLayer *)self.layer;
}

@end
