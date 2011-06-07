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

#import "BAProgressView.h"

@implementation BAProgressView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dealloc {
	[_progressColor release];
    [super dealloc];
}

- (float)progress {
	return _progress;
}

- (void)setProgress:(float)progress {
	if (_progress == progress) {
		return;
	}
	if (progress < 0) {
		progress = 0;
	} else if (progress > 1) {
		progress = 1;
	}
	_progress = progress;
	[self setNeedsDisplay];
}

- (BOOL)failed {
	return _failed;
}

- (void)setFailed:(BOOL)failed {
	if (_failed == failed) {
		return;
	}
	_failed = failed;
	[self setNeedsDisplay];
}

- (UIColor *)progressColor {
	return _progressColor;
}

- (void)setProgressColor:(UIColor *)progressColor {
	if (_progressColor == progressColor) {
		return;
	}
	[_progressColor release];
	_progressColor = [progressColor retain];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	const CGFloat lw = 3;
	const CGFloat ps = MIN(self.bounds.size.width / 2, self.bounds.size.height / 2) - lw;
	const CGPoint cp = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	if (self.failed) {

		// progress plate
		CGContextBeginPath(ctx);
		CGContextAddArc(ctx, cp.x, cp.y, ps, 0, M_PI * 2, 0);
		CGContextClosePath(ctx);
		[self.progressColor set];
		CGContextFillPath(ctx);

		// cross
		CGContextBeginPath(ctx);
		CGFloat cd = ps * 0.35;
		CGContextMoveToPoint(ctx, cp.x + cd, cp.y + cd);
		CGContextAddLineToPoint(ctx, cp.x - cd, cp.y - cd);
		CGContextMoveToPoint(ctx, cp.x - cd, cp.y + cd);
		CGContextAddLineToPoint(ctx, cp.x + cd, cp.y - cd);
		CGContextMoveToPoint(ctx, cp.x + cd, cp.y + cd);
		CGContextClosePath(ctx);
		CGContextSetLineWidth(ctx, 4);
		CGContextSetLineCap(ctx, kCGLineCapRound);
		[self.backgroundColor set];
		CGContextStrokePath(ctx);
		
	} else {

		// progress pie
		if (self.progress > 0) {
			CGContextBeginPath(ctx);
			CGContextMoveToPoint(ctx, cp.x, cp.y);
			CGContextAddArc(ctx, cp.x, cp.y, ps - lw - 1, -M_PI_2, -M_PI_2 + M_PI * 2 * self.progress, 0);
			CGContextClosePath(ctx);
			[self.progressColor set];
			CGContextFillPath(ctx);
		}

		// progress border
		CGContextBeginPath(ctx);
		CGContextAddArc(ctx, cp.x, cp.y, ps, 0, M_PI * 2, 0);
		CGContextClosePath(ctx);
		[self.progressColor set];
		CGContextSetLineWidth(ctx, lw);
		CGContextStrokePath(ctx);
		
	}
}

@end
