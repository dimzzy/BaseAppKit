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

#import "BAMeshView.h"
#import "BAScrollViewProxyDelegate.h"
#import "BAMeshViewCell+Owner.h"

// assume slightly over 2 * 1024 / 44 which is two rows
#define kMaxReusableCellsCount 50

@implementation NSIndexPath (BAMeshView)

+ (NSIndexPath *)indexPathForCell:(NSInteger)cell inSection:(NSInteger)section {
	NSInteger indexes[] = { section, cell };
	return [NSIndexPath indexPathWithIndexes:(NSUInteger *)indexes length:2];
}

- (NSInteger)meshCell {
	return [self indexAtPosition:1];
}

- (NSInteger)meshSection {
	return [self indexAtPosition:0];
}

@end


// Layout data for a section

@interface BAMeshSectionData : NSObject

@property CGFloat y;
@property CGFloat headerHeight;
@property CGFloat footerHeight;
@property CGFloat totalHeight;
@property NSInteger numberOfCells;

- (CGRect)cellFrame:(NSInteger)cell;
- (void)setFrame:(CGRect)frame forCell:(NSInteger)cell;
- (NSInteger)cellAtPoint:(CGPoint)p;

@end

@implementation BAMeshSectionData {
@private
	NSInteger _numberOfCells;
	CGRect *_cellFrames;
}

@synthesize y = _y;
@synthesize headerHeight = _headerHeight;
@synthesize footerHeight = _footerHeight;
@synthesize totalHeight = _totalHeight;

- (void)dealloc {
	free(_cellFrames);
    [super dealloc];
}

- (NSInteger)numberOfCells {
	return _numberOfCells;
}

- (void)setNumberOfCells:(NSInteger)numberOfCells {
	if (_numberOfCells == numberOfCells) {
		return;
	}
	_numberOfCells = numberOfCells;
	free(_cellFrames);
	if (numberOfCells > 0) {
		_cellFrames = calloc(numberOfCells, sizeof(CGRect));
	} else {
		_cellFrames = NULL;
	}
}

- (CGRect)cellFrame:(NSInteger)cell {
	if (cell < 0 || cell >= _numberOfCells) {
		return CGRectZero;
	}
	return _cellFrames[cell];
}

- (void)setFrame:(CGRect)frame forCell:(NSInteger)cell {
	if (cell < 0 || cell >= _numberOfCells) {
		return;
	}
	_cellFrames[cell] = frame;
}

- (NSInteger)cellAtPoint:(CGPoint)p {
	// TODO: binary search
	for (NSInteger cell = 0; cell < self.numberOfCells; cell++) {
		CGRect frame = _cellFrames[cell];
		if (CGRectContainsPoint(frame, p)) {
			return cell;
		}
	}
	return -1;
}

- (NSString *)description {
	NSMutableString *s = [NSMutableString string];
	[s appendFormat:@"<section data %g/%g/%g/%g", self.y, self.headerHeight, self.footerHeight, self.totalHeight];
	for (NSInteger i = 0; i < self.numberOfCells; i++) {
		[s appendString:@" "];
		[s appendString:NSStringFromCGRect([self cellFrame:i])];
	}
	[s appendString:@">"];
	return s;
}

@end


// Views added for a section

@interface BAMeshSectionViews : NSObject

@property(assign) BOOL hasHeader;
@property(retain) UIView *headerView;
@property(assign) BOOL hasFooter;
@property(retain) UIView *footerView;
@property(assign) NSInteger numberOfCells;

- (BAMeshViewCell *)cellView:(NSInteger)cell;
- (void)setView:(BAMeshViewCell *)view forCell:(NSInteger)cell;
- (void)removeViewsWithReusableCells:(NSMutableArray *)reusableCells;

@end

@implementation BAMeshSectionViews {
@private
	NSInteger _numberOfCells;
	BAMeshViewCell **_cellViews;
}

