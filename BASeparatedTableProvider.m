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

#import "BASeparatedTableProvider.h"

@implementation BASeparatedTableProvider

- (id<BASeparatedTableProviderDelegate>)delegate {
	return (id<BASeparatedTableProviderDelegate>)[super delegate];
}

- (void)setDelegate:(id<BASeparatedTableProviderDelegate>)delegate {
	[super setDelegate:delegate];
}

- (NSIndexPath *)separatedIndexPathForIndexPath:(NSIndexPath *)indexPath {
	return [NSIndexPath indexPathForRow:((indexPath.row * 3) + 1) inSection:indexPath.section];
}

- (NSArray *)separatedIndexPathsForIndexPaths:(NSArray *)indexPaths {
	if (!indexPaths) {
		return nil;
	}
	NSMutableArray *separatedIndexPaths = [NSMutableArray arrayWithCapacity:([indexPaths count] * 3)];
	for (NSIndexPath *indexPath in indexPaths) {
		[separatedIndexPaths addObject:[NSIndexPath indexPathForRow:((indexPath.row * 3) + 0) inSection:indexPath.section]];
		[separatedIndexPaths addObject:[NSIndexPath indexPathForRow:((indexPath.row * 3) + 1) inSection:indexPath.section]];
		[separatedIndexPaths addObject:[NSIndexPath indexPathForRow:((indexPath.row * 3) + 2) inSection:indexPath.section]];
	}
	return separatedIndexPaths;
}



// Table Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rowsCount = [self.delegate tableView:tableView numberOfRowsInSection:section];
	return rowsCount * 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.row % 3) {
		case 0: return [self.delegate tableView:tableView topSeparatorCellForRowAtIndexPath:indexPath];
		case 1: return [self.delegate tableView:tableView
						  cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.row / 3) inSection:indexPath.section]];
		case 2: return [self.delegate tableView:tableView bottomSeparatorCellForRowAtIndexPath:indexPath];
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([self.delegate respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
		return [self.delegate numberOfSectionsInTableView:tableView];
	}
	return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	if ([self.delegate respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
//		return [self.delegate tableView:tableView titleForHeaderInSection:section];
//	}
//	return nil;
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//	if ([self.delegate respondsToSelector:@selector(tableView:titleForFooterInSection:)]) {
//		return [self.delegate tableView:tableView titleForFooterInSection:section];
//	}
//	return nil;
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.row % 3 == 1) && [self.delegate respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
		return [self.delegate tableView:tableView
				  canEditRowAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.row / 3) inSection:indexPath.section]];
	}
	return NO;
}

//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView;

//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.row % 3 == 1) && [self.delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
		[self.delegate tableView:tableView
			  commitEditingStyle:editingStyle
			   forRowAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.row / 3) inSection:indexPath.section]];
	}
}

//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;



// Table Delegate

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.row % 3) {
		case 0: {
			BACellSeparatorPositions positions = [self.delegate tableView:tableView separatorPositionsForRow:indexPath];
			if (positions & BACellSeparatorPositionTop) {
				return [self.delegate tableView:tableView heightForTopSeparatorRowAtIndexPath:indexPath];
			}
			return 0;
		}
		case 1: 
			if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
				return [self.delegate tableView:tableView
						heightForRowAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.row / 3) inSection:indexPath.section]];
			}
			return 0;
		case 2: {
			BACellSeparatorPositions positions = [self.delegate tableView:tableView separatorPositionsForRow:indexPath];
			if (positions & BACellSeparatorPositionBottom) {
				return [self.delegate tableView:tableView heightForBottomSeparatorRowAtIndexPath:indexPath];
			}
			return 0;
		}
	}
	return 0;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;

//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath;

//- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
//- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ((indexPath.row % 3 == 1) && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
		[self.delegate tableView:tableView
		 didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.row / 3) inSection:indexPath.section]];
	}
}

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
//- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;

//- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;

//- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath;
//- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath;

//- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;               

//- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath;

//- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath;
//- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
//- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;

@end
