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
#import "BAGridViewCell.h"


// Support column in index paths

@interface NSIndexPath (BAGridView)

+ (NSIndexPath *)indexPathForColumn:(NSInteger)column inRow:(NSInteger)row inSection:(NSInteger)section;

@property(nonatomic, readonly) NSInteger gridColumn;
@property(nonatomic, readonly) NSInteger gridRow;
@property(nonatomic, readonly) NSInteger gridSection;

@end


#pragma mark -
#pragma mark data source

@class BAGridView;

@protocol BAGridViewDataSource <NSObject>

- (NSInteger)gridView:(BAGridView *)gridView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)gridView:(BAGridView *)gridView numberOfColumnsInRow:(NSInteger)row inSection:(NSInteger)section;
- (BAGridViewCell *)gridView:(BAGridView *)gridView cellAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInGridView:(BAGridView *)gridView; // Default is 1 if not implemented

@end

#pragma mark -
#pragma mark delagate

@protocol BAGridViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (void)gridView:(BAGridView *)gridView willDisplayCell:(BAGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (CGSize)gridView:(BAGridView *)gridView sizeForCellAtIndexPath:(NSIndexPath *)indexPath;

// Headers & Footers

- (CGFloat)gridView:(BAGridView *)gridView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)gridView:(BAGridView *)gridView heightForFooterInSection:(NSInteger)section;
- (UIView *)gridView:(BAGridView *)gridView viewForHeaderInSection:(NSInteger)section;
- (UIView *)gridView:(BAGridView *)gridView viewForFooterInSection:(NSInteger)section;

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)gridView:(BAGridView *)gridView willSelectCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)gridView:(BAGridView *)gridView willDeselectCellAtIndexPath:(NSIndexPath *)indexPath;

// Called after the user changes the selection.
- (void)gridView:(BAGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(BAGridView *)gridView didDeselectCellAtIndexPath:(NSIndexPath *)indexPath;

@end


#pragma mark -
#pragma mark view

@interface BAGridView : UIScrollView

@property(nonatomic,assign) id <BAGridViewDataSource> dataSource;
@property(nonatomic,assign) id <BAGridViewDelegate> delegate;
@property(nonatomic) CGSize cellSize;               // will return the default value (44x44) if unset
@property(nonatomic) CGFloat sectionHeaderHeight;   // will return the default value (0) if unset
@property(nonatomic) CGFloat sectionFooterHeight;   // will return the default value (0) if unset

// Data

- (void)reloadData;

// Info

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfColumnsInRow:(NSInteger)row inSection:(NSInteger)section;

- (CGRect)rectForSection:(NSInteger)section;                                    // includes header, footer and all rows
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForFooterInSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;                         // returns nil if point is outside table
- (NSIndexPath *)indexPathForCell:(BAGridViewCell *)cell;                       // returns nil if cell is not visible
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