@synthesize hasHeader = _hasHeader;
@synthesize headerView = _headerView;
@synthesize hasFooter = _hasFooter;
@synthesize footerView = _footerView;

- (void)freeCells {
	if (!_cellViews) {
		return;
	}
	for (NSUInteger cell = 0; cell < _numberOfCells; cell++) {
		[_cellViews[cell] removeFromSuperview];
		[_cellViews[cell] release];
	}
	free(_cellViews);
	_cellViews = NULL;
}

- (void)dealloc {
	[self removeViewsWithReusableCells:nil];
	free(_cellViews);
    [super dealloc];
}

- (NSInteger)numberOfCells {
	return _numberOfCells;
}

- (void)setNumberOfCells:(NSInteger)numberOfCells {
	if (_numberOfCells == numberOfCells) {
		return;
	}
	[self freeCells];
	_numberOfCells = numberOfCells;
	if (numberOfCells > 0) {
		_cellViews = calloc(numberOfCells, sizeof(BAMeshViewCell *));
	}
}

- (BAMeshViewCell *)cellView:(NSInteger)cell {
	if (cell < 0 || cell >= _numberOfCells) {
		return nil;
	}
	return [[_cellViews[cell] retain] autorelease];
}

- (void)setView:(BAMeshViewCell *)view forCell:(NSInteger)cell {
	if (cell < 0 || cell >= _numberOfCells) {
		return;
	}
	if (_cellViews[cell] == view) {
		return;
	}
	[_cellViews[cell] removeFromSuperview];
	[_cellViews[cell] release];
	_cellViews[cell] = [view retain];
}

- (void)removeViewsWithReusableCells:(NSMutableArray *)reusableCells {
	if (self.headerView) {
		[self.headerView removeFromSuperview];
		self.headerView = nil;
	}
	for (NSUInteger cell = 0; cell < _numberOfCells; cell++) {
		BAMeshViewCell *cellView = _cellViews[cell];
		if (!cellView) {
			continue;
		}
		[cellView removeFromSuperview];
		if (cellView.reuseIdentifier) {
			[cellView prepareForReuse];
			[reusableCells addObject:cellView];
		}
		[cellView release];
		_cellViews[cell] = nil;
	}
	if (self.footerView) {
		[self.footerView removeFromSuperview];
		self.footerView = nil;
	}
}

- (NSString *)description {
	NSMutableString *s = [NSMutableString string];
	[s appendFormat:@"<section views %d/%p/%d/%p ", self.hasHeader, self.headerView, self.hasFooter, self.footerView];
	for (NSInteger i = 0; i < self.numberOfCells; i++) {
		BAMeshViewCell *cellView = [self cellView:i];
		[s appendString:(cellView ? @"x" : @"-")];
	}
	[s appendString:@">"];
	return s;
}

@end


@interface BAMeshViewProxyDelegate : BAScrollViewProxyDelegate

@property(assign) id<NSObject> didScrollTarget;
@property(assign) SEL didScrollAction;

@end


@implementation BAMeshViewProxyDelegate

@synthesize didScrollTarget = _didScrollTarget;
@synthesize didScrollAction = _didScrollAction;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[super scrollViewDidScroll:scrollView];
	if (_didScrollTarget && _didScrollAction) {
		[_didScrollTarget performSelector:_didScrollAction];
	}
}

@end


@interface BAMeshView ()

- (CGSize)sizeForCell:(NSInteger)cell inSection:(NSInteger)section;
- (BAMeshRowLayout)rowsLayoutInSection:(NSInteger)section;
- (BAMeshCellAlignment)alignmentForCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (CGFloat)heightForFooterInSection:(NSInteger)section;
- (void)meshDidScroll;
- (void)handleTapOnCell:(UIGestureRecognizer *)recognizer;

@end


