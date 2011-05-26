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

#import "BAPageControlViewController.h"

@implementation BAPageControlViewController

- (void)pageDidChange:(BAPageControl *)pageControl {
	NSInteger page = pageControl.currentPage;
	self.view.backgroundColor = [UIColor colorWithRed:(page % 2)
												green:(page % 3)
												 blue:(page == 0 ? 1 : 0)
												alpha:1];
}

- (void)addPage {
	_pageControl1.numberOfPages++;
}

- (void)removePage {
	_pageControl1.numberOfPages--;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	_pageControl1.numberOfPages = 6;
	[_pageControl1 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
	_pageControl2.activeColor = [UIColor redColor];
	_pageControl2.inactiveColor = [UIColor blueColor];
	_pageControl2.numberOfPages = 6;
	[_pageControl2 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
	_pageControl3.primaryMode = BAPageControlModeBlocks;
	_pageControl3.numberOfPages = 6;
	[_pageControl3 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
	_pageControl4.primaryMode = BAPageControlModeProgress;
	_pageControl4.inset = 120;
	_pageControl4.numberOfPages = 6;
	[_pageControl4 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
	_pageControl5.primaryMode = BAPageControlModeBlock;
	_pageControl5.inset = 120;
	_pageControl5.numberOfPages = 6;
	[_pageControl5 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
	_pageControl6.primaryMode = BAPageControlModePill;
	_pageControl6.inset = 120;
	_pageControl6.numberOfPages = 6;
	[_pageControl6 addTarget:self
					  action:@selector(pageDidChange:)
			forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[_pageControl1 release];
	_pageControl1 = nil;
	[_pageControl2 release];
	_pageControl2 = nil;
	[_pageControl3 release];
	_pageControl3 = nil;
	[_pageControl4 release];
	_pageControl4 = nil;
	[_pageControl5 release];
	_pageControl5 = nil;
	[_pageControl6 release];
	_pageControl6 = nil;
}

- (void)dealloc {
	[_pageControl1 release];
	[_pageControl2 release];
	[_pageControl3 release];
	[_pageControl4 release];
	[_pageControl5 release];
	[_pageControl6 release];
	[super dealloc];
}

@end
