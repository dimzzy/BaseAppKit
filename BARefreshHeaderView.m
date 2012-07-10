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

#import "BARefreshHeaderView.h"

const double kArrowFlipAnimationDuration = 0.18;
const CGFloat kMargin = 25;
const CGFloat kArrowWidth = 23;
const CGFloat kArrowHeight = 60;
const CGFloat kRefreshHeaderHeight = 80;
const CGFloat kRefreshHeaderActionHeight = 5;

@implementation BARefreshHeaderView {
@private
	BARefreshHeaderState _state;
}

@synthesize errorText = _errorText;
@synthesize lastUpdatedLabel = _lastUpdatedLabel;
@synthesize statusLabel = _statusLabel;
@synthesize arrowImageLayer = _arrowImageLayer;
@synthesize activityView = _activityView;
@synthesize delegate = _delegate;

- (void)dealloc {
	[_lastUpdatedLabel release];
	[_statusLabel release];
	[_arrowImageLayer release];
	[_activityView release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		_lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMargin + kArrowWidth,
																	  frame.size.height - 30,
																	  self.frame.size.width - (kMargin + kArrowWidth + kMargin),
																	  20)];
		_lastUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_lastUpdatedLabel.font = [UIFont systemFontOfSize:12];
		_lastUpdatedLabel.backgroundColor = [UIColor clearColor];
		_lastUpdatedLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:_lastUpdatedLabel];
		
		_statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMargin + kArrowWidth,
																 frame.size.height - 68,
																 self.frame.size.width - (kMargin + kArrowWidth + kMargin),
																 40)];
		_statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_statusLabel.font = [UIFont boldSystemFontOfSize:13];
		_statusLabel.backgroundColor = [UIColor clearColor];
		_statusLabel.textAlignment = UITextAlignmentCenter;
		_statusLabel.numberOfLines = 2;
		[self addSubview:_statusLabel];
		
		_arrowImageLayer = [[CALayer layer] retain];
		_arrowImageLayer.frame = CGRectMake(kMargin, frame.size.height - 70, kArrowWidth, kArrowHeight);
		_arrowImageLayer.contentsGravity = kCAGravityResizeAspect;
		_arrowImageLayer.contentsScale = [[UIScreen mainScreen] scale];
		[[self layer] addSublayer:_arrowImageLayer];
		
		_activityView = [[UIActivityIndicatorView alloc] init];
		_activityView.frame = CGRectMake(kMargin, frame.size.height - 48, 20, 20);
		[self addSubview:_activityView];
		
		[self setState:BARefreshHeaderStateIdle];
    }
    return self;
	
}

- (void)refreshLastUpdatedDate {
	if ([_delegate respondsToSelector:@selector(refreshHeaderDataSourceLastUpdated:)]) {
		NSDate *date = [_delegate refreshHeaderDataSourceLastUpdated:self];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle:NSDateFormatterMediumStyle];
		_lastUpdatedLabel.text = [NSString stringWithFormat:@"%@ %@",
								  NSLocalizedString(@"RefreshHeaderUpdated", nil),
								  [formatter stringFromDate:date]];
		[[NSUserDefaults standardUserDefaults] setObject:_lastUpdatedLabel.text forKey:@"BARefreshHeaderView_LastUpdate"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[formatter release];
	} else {
		_lastUpdatedLabel.text = nil;
	}
}