@implementation BAMeshView {
@private
	id<BAMeshViewDataSource> _dataSource;
	BAMeshViewProxyDelegate *_proxyDelegate; // retained; intercepts didScroll events
	CGFloat _meshHeaderHeight;
	CGFloat _meshFooterHeight;
	NSMutableArray *_sectionData; // all data for layout
	NSMutableArray *_sectionViews; // description of currently added views
	NSMutableArray *_reusableCells;
	UIView *_meshHeaderView;
	UIView *_meshFooterView;
}

@synthesize cellSize = _cellSize;
@synthesize sectionHeaderHeight = _sectionHeaderHeight;
@synthesize sectionFooterHeight = _sectionFooterHeight;

- (void)dealloc {
	[_proxyDelegate release];
	_proxyDelegate = nil;
	[_sectionData release];
	[_sectionViews release];
	[_reusableCells release];
	[_meshHeaderView release];
	[_meshFooterView release];
    [super dealloc];
}

- (void)setupMeshView {
	self.cellSize = CGSizeMake(44, 44);
//	self.sectionHeaderHeight = 22;
//	self.sectionFooterHeight = 22;
	[_proxyDelegate release];
	_proxyDelegate = [[BAMeshViewProxyDelegate alloc] init];
	_proxyDelegate.didScrollTarget = self;
	_proxyDelegate.didScrollAction = @selector(meshDidScroll);
	[super setDelegate:_proxyDelegate];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
		[self setupMeshView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)rect {
    if ((self = [super initWithFrame:rect])) {
		[self setupMeshView];
    }
    return self;
}

- (id<BAMeshViewDataSource>)dataSource {
	return _dataSource;
}

- (void)setDataSource:(id<BAMeshViewDataSource>)dataSource {
	if (_dataSource == dataSource) {
		return;
	}
	_dataSource = dataSource;
	[_sectionData release];
	_sectionData = nil;
	[_sectionViews release];
	_sectionViews = nil;
	[self setNeedsLayout];
}

- (id<BAMeshViewDelegate>)delegate {
	return (id<BAMeshViewDelegate>)[_proxyDelegate delegate];
}

- (void)setDelegate:(id<BAMeshViewDelegate>)delegate {
	if ([_proxyDelegate delegate] == delegate) {
		return;
	}
	[_proxyDelegate setDelegate:delegate];
	[_sectionData release];
	_sectionData = nil;
	[_sectionViews release];
	_sectionViews = nil;
	[self setNeedsLayout];
}

- (void)reloadData {
	[_sectionData release];
	_sectionData = nil;
	[_sectionViews release];
	_sectionViews = nil;
	[self setNeedsLayout];
}

- (NSMutableArray *)reusableCells {
	if (!_reusableCells) {
		_reusableCells = [[NSMutableArray alloc] init];
	}
	return _reusableCells;
}

- (void)compactReusableCells {
	const int extraCellsCount = [[self reusableCells] count] - kMaxReusableCellsCount;
	if (extraCellsCount > 0) {
		[[self reusableCells] removeObjectsInRange:NSMakeRange(0, extraCellsCount)];
	}
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier {
	if (!identifier) {
		return nil;
	}
	for (NSInteger i = 0; i < [[self reusableCells] count]; i++) {
		BAMeshViewCell *cell = [[self reusableCells] objectAtIndex:i];
		if ([[cell reuseIdentifier] isEqualToString:identifier]) {
			[[cell retain] autorelease];
			[[self reusableCells] removeObjectAtIndex:i];
			return cell;
		}
	}
	return nil;
}

- (CGFloat)extrapolatedSpreadForRow:(NSRange)cells ofSize:(CGSize)rowSize maxWidth:(CGFloat)maxWidth {
	if (cells.length < 2 || rowSize.width == 0) {
		return 0;
	}
	const CGFloat avgCellWidth = rowSize.width / cells.length;
	const int availableCellsCount = (maxWidth - rowSize.width) / avgCellWidth;
	return (maxWidth - rowSize.width - avgCellWidth * availableCellsCount) / (cells.length + availableCellsCount - 1);
}

- (void)layoutRow:(NSRange)cells
		   ofSize:(CGSize)rowSize
		 maxWidth:(CGFloat)maxWidth
		inSection:(NSInteger)section
			 data:(BAMeshSectionData *)sectionData
{
	if (cells.length == 0) {
		return;
	}
	BAMeshRowLayout rowLayout = [self rowsLayoutInSection:section];
	const BOOL lastRow = (sectionData.numberOfCells == cells.location + cells.length);
	if (!lastRow && (rowLayout == BAMeshRowLayoutSpreadCenter ||
					 rowLayout == BAMeshRowLayoutSpreadLeft ||
					 rowLayout == BAMeshRowLayoutSpreadRight))
	{
		rowLayout = BAMeshRowLayoutSpread;
	}
	CGFloat d; // horizontal interval
	CGFloat x;
	CGFloat w = 0; // cell width for fill layout
	switch (rowLayout) {
		case BAMeshRowLayoutSpread:
			if (cells.length > 1) {
				d = (maxWidth - rowSize.width) / (cells.length - 1);
			} else {
				d = 0;
			}
			x = 0;
			break;
		case BAMeshRowLayoutSpreadCenter:
			d = [self extrapolatedSpreadForRow:cells ofSize:rowSize maxWidth:maxWidth];
			x = (maxWidth - rowSize.width) / 2;
			break;
		case BAMeshRowLayoutSpreadLeft:
			d = [self extrapolatedSpreadForRow:cells ofSize:rowSize maxWidth:maxWidth];
			x = 0;
			break;
		case BAMeshRowLayoutSpreadRight:
			d = [self extrapolatedSpreadForRow:cells ofSize:rowSize maxWidth:maxWidth];
			x = maxWidth - rowSize.width - d * (cells.length - 1);
			break;
		case BAMeshRowLayoutCenter:
			d = 0;
			x = (maxWidth - rowSize.width) / 2;
			break;
		case BAMeshRowLayoutLeft:
			d = 0;
			x = 0;
			break;
		case BAMeshRowLayoutRight:
			d = 0;
			x = maxWidth - rowSize.width;
			break;
		case BAMeshRowLayoutFill:
			d = 0;
			x = 0;
			w = maxWidth / cells.length;
			break;
	}
	for (NSInteger cell = cells.location; cell < cells.location + cells.length; cell++) {
		CGRect cellFrame = [sectionData cellFrame:cell];
		cellFrame.origin.x = rint(x);
		if (rowLayout == BAMeshRowLayoutFill) {
			cellFrame.size.width = rint(w);
			x += w + d;
		} else {
			x += cellFrame.size.width + d;
		}
		BAMeshCellAlignment cellAlignment = [self alignmentForCellAtIndexPath:[NSIndexPath indexPathForCell:cell
																								  inSection:section]];
		// we assume here that cells are aligned at the top of the row
		switch (cellAlignment) {
			case BAMeshCellAlignmentTop:
				// nothing to do
				break;
			case BAMeshCellAlignmentCenter:
				cellFrame.origin.y += rint((rowSize.height - cellFrame.size.height) / 2);
				break;
			case BAMeshCellAlignmentBottom:
				cellFrame.origin.y += rint(rowSize.height - cellFrame.size.height);
				break;
			case BAMeshCellAlignmentFill:
				cellFrame.size.height = rowSize.height;
				break;
		}
		[sectionData setFrame:cellFrame forCell:cell];
	}
}

- (NSMutableArray *)sectionData {
	if (!_sectionData) {
//		NSLog(@"%s", __func__);
		const NSInteger numberOfSections = [self numberOfSections];
		_sectionData = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		CGFloat y = _meshHeaderHeight;
		const CGFloat maxWidth = self.bounds.size.width - (self.contentInset.left + self.contentInset.right);
		for (NSInteger section = 0; section < numberOfSections; section++) {
			BAMeshSectionData *sectionData = [[[BAMeshSectionData alloc] init] autorelease];
			sectionData.y = y;
			sectionData.headerHeight = [self heightForHeaderInSection:section];
			sectionData.footerHeight = [self heightForFooterInSection:section];
			sectionData.totalHeight = sectionData.headerHeight + sectionData.footerHeight;
			sectionData.numberOfCells = [self numberOfCellsInSection:section];
			y += sectionData.headerHeight;
			CGFloat x = 0;
			CGFloat rowHeight = 0;
			NSInteger firstRowCell = 0;
			for (NSInteger cell = firstRowCell; cell < sectionData.numberOfCells; cell++) {
				const CGSize cellSize = [self sizeForCell:cell inSection:section];
				if (cell > firstRowCell && (x + cellSize.width) > maxWidth) {
					[self layoutRow:NSMakeRange(firstRowCell, cell - firstRowCell)
							 ofSize:CGSizeMake(x, rowHeight)
						   maxWidth:maxWidth
						  inSection:section
							   data:sectionData];
					y += rowHeight;
					sectionData.totalHeight += rowHeight;
					x = 0;
					rowHeight = 0;
					firstRowCell = cell;
				}
				[sectionData setFrame:CGRectMake(x, y, cellSize.width, cellSize.height) forCell:cell];
				x += cellSize.width;
				rowHeight = MAX(rowHeight, cellSize.height);
			}
			y += rowHeight;
			if (sectionData.numberOfCells > firstRowCell) {
				[self layoutRow:NSMakeRange(firstRowCell, sectionData.numberOfCells - firstRowCell)
						 ofSize:CGSizeMake(x, rowHeight)
					   maxWidth:maxWidth
					  inSection:section
						   data:sectionData];
			}
			sectionData.totalHeight += rowHeight;
			[_sectionData addObject:sectionData];
//			NSLog(@"%@", sectionData);
			y += sectionData.footerHeight;
		}
		y += _meshFooterHeight;
		self.contentSize = CGSizeMake(maxWidth, y);
//		NSLog(@"Content Size %@", NSStringFromCGSize(self.contentSize));
	}
	return _sectionData;
}

- (NSMutableArray *)sectionViews {
	if (!_sectionViews) {
		const NSInteger numberOfSections = [self numberOfSections];
		_sectionViews = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		for (NSInteger section = 0; section < numberOfSections; section++) {
			BAMeshSectionViews *sectionViews = [[[BAMeshSectionViews alloc] init] autorelease];
			sectionViews.hasHeader = YES;
			sectionViews.hasFooter = YES;
			sectionViews.numberOfCells = [self numberOfCellsInSection:section];
			[_sectionViews addObject:sectionViews];
		}
	}
	return _sectionViews;
}

- (void)updateVisibleCells {
	[self sectionData]; // updates content size
	const CGRect contentRect = CGRectMake(0, self.contentOffset.y,
										  self.contentSize.width,
										  MIN(self.contentSize.height, self.bounds.size.height));
//	NSLog(@"Content Rect: %@", NSStringFromCGRect(contentRect));
	const NSInteger numberOfSections = [self numberOfSections];
	for (NSInteger section = 0; section < numberOfSections; section++) {
		BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:section];
		BAMeshSectionViews *sectionViews = [[self sectionViews] objectAtIndex:section];
		const CGRect sectionRect = CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.totalHeight);
//		NSLog(@"Section Rect: %@", NSStringFromCGRect(sectionRect));
		if (CGRectIntersectsRect(contentRect, sectionRect)) {
			// section is (partially?) visible
			if (sectionViews.hasHeader) {
				CGRect headerRect = CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.headerHeight);
				if (CGRectIntersectsRect(contentRect, headerRect)) {
					if (sectionViews.headerView) {
						sectionViews.headerView.frame = headerRect;
					} else {
						if ([self.delegate respondsToSelector:@selector(meshView:viewForHeaderInSection:)]) {
							sectionViews.headerView = [self.delegate meshView:self viewForHeaderInSection:section];
						}
						if (sectionViews.headerView) {
							sectionViews.headerView.frame = headerRect;
							[self insertSubview:sectionViews.headerView atIndex:0];
						} else {
							sectionViews.hasHeader = NO;
						}
					}
				} else {
					if (sectionViews.headerView) {
						[sectionViews.headerView removeFromSuperview];
						sectionViews.headerView = nil;
					}
				}
			}
			for (NSInteger cell = 0; cell < sectionViews.numberOfCells; cell++) {
				CGRect cellFrame = [sectionData cellFrame:cell];
				BAMeshViewCell *cellView = [sectionViews cellView:cell];
				if (CGRectIntersectsRect(contentRect, cellFrame)) {
					if (cellView) {
						cellView.frame = cellFrame;
					} else {
						NSIndexPath *indexPath = [NSIndexPath indexPathForCell:cell inSection:section];
						cellView = [self.dataSource meshView:self cellAtIndexPath:indexPath];
						if (!cellView) {
							[NSException raise:@"BAMeshViewError" format:@"Failed to create a cell"];
						}
						cellView.indexPath = indexPath;
						UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self
																							   action:@selector(handleTapOnCell:)]
													   autorelease];
						[cellView addGestureRecognizer:tap];
						cellView.frame = cellFrame;
						[self insertSubview:cellView atIndex:0];
						[sectionViews setView:cellView forCell:cell];
					}
				} else {
					if (cellView) {
						[cellView removeFromSuperview];
						if (cellView.reuseIdentifier) {
							[cellView prepareForReuse];
							[[self reusableCells] addObject:cellView];
						}
						[sectionViews setView:nil forCell:cell];
					}
				}
			}
			[self compactReusableCells];
			if (sectionViews.hasFooter) {
				CGRect footerRect = CGRectMake(0, sectionData.y + sectionData.totalHeight - sectionData.footerHeight,
											   self.contentSize.width, sectionData.footerHeight);
				if (CGRectIntersectsRect(contentRect, footerRect)) {
					if (sectionViews.footerView) {
						sectionViews.footerView.frame = footerRect;
					} else {
						if ([self.delegate respondsToSelector:@selector(meshView:viewForFooterInSection:)]) {
							sectionViews.footerView = [self.delegate meshView:self viewForFooterInSection:section];
						}
						if (sectionViews.footerView) {
							sectionViews.footerView.frame = footerRect;
							[self insertSubview:sectionViews.footerView atIndex:0];
						} else {
							sectionViews.hasFooter = NO;
						}
					}
				} else {
					if (sectionViews.footerView) {
						[sectionViews.footerView removeFromSuperview];
						sectionViews.footerView = nil;
					}
				}
			}
		} else {
			// section is not visible
			[sectionViews removeViewsWithReusableCells:[self reusableCells]];
			[self compactReusableCells];
		}
	}
}

