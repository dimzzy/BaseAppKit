//
//  BAWebViewController.m
//  BADemo
//
//  Created by Dmitry Stadnik on 8/22/12.
//  Copyright (c) 2012 BaseAppKit. All rights reserved.
//

#import "BAWebViewController.h"

@interface BAWebViewController ()

@end

@implementation BAWebViewController {
	UIWebView *_webView;
}

- (void)dealloc {
    [_webView release];
    [super dealloc];
}

- (UIWebView *)webView {
	if (!_webView) {
		_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if (!self.webView.window) {
		self.webView.frame = self.view.bounds;
		[self.view addSubview:self.webView];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
