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

#import "BARemoteImageView.h"
#import "BAPersistentCache.h"

@implementation BARemoteImageView

@synthesize animateImageUpdate = _animateImageUpdate;
@synthesize delegate = _delegate;

- (void)resetLoader {
	if (_loader) {
		_loader.delegate = nil; // IMPORTANT: nullify delegate since loader is retained by connection and can outlive us
		[_loader release];
		_loader = nil;
	}
}

- (void)dealloc {
	[self resetLoader];
	[_remoteImageURL release];
	[super dealloc];
}

- (UIImageView *)duplicate {
	UIImageView *imageView = [[[UIImageView alloc] initWithImage:self.image] autorelease];
	imageView.frame = self.bounds;
	imageView.contentMode = self.contentMode;
	imageView.clipsToBounds = self.clipsToBounds;
	return imageView;
}

- (void)updateRemoteImage:(UIImage *)remoteImage animated:(BOOL)animated {
	UIImageView *coverImageView = nil;
	if (animated && self.animateImageUpdate) {
		coverImageView = [self duplicate];
		[self insertSubview:coverImageView atIndex:0];
	}
	self.image = remoteImage;
	if (coverImageView) {
		[UIView animateWithDuration:0.3
						 animations:^{
							 coverImageView.alpha = 0;
						 } completion:^(BOOL finished) {
							 [coverImageView removeFromSuperview];
						 }];
	}
}

- (NSURL *)remoteImageURL {
	return _remoteImageURL;
}

- (void)setRemoteImageURL:(NSURL *)remoteImageURL {
	if (_remoteImageURL == remoteImageURL) {
		return;
	}
	[_remoteImageURL release];
	_remoteImageURL = [remoteImageURL retain];

	[self resetLoader];
	if (_remoteImageURL) {
		// Check cache first so update is immediate; loader defers update
		UIImage *image = [[BAPersistentCache persistentCache] imageForKey:[_remoteImageURL absoluteString]];
		if (image) {
			[self updateRemoteImage:image animated:NO];
		} else {
			NSURLRequest *request = [BADataLoader GETRequestWithURL:_remoteImageURL];
			_loader = [[BADataLoader alloc] initWithRequest:request];
			_loader.delegate = self;
			[_loader startIgnoreCache:NO];
		}
	}
}

- (void)loader:(BADataLoader *)loader didFinishLoadingData:(NSData *)data fromCache:(BOOL)fromCache {
	UIImage *image = [UIImage imageWithData:data];
	[self updateRemoteImage:image animated:!fromCache];
	[self resetLoader];
	if (self.delegate && [self.delegate respondsToSelector:@selector(remoteImageViewDidLoad:)]) {
		[self.delegate remoteImageViewDidLoad:self];
	}
}

- (void)loader:(BADataLoader *)loader didFailWithError:(NSError *)error {
	[self resetLoader];
	if (self.delegate && [self.delegate respondsToSelector:@selector(remoteImageView:didFailWithError:)]) {
		[self.delegate remoteImageView:self didFailWithError:error];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.delegate && [self.delegate respondsToSelector:@selector(remoteImageView:touchesBegan:withEvent:)]) {
		[self.delegate remoteImageView:self touchesBegan:touches withEvent:event];
	}
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.delegate && [self.delegate respondsToSelector:@selector(remoteImageView:touchesEnded:withEvent:)]) {
		[self.delegate remoteImageView:self touchesEnded:touches withEvent:event];
	}
	[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.delegate && [self.delegate respondsToSelector:@selector(remoteImageView:touchesCancelled:withEvent:)]) {
		[self.delegate remoteImageView:self touchesCancelled:touches withEvent:event];
	}
	[super touchesCancelled:touches withEvent:event];
}

@end