- (void)layoutSubviews {
	CGFloat width = self.bounds.size.width;
	width -= (self.contentInset.left + self.contentInset.right);
	if (self.meshHeaderView) {
		_meshHeaderHeight = [self.meshHeaderView sizeThatFits:CGSizeMake(width, HUGE_VALF)].height;
	} else {
		_meshHeaderHeight = 0;
	}
	if (self.meshFooterView) {
		_meshFooterHeight = [self.meshFooterView sizeThatFits:CGSizeMake(width, HUGE_VALF)].height;
	} else {
		_meshFooterHeight = 0;
	}
	
	// update content size when view frame changes
	[_sectionData release];
	_sectionData = nil;
	
	[self updateVisibleCells];
	
	if (self.meshHeaderView) {
		self.meshHeaderView.frame = CGRectMake(0, 0, width, _meshHeaderHeight);
	}
	if (self.meshFooterView) {
		const CGFloat y = self.contentSize.height - _meshFooterHeight;
		self.meshFooterView.frame = CGRectMake(0, y, width, _meshFooterHeight);
	}
}

- (void)meshDidScroll {
	[self updateVisibleCells];
}

- (UIView *)meshHeaderView {
	return _meshHeaderView;
}

- (void)setMeshHeaderView:(UIView *)view {
	if (_meshHeaderView == view) {
		return;
	}
	[_meshHeaderView removeFromSuperview];
	[_meshHeaderView release];
	_meshHeaderView = [view retain];
	CGFloat width = self.bounds.size.width;
	width -= (self.contentInset.left + self.contentInset.right);
	if (view) {
		[self insertSubview:view atIndex:0];
		_meshHeaderHeight = [self.meshHeaderView sizeThatFits:CGSizeMake(width, HUGE_VALF)].height;
	} else {
		_meshHeaderHeight = 0;
	}
	[self setNeedsLayout];
}

