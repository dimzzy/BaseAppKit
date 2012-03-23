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

#import <UIKit/UIKit.h>
#import "BAPageControl.h"

@interface BACustomPageControl : UIControl

@property(nonatomic) NSInteger numberOfPages; // default is 0
@property(nonatomic) NSInteger currentPage; // default is 0. value pinned to 0..numberOfPages-1
@property(nonatomic) BOOL hidesForSinglePage; // hide the the indicator if there is only one page. default is NO
@property(nonatomic) BOOL defersCurrentPageDisplay; // if set, clicking to a new page won't update the currently
                                                    // displayed page until -updateCurrentPageDisplay is called.
                                                    // default is NO

@property(nonatomic, retain) UIImage *activeImage;
@property(nonatomic, retain) UIImage *inactiveImage;

@property(nonatomic, assign) BAPageControlAlignment alignment;

@property(nonatomic, assign) CGFloat inset; // for left/right aligned modes

- (void)updateCurrentPageDisplay; // update page display to match the currentPage.
                                  // ignored if defersCurrentPageDisplay is NO.
                                  // setting the page value directly will update immediately

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount; // returns minimum size required to display dots for given page count.
                                                     // can be used to size control if page count could change

@end
