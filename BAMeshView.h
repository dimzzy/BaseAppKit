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
#import "BAMeshViewCell.h"


// Support column in index paths

@interface NSIndexPath (BAMeshView)

+ (NSIndexPath *)indexPathForCell:(NSInteger)cell inSection:(NSInteger)section;

@property(nonatomic, readonly) NSInteger meshCell;
@property(nonatomic, readonly) NSInteger meshSection;

@end


#pragma mark -
#pragma mark data source

@class BAMeshView;

@protocol BAMeshViewDataSource <NSObject>

- (NSInteger)meshView:(BAMeshView *)meshView numberOfCellsInSection:(NSInteger)section;
- (BAMeshViewCell *)meshView:(BAMeshView *)meshView cellAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInMeshView:(BAMeshView *)meshView; // Default is 1 if not implemented

@end

#pragma mark -
#pragma mark delagate

// Note about spread logic:
// 
// By default all cells in a row are distributed evenly along the row. But the last row could be treated
// differently because it could contain fewer cells and (especially for meshes with a fixed cell size)
// it makes sense to use the same horizontal spacing as for the rows above.
// 
// So layouts BAMeshRowLayoutSpread[Center|Left|Right] treat the last row in a special way: first average
// cell width for the last row is calculated. Then we calculate how many average cells would fit in the row.
// Next based on this estimate we calculate horizontal spacing which is used to separate the existing cells.
// This should give us better layout for the last row and if all cells have a fixed size then horizontal
// spacing will be exactly the same for all rows.

typedef enum {
	BAMeshRowLayoutSpread = 0, // default; distribute cells evenly in rows
	BAMeshRowLayoutSpreadCenter, // spread with the last row centered
	BAMeshRowLayoutSpreadLeft, // spread with the last row aligned to the left side
	BAMeshRowLayoutSpreadRight, // spread with the last row aligned to the right side
	BAMeshRowLayoutCenter, // all cells are packed and centered within row
	BAMeshRowLayoutLeft, // all cells are packed at the left side
	BAMeshRowLayoutRight, // all cells are packed at the right side
	BAMeshRowLayoutFill // all cells are made equal width to cover the whole row
} BAMeshRowLayout;

typedef enum {
	BAMeshCellAlignmentCenter = 0, // default; cell is centered vertically within row
	BAMeshCellAlignmentTop, // cell is at row's top
	BAMeshCellAlignmentBottom, // cell is at row's bottom
	BAMeshCellAlignmentFill // cell height is made equal to the row height
} BAMeshCellAlignment;

@protocol BAMeshViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (void)meshView:(BAMeshView *)meshView willDisplayCell:(BAMeshViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (CGSize)meshView:(BAMeshView *)meshView sizeForCellAtIndexPath:(NSIndexPath *)indexPath;
- (BAMeshRowLayout)meshView:(BAMeshView *)meshView rowsLayoutInSection:(NSInteger)section;
- (BAMeshCellAlignment)meshView:(BAMeshView *)meshView alignmentForCellAtIndexPath:(NSIndexPath *)indexPath;

// Headers & Footers

- (CGFloat)meshView:(BAMeshView *)meshView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)meshView:(BAMeshView *)meshView heightForFooterInSection:(NSInteger)section;
- (UIView *)meshView:(BAMeshView *)meshView viewForHeaderInSection:(NSInteger)section;
- (UIView *)meshView:(BAMeshView *)meshView viewForFooterInSection:(NSInteger)section;

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)meshView:(BAMeshView *)meshView willSelectCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)meshView:(BAMeshView *)meshView willDeselectCellAtIndexPath:(NSIndexPath *)indexPath;

// Called after the user changes the selection.
- (void)meshView:(BAMeshView *)meshView didSelectCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)meshView:(BAMeshView *)meshView didDeselectCellAtIndexPath:(NSIndexPath *)indexPath;

@end


#pragma mark -
#pragma mark view

@interface BAMeshView : UIScrollView

@property(nonatomic, assign) IBOutlet id<BAMeshViewDataSource> dataSource;
@property(nonatomic, assign) IBOutlet id<BAMeshViewDelegate> delegate;
@property(nonatomic) CGSize cellSize;               // will return the default value (44x44) if unset
@property(nonatomic) CGFloat sectionHeaderHeight;   // will return the default value (0) if unset
@property(nonatomic) CGFloat sectionFooterHeight;   // will return the default value (0) if unset

// Data

- (void)reloadData;

// Info

- (NSInteger)numberOfSections;
- (NSInteger)numberOfCellsInSection:(NSInteger)section;

- (CGRect)rectForSection:(NSInteger)section;                                    // includes header, footer and all rows
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForFooterInSection:(NSInteger)section;
- (CGRect)rectForCellAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForCellAtPoint:(CGPoint)point;                        // returns nil if point is outside table
- (NSIndexPath *)indexPathForCell:(BAMeshViewCell *)cell;                       // returns nil if cell is not visible
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;                              // returns nil if rect not valid 

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;                  // returns nil if cell is not visible or index path is out of range
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleCells;

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated;

// Selection

- (NSIndexPath *)indexPathForSelectedCell; // returns nil or index path representing section and row of selection.
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;  // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.

@end