- (UIView *)meshFooterView {
	return _meshFooterView;
}

- (void)setMeshFooterView:(UIView *)view {
	if (_meshFooterView == view) {
		return;
	}
	[_meshFooterView removeFromSuperview];
	[_meshFooterView release];
	_meshFooterView = [view retain];
	CGFloat width = self.bounds.size.width;
	width -= (self.contentInset.left + self.contentInset.right);
	if (view) {
		[self insertSubview:view atIndex:0];
		_meshFooterHeight = [self.meshFooterView sizeThatFits:CGSizeMake(width, HUGE_VALF)].height;
	} else {
		_meshFooterHeight = 0;
	}
	[self setNeedsLayout];
}

- (NSInteger)numberOfSections {
	if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInMeshView:)]) {
		return [self.dataSource numberOfSectionsInMeshView:self];
	}
	return 1;
}

- (NSInteger)numberOfCellsInSection:(NSInteger)section {
	return [self.dataSource meshView:self numberOfCellsInSection:section];
}

- (CGSize)sizeForCell:(NSInteger)cell inSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(meshView:sizeForCellAtIndexPath:)]) {
		return [self.delegate meshView:self sizeForCellAtIndexPath:[NSIndexPath indexPathForCell:cell inSection:section]];
	}
	return self.cellSize;
}

