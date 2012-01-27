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

#import "BAGridView.h"
#import "BAScrollViewProxyDelegate.h"

// assume slightly over 1024 / 44
#define kMaxReusableCellsCount 25

@implementation NSIndexPath (BAGridView)

+ (NSIndexPath *)indexPathForColumn:(NSInteger)column inRow:(NSInteger)row inSection:(NSInteger)section {
	NSInteger indexes[] = { section, row, column };
	return [NSIndexPath indexPathWithIndexes:(NSUInteger *)indexes length:3];
}

- (NSInteger)gridColumn {
	return [self indexAtPosition:2];
}

- (NSInteger)gridRow {
	return [self indexAtPosition:1];
}

- (NSInteger)gridSection {
	return [self indexAtPosition:0];
}

@end


// Layout data for a section

@interface BAGridSectionData : NSObject

@property CGFloat y;
@property CGFloat headerHeight;
@property CGFloat footerHeight;
@property CGFloat totalHeight;
@property NSInteger numberOfRows;

- (CGFloat)yForRow:(NSInteger)row;
- (void)setY:(CGFloat)y forRow:(NSInteger)row;
- (CGFloat)heightForRow:(NSInteger)row;
- (void)setHeight:(CGFloat)height forRow:(NSInteger)row;

- (NSInteger)indexOfRowAtY:(CGFloat)y;

@end

@implementation BAGridSectionData {
@private
	NSInteger _numberOfRows;
	CGPoint *_rows; // x -> height
}

@synthesize y = _y;
@synthesize headerHeight = _headerHeight;
@synthesize footerHeight = _footerHeight;
@synthesize totalHeight = _totalHeight;

- (void)dealloc {
	if (_rows) {
		free(_rows);
	}
    [super dealloc];
}

- (NSInteger)numberOfRows {
	return _numberOfRows;
}

- (void)setNumberOfRows:(NSInteger)numberOfRows {
	if (_numberOfRows == numberOfRows) {
		return;
	}
	_numberOfRows = numberOfRows;
	free(_rows);
	if (numberOfRows > 0) {
		_rows = malloc(numberOfRows * sizeof(CGPoint));
	} else {
		_rows = NULL;
	}
}

- (CGFloat)yForRow:(NSInteger)row {
	if (row < 0 || row >= _numberOfRows) {
		return 0;
	}
	return _rows[row].y;
}

- (void)setY:(CGFloat)y forRow:(NSInteger)row {
	if (row < 0 || row >= _numberOfRows) {
		return;
	}
	_rows[row].y = y;
}

- (CGFloat)heightForRow:(NSInteger)row {
	if (row < 0 || row >= _numberOfRows) {
		return 0;
	}
	return _rows[row].x;
}

- (void)setHeight:(CGFloat)height forRow:(NSInteger)row {
	if (row < 0 || row >= _numberOfRows) {
		return;
	}
	_rows[row].x = height;
}

- (NSInteger)indexOfRowAtY:(CGFloat)y {
	// TODO: binary search
	for (NSInteger row = 0; row < self.numberOfRows; row++) {
		CGPoint p = _rows[row];
		if ((y > p.y) && (y < p.y + p.x)) {
			return row;
		}
	}
	return -1;
}

- (NSString *)description {
	NSMutableString *s = [NSMutableString string];
	[s appendFormat:@"<section data %g/%g/%g/%g", self.y, self.headerHeight, self.footerHeight, self.totalHeight];
	for (NSInteger i = 0; i < self.numberOfRows; i++) {
		[s appendFormat:@" %g:%g", [self yForRow:i], [self heightForRow:i]];
	}
	[s appendString:@">"];
	return s;
}

@end


// Views added for a section

@interface BAGridSectionViews : NSObject

@property(assign) BOOL hasHeader;
@property(retain) UIView *headerView;
@property(assign) BOOL hasFooter;
@property(retain) UIView *footerView;
@property(assign) NSInteger firstRow; // Index of the first row in the rows array
@property(readonly) NSMutableArray *rows;

- (void)removeViewsWithReusableCells:(NSMutableArray *)reusableCells;

@end

@implementation BAGridSectionViews {
@private
	NSMutableArray *_rows;
}

