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

#import "BAActivityView.h"
#import <QuartzCore/QuartzCore.h>

#define kBAActivityViewPadding 10

@implementation BAActivityView

@synthesize indicatorView = _indicatorView;
@synthesize descriptionLabel = _descriptionLabel;

- (void)dealloc {
    [super dealloc];
	[_indicatorView release];
	[_descriptionLabel release];
}

- (void)setupView {
	self.layer.cornerRadius = 10;
	self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
	
	_indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[_indicatorView startAnimating];
	[self addSubview:_indicatorView];
	
	_descriptionLabel = [[UILabel alloc] init];
	_descriptionLabel.font = [UIFont systemFontOfSize:16];
	_descriptionLabel.textColor = [UIColor whiteColor];
	_descriptionLabel.backgroundColor = [UIColor clearColor];
	_descriptionLabel.textAlignment = UITextAlignmentCenter;
	_descriptionLabel.numberOfLines = 10;
	_descriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
	[self addSubview:_descriptionLabel];
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setupView];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setupView];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	const CGFloat width = self.bounds.size.width - kBAActivityViewPadding * 2;
	CGSize labelSize = [self.descriptionLabel.text sizeWithFont:self.descriptionLabel.font
											  constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
												  lineBreakMode:self.descriptionLabel.lineBreakMode];
	CGFloat height = self.indicatorView.bounds.size.height + labelSize.height + kBAActivityViewPadding * 3;
	return CGSizeMake(size.width, height);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGFloat y = kBAActivityViewPadding;

	[self.indicatorView sizeToFit];
	self.indicatorView.center = CGPointMake(self.bounds.size.width / 2, y + self.indicatorView.bounds.size.height / 2);
	
	y += self.indicatorView.bounds.size.height + kBAActivityViewPadding;
	
	CGFloat width = self.bounds.size.width - kBAActivityViewPadding * 2;
	CGSize labelSize = [self.descriptionLabel.text sizeWithFont:self.descriptionLabel.font
											  constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
												  lineBreakMode:self.descriptionLabel.lineBreakMode];
	self.descriptionLabel.frame = CGRectMake(kBAActivityViewPadding, y, width, labelSize.height);
}

@end