- (BAMeshRowLayout)rowsLayoutInSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(meshView:rowsLayoutInSection:)]) {
		return [self.delegate meshView:self rowsLayoutInSection:section];
	}
	return BAMeshRowLayoutSpread;
}

- (BAMeshCellAlignment)alignmentForCellAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.delegate respondsToSelector:@selector(meshView:alignmentForCellAtIndexPath:)]) {
		return [self.delegate meshView:self alignmentForCellAtIndexPath:indexPath];
	}
	return BAMeshCellAlignmentCenter;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(meshView:heightForHeaderInSection:)]) {
		return [self.delegate meshView:self heightForHeaderInSection:section];
	}
	return self.sectionHeaderHeight;
}

- (CGFloat)heightForFooterInSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(meshView:heightForFooterInSection:)]) {
		return [self.delegate meshView:self heightForFooterInSection:section];
	}
	return self.sectionFooterHeight;
}

- (CGRect)rectForSection:(NSInteger)section {
	BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.totalHeight);
}

- (CGRect)rectForHeaderInSection:(NSInteger)section {
	BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.headerHeight);
}

- (CGRect)rectForFooterInSection:(NSInteger)section {
	BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y + sectionData.totalHeight - sectionData.footerHeight,
					  self.contentSize.width, sectionData.footerHeight);
}