@synthesize hasHeader = _hasHeader;
@synthesize headerView = _headerView;
@synthesize hasFooter = _hasFooter;
@synthesize footerView = _footerView;
@synthesize firstRow = _firstRow;

- (void)dealloc {
	self.headerView = nil;
	self.footerView = nil;
	[_rows release];
    [super dealloc];
}

- (NSMutableArray *)rows {
	if (!_rows) {
		_rows = [[NSMutableArray alloc] init];
	}
	return _rows;
}

- (void)removeViewsWithReusableCells:(NSMutableArray *)reusableCells {
	if (self.headerView) {
		[self.headerView removeFromSuperview];
		self.headerView = nil;
	}
	for (NSArray *cells in self.rows) {
		for (BAGridViewCell *cell in cells) {
			[cell removeFromSuperview];
			if (cell.reuseIdentifier) {
				[cell prepareForReuse];
				[reusableCells addObject:cell];
			}
		}
	}
	[self.rows removeAllObjects];
	self.firstRow = -1;
	if (self.footerView) {
		[self.footerView removeFromSuperview];
		self.footerView = nil;
	}
}

@end


@interface BAGridViewProxyDelegate : BAScrollViewProxyDelegate

@property(assign) id<NSObject> didScrollTarget;
@property(assign) SEL didScrollAction;

@end


@implementation BAGridViewProxyDelegate

@synthesize didScrollTarget = _didScrollTarget;
@synthesize didScrollAction = _didScrollAction;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[super scrollViewDidScroll:scrollView];
	if (_didScrollTarget && _didScrollAction) {
		[_didScrollTarget performSelector:_didScrollAction];
	}
}

@end


@interface BAGridView ()

- (CGFloat)heightForRow:(NSInteger)row inSection:(NSInteger)section;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (CGFloat)heightForFooterInSection:(NSInteger)section;
- (void)gridDidScroll;

@end


@implementation BAGridView {
@private
	id<BAGridViewDataSource> _dataSource;
	BAGridViewProxyDelegate *_proxyDelegate; // retained; intercepts didScroll events
	NSMutableArray *_sectionData; // all data for layout
	NSMutableArray *_sectionViews; // description of currently added views
	NSMutableArray *_reusableCells;
}

@synthesize rowHeight = _rowHeight;
@synthesize sectionHeaderHeight = _sectionHeaderHeight;
@synthesize sectionFooterHeight = _sectionFooterHeight;

- (void)dealloc {
	[_proxyDelegate release];
	[_sectionData release];
	[_sectionViews release];
	[_reusableCells release];
    [super dealloc];
}

