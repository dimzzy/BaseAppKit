//
//  BATextViewController.m
//  BADemo
//
//  Created by Dmitry Stadnik on 8/21/12.
//  Copyright (c) 2012 BaseAppKit. All rights reserved.
//

#import "BATextViewController.h"

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