- (CGRect)rectForCellAtIndexPath:(NSIndexPath *)indexPath {
	BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:indexPath.meshSection];
	return [sectionData cellFrame:indexPath.meshCell];
}

- (NSIndexPath *)indexPathForCell:(BAMeshViewCell *)cell {
	return cell.indexPath;
}

- (BAMeshViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *allSectionViews = [self sectionViews];
	if (indexPath.meshSection < 0 || indexPath.meshSection >= [allSectionViews count]) {
		return nil;
	}
	BAMeshSectionViews *sectionViews = [allSectionViews objectAtIndex:indexPath.meshSection];
	if (indexPath.meshCell < 0 || indexPath.meshCell >= sectionViews.numberOfCells) {
		return nil;
	}
	return [sectionViews cellView:indexPath.meshCell];
}

- (NSIndexPath *)indexPathForCellAtPoint:(CGPoint)point {
	// Not Implemented Yet
	return nil;
}

- (NSArray *)indexPathsForRowsInRect:(CGRect)rect {
	// Not Implemented Yet
	return nil;
}

- (NSArray *)visibleCells {
	// Not Implemented Yet
	return nil;
}

- (NSArray *)indexPathsForVisibleCells {
	// Not Implemented Yet
	return nil;
}

- (NSIndexSet *)indexesOfVisibleSections {
	[self sectionData]; // updates content size
	NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];
	const CGRect contentRect = CGRectMake(0, self.contentOffset.y,
										  self.contentSize.width,
										  MIN(self.contentSize.height, self.bounds.size.height));
	const NSInteger numberOfSections = [self numberOfSections];
	for (NSInteger section = 0; section < numberOfSections; section++) {
		BAMeshSectionData *sectionData = [[self sectionData] objectAtIndex:section];
		const CGRect sectionRect = CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.totalHeight);
		if (CGRectIntersectsRect(contentRect, sectionRect)) {
			[sections addIndex:section];
		}
	}
	return sections;
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
			  atScrollPosition:(UITableViewScrollPosition)scrollPosition
					  animated:(BOOL)animated
{
	// Not Implemented Yet
}