- (void)setupGridView {
	self.rowHeight = 44;
//	self.sectionHeaderHeight = 22;
//	self.sectionFooterHeight = 22;
	[_proxyDelegate release];
	_proxyDelegate = [[BAGridViewProxyDelegate alloc] init];
	_proxyDelegate.didScrollTarget = self;
	_proxyDelegate.didScrollAction = @selector(gridDidScroll);
	[super setDelegate:_proxyDelegate];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
		[self setupGridView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)rect {
    if ((self = [super initWithFrame:rect])) {
		[self setupGridView];
    }
    return self;
}

- (id<BAGridViewDataSource>)dataSource {
	return _dataSource;
}

- (void)setDataSource:(id<BAGridViewDataSource>)dataSource {
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

- (id<BAGridViewDelegate>)delegate {
	return (id<BAGridViewDelegate>)[_proxyDelegate delegate];
}

- (void)setDelegate:(id<BAGridViewDelegate>)delegate {
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
	while ([[self reusableCells] count] > kMaxReusableCellsCount) {
		[[self reusableCells] removeObjectAtIndex:0];
	}
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier {
	if (!identifier) {
		return nil;
	}
	for (NSInteger i = 0; i < [[self reusableCells] count]; i++) {
		BAGridViewCell *cell = [[self reusableCells] objectAtIndex:i];
		if ([[cell reuseIdentifier] isEqualToString:identifier]) {
			[[cell retain] autorelease];
			[[self reusableCells] removeObjectAtIndex:i];
			return cell;
		}
	}
	return nil;
}

- (NSMutableArray *)sectionData {
	if (!_sectionData) {
//		NSLog(@"%s", __func__);
		const NSInteger numberOfSections = [self numberOfSections];
		_sectionData = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		CGFloat y = 0;
		for (NSInteger section = 0; section < numberOfSections; section++) {
			BAGridSectionData *sectionData = [[[BAGridSectionData alloc] init] autorelease];
			sectionData.y = y;
			sectionData.headerHeight = [self heightForHeaderInSection:section];
			sectionData.footerHeight = [self heightForFooterInSection:section];
			sectionData.totalHeight = sectionData.headerHeight + sectionData.footerHeight;
			sectionData.numberOfRows = [self numberOfRowsInSection:section];
			y += sectionData.headerHeight;
			for (NSInteger row = 0; row < sectionData.numberOfRows; row++) {
				const CGFloat rowHeight = [self heightForRow:row inSection:section];
				[sectionData setY:y forRow:row];
				[sectionData setHeight:rowHeight forRow:row];
				y += rowHeight;
				sectionData.totalHeight += rowHeight;
			}
			[_sectionData addObject:sectionData];
//			NSLog(@"%@", sectionData);
			y += sectionData.footerHeight;
		}
		self.contentSize = CGSizeMake(self.bounds.size.width, y);
//		NSLog(@"Content Size %@", NSStringFromCGSize(self.contentSize));
	}
	return _sectionData;
}

- (NSMutableArray *)sectionViews {
	if (!_sectionViews) {
		const NSInteger numberOfSections = [self numberOfSections];
		_sectionViews = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		for (NSInteger section = 0; section < numberOfSections; section++) {
			BAGridSectionViews *sectionViews = [[[BAGridSectionViews alloc] init] autorelease];
			sectionViews.hasHeader = YES;
			sectionViews.hasFooter = YES;
			sectionViews.firstRow = -1;
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
		BAGridSectionData *sectionData = [[self sectionData] objectAtIndex:section];
		BAGridSectionViews *sectionViews = [[self sectionViews] objectAtIndex:section];
		const CGRect sectionRect = CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.totalHeight);
//		NSLog(@"Section Rect: %@", NSStringFromCGRect(sectionRect));
		if (CGRectIntersectsRect(contentRect, sectionRect)) {
			// section is (partially?) visible
			if (sectionViews.hasHeader) {
				CGRect headerRect = CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.headerHeight);
				if (CGRectIntersectsRect(contentRect, headerRect)) {
					if (!sectionViews.headerView) {
						if ([self.delegate respondsToSelector:@selector(gridView:viewForHeaderInSection:)]) {
							sectionViews.headerView = [self.delegate gridView:self viewForHeaderInSection:section];
						}
						if (sectionViews.headerView) {
							sectionViews.headerView.frame = headerRect;
							[self addSubview:sectionViews.headerView];
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
			NSMutableArray *rows = [[NSMutableArray alloc] initWithArray:sectionViews.rows];
			const NSInteger firstRow = sectionViews.firstRow;
			const NSInteger lastRow = (firstRow >= 0 && [rows count] > 0) ? firstRow + [rows count] - 1 : -1;
			[sectionViews.rows removeAllObjects];
			sectionViews.firstRow = -1;
			const NSInteger numberOfRows = [self numberOfRowsInSection:section];
			for (NSInteger row = 0; row < numberOfRows; row++) {
				NSMutableArray *cells = nil;
				if (row >= firstRow && row <= lastRow) {
					cells = [rows objectAtIndex:(row - firstRow)];
				}
				const CGFloat rowY = [sectionData yForRow:row];
				const CGFloat rowHeight = [sectionData heightForRow:row];
				const CGRect rowRect = CGRectMake(0, rowY, self.contentSize.width, rowHeight);
//				NSLog(@"Row Rect: %@", NSStringFromCGRect(rowRect));
				if (CGRectIntersectsRect(rowRect, contentRect)) {
					if (!cells) {
						const NSInteger numberOfColumns = [self numberOfColumnsInRow:row inSection:section];
						cells = [NSMutableArray arrayWithCapacity:numberOfColumns];
						CGFloat x = 0;
						for (NSInteger column = 0; column < numberOfColumns; column++) {
							NSIndexPath *indexPath = [NSIndexPath indexPathForColumn:column inRow:row inSection:section];
							BAGridViewCell *cell = [self.dataSource gridView:self cellAtIndexPath:indexPath];
							if (!cell) {
								[NSException raise:@"BAGridViewError" format:@"Failed to create a cell"];
							}
							CGRect cellRect = cell.frame;
							cellRect.origin.x = x;
							cellRect.origin.y = rowY;
							cellRect.size.height = rowHeight;
							cell.frame = cellRect;
//							NSLog(@"Cell Rect: %@", NSStringFromCGRect(cellRect));
							x += cellRect.size.width;
							[cells addObject:cell];
							[self addSubview:cell];
						}
					}
					if (sectionViews.firstRow < 0) {
						sectionViews.firstRow = row;
					}
					[sectionViews.rows addObject:cells];
				} else {
					if (cells) {
						for (BAGridViewCell *cell in cells) {
							[cell removeFromSuperview];
							if (cell.reuseIdentifier) {
								[cell prepareForReuse];
								[[self reusableCells] addObject:cell];
							}
						}
						[self compactReusableCells];
					}
				}
			}
			[rows release];
			if (sectionViews.hasFooter) {
				CGRect footerRect = CGRectMake(0, sectionData.y + sectionData.totalHeight - sectionData.footerHeight,
											   self.contentSize.width, sectionData.footerHeight);
				if (CGRectIntersectsRect(contentRect, footerRect)) {
					if (!sectionViews.footerView) {
						if ([self.delegate respondsToSelector:@selector(gridView:viewForFooterInSection:)]) {
							sectionViews.footerView = [self.delegate gridView:self viewForFooterInSection:section];
						}
						if (sectionViews.footerView) {
							sectionViews.footerView.frame = footerRect;
							[self addSubview:sectionViews.footerView];
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
	[self updateVisibleCells];
}

- (void)gridDidScroll {
	[self updateVisibleCells];
}

- (NSInteger)numberOfSections {
	if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)]) {
		return [self.dataSource numberOfSectionsInGridView:self];
	}
	return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
	return [self.dataSource gridView:self numberOfRowsInSection:section];
}

- (NSInteger)numberOfColumnsInRow:(NSInteger)row inSection:(NSInteger)section {
	return [self.dataSource gridView:self numberOfColumnsInRow:row inSection:section];
}

- (CGFloat)heightForRow:(NSInteger)row inSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(gridView:heightForRowAtIndexPath:)]) {
		return [self.delegate gridView:self heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
	}
	return self.rowHeight;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(gridView:heightForHeaderInSection:)]) {
		return [self.delegate gridView:self heightForHeaderInSection:section];
	}
	return self.sectionHeaderHeight;
}

- (CGFloat)heightForFooterInSection:(NSInteger)section {
	if ([self.delegate respondsToSelector:@selector(gridView:heightForFooterInSection:)]) {
		return [self.delegate gridView:self heightForFooterInSection:section];
	}
	return self.sectionFooterHeight;
}

- (CGRect)rectForSection:(NSInteger)section {
	BAGridSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.totalHeight);
}

- (CGRect)rectForHeaderInSection:(NSInteger)section {
	BAGridSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y, self.contentSize.width, sectionData.headerHeight);
}

- (CGRect)rectForFooterInSection:(NSInteger)section {
	BAGridSectionData *sectionData = [[self sectionData] objectAtIndex:section];
	return CGRectMake(0, sectionData.y + sectionData.totalHeight - sectionData.footerHeight, self.contentSize.width, sectionData.footerHeight);
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath {
	BAGridSectionData *sectionData = [[self sectionData] objectAtIndex:indexPath.gridSection];
	const CGFloat y = [sectionData yForRow:indexPath.gridRow];
	const CGFloat height = [sectionData heightForRow:indexPath.gridRow];
	return CGRectMake(0, y, self.contentSize.width, height);
}

- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point {
	return nil;
}

- (NSIndexPath *)indexPathForCell:(BAGridViewCell *)cell {
	return nil;
}

- (NSArray *)indexPathsForRowsInRect:(CGRect)rect {
	return nil;
}

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (NSArray *)visibleCells {
	return nil;
}

- (NSArray *)indexPathsForVisibleCells {
	return nil;
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
}

- (void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
}

// Selection

- (NSIndexPath *)indexPathForSelectedCell {
	return nil;
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
}

@end