- (void)setState:(BARefreshHeaderState)state {
	switch (state) {

		case BARefreshHeaderStatePulling:
			_statusLabel.text = NSLocalizedString(@"RefreshHeaderRelease", nil);
			[CATransaction begin];
			[CATransaction setAnimationDuration:kArrowFlipAnimationDuration];
			_arrowImageLayer.transform = CATransform3DMakeRotation((M_PI / 180.0) * 180, 0, 0, 1);
			[CATransaction commit];
			break;

		case BARefreshHeaderStateIdle:
			if (_state == BARefreshHeaderStatePulling) {
				[CATransaction begin];
				[CATransaction setAnimationDuration:kArrowFlipAnimationDuration];
				_arrowImageLayer.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			_statusLabel.text = self.errorText ? self.errorText : NSLocalizedString(@"RefreshHeaderPull", nil);
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			_arrowImageLayer.hidden = NO;
			_arrowImageLayer.transform = CATransform3DIdentity;
			[CATransaction commit];
			[self refreshLastUpdatedDate];
			break;

		case BARefreshHeaderStateLoading:
			_statusLabel.text = NSLocalizedString(@"RefreshHeaderLoading", nil);
			[_activityView startAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImageLayer.hidden = YES;
			[CATransaction commit];
			break;

		default:
			break;
	}
	_state = state;
}

- (void)dataSourceDidStartLoading:(UIScrollView *)scrollView {
	[UIView animateWithDuration:0.3
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 UIEdgeInsets insets = [scrollView contentInset];
						 insets.top = kRefreshHeaderHeight;
						 [scrollView setContentInset:insets];
					 }
					 completion:nil];
	[self setState:BARefreshHeaderStateLoading];
}

- (void)dataSourceDidFinishLoading:(UIScrollView *)scrollView {
	[UIView animateWithDuration:0.3
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 UIEdgeInsets insets = [scrollView contentInset];
						 insets.top = 0;
						 [scrollView setContentInset:insets];
					 }
					 completion:nil];
	[self setState:BARefreshHeaderStateIdle];
}

- (void)dataSourceDidFail:(UIScrollView *)scrollView {
	[UIView animateWithDuration:0.3
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 UIEdgeInsets insets = [scrollView contentInset];
						 insets.top = kRefreshHeaderHeight;
						 [scrollView setContentInset:insets];
					 }
					 completion:nil];
	[self setState:BARefreshHeaderStateIdle];
}

- (BOOL)dataSourceLoading {
	BOOL loading = NO;
	if ([_delegate respondsToSelector:@selector(refreshHeaderDataSourceLoading:)]) {
		loading = [_delegate refreshHeaderDataSourceLoading:self];
	}
	return loading;
}

#pragma mark -
#pragma mark Scroll View Callbacks

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	if (_state == BARefreshHeaderStateLoading) {
		UIEdgeInsets insets = [scrollView contentInset];
		CGFloat offset = MAX(-scrollView.contentOffset.y, 0);
		insets.top = MIN(offset, kRefreshHeaderHeight);
		[scrollView setContentInset:insets];
	} else if (scrollView.isDragging) {
		const BOOL loading = [self dataSourceLoading];
		if (_state == BARefreshHeaderStatePulling &&
			scrollView.contentOffset.y > -(kRefreshHeaderHeight + kRefreshHeaderActionHeight) &&
			scrollView.contentOffset.y < 0 &&
			!loading)
		{
			[self setState:BARefreshHeaderStateIdle];
		} else if (_state == BARefreshHeaderStateIdle &&
				   scrollView.contentOffset.y < -(kRefreshHeaderHeight + kRefreshHeaderActionHeight) &&
				   !loading)
		{
			[self setState:BARefreshHeaderStatePulling];
		}
//		if (scrollView.contentInset.top != 0) {
//			scrollView.contentInset = UIEdgeInsetsZero;
//		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	const BOOL loading = [self dataSourceLoading];
	if (scrollView.contentOffset.y <= -(kRefreshHeaderHeight + kRefreshHeaderActionHeight) && !loading) {
		if ([_delegate respondsToSelector:@selector(refreshHeaderDidTriggerRefresh:)]) {
			[_delegate refreshHeaderDidTriggerRefresh:self];
		}
		[self setState:BARefreshHeaderStateLoading];
		[UIView animateWithDuration:0.2
							  delay:0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 UIEdgeInsets insets = [scrollView contentInset];
							 insets.top = kRefreshHeaderHeight;
							 [scrollView setContentInset:insets];
						 }
						 completion:nil];
	}
}

@end