- (void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
	// Not Implemented Yet
}

// Selection

- (BAMeshViewCell *)willSelectCell:(BAMeshViewCell *)cell {
	NSIndexPath *indexPath = [self indexPathForCell:cell];
	NSIndexPath *proposedIndexPath = indexPath;
	if (indexPath && [self.delegate respondsToSelector:@selector(meshView:willSelectCellAtIndexPath:)]) {
		proposedIndexPath = [self.delegate meshView:self willSelectCellAtIndexPath:indexPath];
	}
	if (proposedIndexPath) {
		if ([proposedIndexPath isEqual:indexPath]) {
			return cell;
		} else {
			return [self cellAtIndexPath:proposedIndexPath];
		}
	} else {
		return nil;
	}
}

- (void)didSelectCell:(BAMeshViewCell *)cell {
	NSIndexPath *indexPath = [self indexPathForCell:cell];
	if (indexPath && [self.delegate respondsToSelector:@selector(meshView:didSelectCellAtIndexPath:)]) {
		[self.delegate meshView:self didSelectCellAtIndexPath:indexPath];
	}
}

- (void)handleTapOnCell:(UIGestureRecognizer *)recognizer {
	if (![recognizer.view isKindOfClass:[BAMeshViewCell class]]) {
		return;
	}
	BAMeshViewCell *cell = (BAMeshViewCell *)recognizer.view;
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		cell.highlighted = YES;
	} else if (recognizer.state == UIGestureRecognizerStateCancelled) {
		cell.highlighted = NO;
	} else if (recognizer.state == UIGestureRecognizerStateEnded) {
		cell.highlighted = NO;
		BAMeshViewCell *proposedCell = [self willSelectCell:cell];
		if (proposedCell) {
			proposedCell.selected = YES;
			[self didSelectCell:proposedCell];
		}
	}
}

- (NSIndexPath *)indexPathForSelectedCell {
	// Not Implemented Yet
	return nil;
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath
					animated:(BOOL)animated
			  scrollPosition:(UITableViewScrollPosition)scrollPosition
{
	// Not Implemented Yet
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	// Not Implemented Yet
}

@end
