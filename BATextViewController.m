/*
 Copyright 2012 Dmitry Stadnik. All rights reserved.

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

#import "BATextViewController.h"
#import "BAWebViewController.h"

@interface BATextViewController ()

@end

@implementation BATextViewController {
	UITextView *_textView;
}

- (void)dealloc {
    [_textView release];
    [super dealloc];
}

- (UITextView *)textView {
	if (!_textView) {
		_textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		_textView.editable = NO;
		_textView.font = [UIFont systemFontOfSize:13];
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _textView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if (!self.textView.window) {
		self.textView.frame = self.view.bounds;
		[self.view addSubview:self.textView];
	}
}

- (NSURL *)textURL {
	NSString *t = self.textView.text;
	if (![t hasPrefix:@"http://"] && ![t hasPrefix:@"https://"]) {
		return nil;
	}
	return [NSURL URLWithString:t];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = nil;
	NSURL *URL = [self textURL];
	if (URL) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																								target:self
																								action:@selector(openURL)] autorelease];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)openURL {
	NSURL *URL = [self textURL];
	if (URL) {
		BAWebViewController *controller = [[[BAWebViewController alloc] init] autorelease];
		[controller.webView loadRequest:[NSURLRequest requestWithURL:URL
														 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
													 timeoutInterval:60]];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
