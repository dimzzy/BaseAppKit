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

typedef enum {
	BAPageControlModeDots = 0, // like system control
	BAPageControlModeBlocks,   // squares instead of dots
	BAPageControlModeProgress, // rectangular progress bar with round corners
	BAPageControlModeBlock,    // rectangular progress bar
	BAPageControlModePill      // bordered progress bar with round corners
} BAPageControlMode;

typedef enum {
	BAPageControlAlignmentCenter, // default
	BAPageControlAlignmentLeft,
	BAPageControlAlignmentRight
} BAPageControlAlignment;

@interface BAPageControl : UIControl {
@private
	NSInteger _numberOfPages;
	NSInteger _currentPage;
	NSInteger _displayedPage;
	BOOL _hidesForSinglePage;
	BOOL _defersCurrentPageDisplay;
	UIColor *_activeColor;
	UIColor *_inactiveColor;
	BAPageControlMode _primaryMode;
	BAPageControlMode _fitMode;
	BAPageControlAlignment _alignment;
	CGFloat _inset;
}

@property(nonatomic) NSInteger numberOfPages; // default is 0
@property(nonatomic) NSInteger currentPage; // default is 0. value pinned to 0..numberOfPages-1
@property(nonatomic) BOOL hidesForSinglePage; // hide the the indicator if there is only one page. default is NO
@property(nonatomic) BOOL defersCurrentPageDisplay; // if set, clicking to a new page won't update the currently
													// displayed page until -updateCurrentPageDisplay is called.
													// default is NO

@property(nonatomic, retain) UIColor *activeColor; // default is white
@property(nonatomic, retain) UIColor *inactiveColor; // default is semitransparent active color

@property(nonatomic, assign) BAPageControlMode primaryMode; // dots is default
@property(nonatomic, assign) BAPageControlMode fitMode; // progress is default; used if primary mode is dots or blocks
														// and they don't fit in bounds (too many pages);
                                                        // in most cases you want this to be progress, block or pill
@property(nonatomic, readonly) BAPageControlMode displayMode; // primary or fit mode depending on bounds and pages count

@property(nonatomic, assign) BAPageControlAlignment alignment;

@property(nonatomic, assign) CGFloat inset; // for progress bar modes and left/right aligned modes

- (void)updateCurrentPageDisplay; // update page display to match the currentPage.
								  // ignored if defersCurrentPageDisplay is NO.
								  // setting the page value directly will update immediately

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount; // returns minimum size required to display dots for given page count.
													 // can be used to size control if page count could change

@end
