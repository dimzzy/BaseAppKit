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

#import <UIKit/UIKit.h>
#import "BAScrollViewProxyDelegate.h"

@class BAPager;


@protocol BAPagerDelegate <UIScrollViewDelegate>

// Create or reuse a view that will serve as a page; similar to tableView:cellForRowAtIndexPath: of table's data source
- (UIView *)pager:(BAPager *)pager pageAtIndex:(NSInteger)index;

@optional

// Index at which page will be inserted in scroll view; 0 if not implemented
// You could use it to control z-order of the pages
- (NSInteger)pager:(BAPager *)pager orderOfPageAtIndex:(NSInteger)index;

// Called when pager removes the page; good place to update your controller for the page
- (void)pager:(BAPager *)pager dropPageAtIndex:(NSInteger)index;

// Update current page indicators or what you have
- (void)pager:(BAPager *)pager currentPageDidChangeTo:(NSInteger)index;

@end


@interface BAPager : BAScrollViewProxyDelegate

@property(nonatomic, retain) UIScrollView *scrollView;
@property(nonatomic, assign) NSUInteger numberOfPages;
@property(nonatomic, assign) NSInteger currentPageIndex;
@property(nonatomic, assign) id<BAPagerDelegate> delegate;

// Similar to reloadData of table view
- (void)reloadPages;

// You should call this method when scroll view bounds change, typically after rotation
- (void)layoutPages;

@end
