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

#import "BAFormInputSupport.h"


@implementation BAFormInputSupport

@synthesize provider = _provider;
@synthesize tableView = _tableView;

- (void)dealloc {
	[_provider release];
	[_tableView release];
	[super dealloc];
}

- (void)decorateTextFieldCell:(BAFormTextFieldCell *)cell
				   descriptor:(BAFormFieldDescriptor *)descriptor
					tableView:(UITableView *)tableView
{
	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)];
	toolbar.barStyle = UIBarStyleBlackTranslucent;
	toolbar.translucent = YES;
	UIBarButtonItem *prevButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"field-prev.png"]
																	style:UIBarButtonItemStyleBordered
																   target:self
																   action:@selector(selectPrevField)] autorelease];
	UIBarButtonItem *nextButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"field-next.png"]
																	style:UIBarButtonItemStyleBordered
																   target:self
																   action:@selector(selectNextField)] autorelease];
	prevButton.width = nextButton.width = 50;
	UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			 target:nil
																			 action:NULL] autorelease];
	UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self
																				 action:@selector(finishEditing)] autorelease];
	toolbar.items = [NSArray arrayWithObjects:prevButton, nextButton, spacer, doneButton, nil];
	cell.textField.inputAccessoryView = toolbar;
}

- (void)activateTextFieldAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	if (cell && [cell isKindOfClass:[BAFormTextFieldCell class]]) {
		BAFormTextFieldCell *textCell = (BAFormTextFieldCell *)cell;
		[textCell.textField becomeFirstResponder];
	}
}

- (void)selectTextFieldAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView scrollToRowAtIndexPath:indexPath
						  atScrollPosition:UITableViewScrollPositionNone
								  animated:YES];
	[self performSelector:@selector(activateTextFieldAtIndexPath:) withObject:indexPath afterDelay:0.2];
}

- (NSIndexPath *)prevField:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	row--;
	if (row < 0) {
		section--;
		if (section < 0) {
			section = [self.provider.sectionDescriptors count] - 1;
		}
		BAFormSectionDescriptor *sectionDescriptor = [self.provider.sectionDescriptors objectAtIndex:section];
		row = [sectionDescriptor.fieldDescriptors count] - 1;
	}
	return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSIndexPath *)nextField:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	BAFormSectionDescriptor *sectionDescriptor = [self.provider.sectionDescriptors objectAtIndex:section];
	row++;
	if (row >= [sectionDescriptor.fieldDescriptors count]) {
		section++;
		if (section >= [self.provider.sectionDescriptors count]) {
			section = 0;
		}
		row = 0;
	}
	return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)selectPrevField {
	NSIndexPath *activeIndexPath = self.provider.activeIndexPath;
	if (!activeIndexPath) {
		return;
	}
	for (NSIndexPath *indexPath = [self prevField:activeIndexPath];
		 indexPath != activeIndexPath;
		 indexPath = [self prevField:indexPath])
	{
		BAFormSectionDescriptor *sectionDescriptor = [self.provider.sectionDescriptors objectAtIndex:indexPath.section];
		BAFormFieldDescriptor *fieldDescriptor = [sectionDescriptor.fieldDescriptors objectAtIndex:indexPath.row];
		if (fieldDescriptor.type == BAFormFieldTypeText) {
			[self selectTextFieldAtIndexPath:indexPath];
			break;
		}
	}
}

- (void)selectNextField {
	NSIndexPath *activeIndexPath = self.provider.activeIndexPath;
	if (!activeIndexPath) {
		return;
	}
	for (NSIndexPath *indexPath = [self nextField:activeIndexPath];
		 indexPath != activeIndexPath;
		 indexPath = [self nextField:indexPath])
	{
		BAFormSectionDescriptor *sectionDescriptor = [self.provider.sectionDescriptors objectAtIndex:indexPath.section];
		BAFormFieldDescriptor *fieldDescriptor = [sectionDescriptor.fieldDescriptors objectAtIndex:indexPath.row];
		if (fieldDescriptor.type == BAFormFieldTypeText) {
			[self selectTextFieldAtIndexPath:indexPath];
			break;
		}
	}
}

- (void)finishEditing {
	NSIndexPath *indexPath = self.provider.activeIndexPath;
	if (!indexPath) {
		return;
	}
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	if (cell && [cell isKindOfClass:[BAFormTextFieldCell class]]) {
		BAFormTextFieldCell *textCell = (BAFormTextFieldCell *)cell;
		[textCell.textField resignFirstResponder];
	}
}

@end
