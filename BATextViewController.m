//
//  BATextViewController.m
//  BADemo
//
//  Created by Dmitry Stadnik on 8/21/12.
//  Copyright (c) 2012 BaseAppKit. All rights reserved.
//

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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = nil;
	if ([self.textView.text length] > 0) {
		NSURL *URL = [NSURL URLWithString:self.textView.text];
		if (URL) {
			self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																									target:self
																									action:@selector(openURL)] autorelease];
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)openURL {
	if ([self.textView.text length] > 0) {
		NSURL *URL = [NSURL URLWithString:self.textView.text];
		if (URL) {
			BAWebViewController *controller = [[[BAWebViewController alloc] init] autorelease];
			[controller.webView loadRequest:[NSURLRequest requestWithURL:URL
															 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
														 timeoutInterval:60]];
			[self.navigationController pushViewController:controller animated:YES];
		}
	}
}

@end
