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

#import "BAFormProvider.h"

#define kMaxSectionCount 1024


@interface BAFormProvider (Private)

- (void)textFieldDidChange:(UITextField *)textField;

@end


@implementation BAFormProvider

@synthesize delegate = _delegate;

- (void)dealloc {
	[_model release];
	[_sectionDescriptors release];
	[super dealloc];
}

- (NSMutableDictionary *)model {
	if (!_model) {
		_model = [[NSMutableDictionary alloc] init];
	}
	return _model;
}

- (NSMutableArray *)sectionDescriptors {
	if (!_sectionDescriptors) {
		_sectionDescriptors = [[NSMutableArray alloc] init];
	}
	return _sectionDescriptors;
}

- (NSInteger)viewTagForField:(NSUInteger)fieldIndex inSection:(NSUInteger)sectionIndex {
	return fieldIndex + kMaxSectionCount * sectionIndex;
}

- (BAFormFieldDescriptor *)fieldDescriptorWithViewTag:(NSInteger)tag {
	if (tag < 0) {
		return nil;
	}
	const NSUInteger sectionIndex = tag / kMaxSectionCount;
	if (sectionIndex >= [self.sectionDescriptors count]) {
		return nil;
	}
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:sectionIndex];
	const NSUInteger fieldIndex = tag % kMaxSectionCount;
	if (fieldIndex >= [sectionDescriptor.fieldDescriptors count]) {
		return nil;
	}
	return [sectionDescriptor.fieldDescriptors objectAtIndex:fieldIndex];
}

- (NSString *)validate {
	for (BAFormSectionDescriptor *sd in self.sectionDescriptors) {
		for (BAFormFieldDescriptor *fd in sd.fieldDescriptors) {
			id fieldValue = [self.model objectForKey:fd.identifier];
			if (fd.validator) {
				NSString *error = fd.validator(fieldValue, fd, self.model);
				if (error) {
					return error;
				}
			}
		}
	}
	return nil;
}

- (BAFormFieldState)evalFieldState:(BAFormFieldDescriptor *)fieldDescriptor {
	BAFormFieldState state = BAFormFieldStateUnknown;
	id fieldValue = [self.model objectForKey:fieldDescriptor.identifier];
	if (fieldValue && fieldDescriptor.validator) {
		NSString *error = fieldDescriptor.validator(fieldValue, fieldDescriptor, self.model);
		state = error ? BAFormFieldStateInvalid : BAFormFieldStateValid;
	}
	return state;
}

- (void)updateFieldStates:(UITableView *)tableView {
	for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows]) {
		BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:indexPath.section];
		BAFormFieldDescriptor *fieldDescriptor = [sectionDescriptor.fieldDescriptors objectAtIndex:indexPath.row];
		BAFormFieldState state = [self evalFieldState:fieldDescriptor];
		BAFormLabelFieldCell *cell = (BAFormLabelFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
		cell.state = state;
	}
}

#pragma mark Table Support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.sectionDescriptors count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:section];
	return sectionDescriptor.header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:section];
	return sectionDescriptor.footer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:section];
	return [sectionDescriptor.fieldDescriptors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
				  cellForField:(BAFormFieldDescriptor *)fieldDescriptor
				   atIndexPath:(NSIndexPath *)indexPath
{
	
	switch (fieldDescriptor.type) {
		case BAFormFieldTypeLabel: {
			BAFormLabelFieldCell *cell = (BAFormLabelFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"BAFormLabelFieldCell"];
			if (!cell) {
				cell = [[[BAFormLabelFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
													reuseIdentifier:@"BAFormLabelFieldCell"] autorelease];
				if ([self.delegate respondsToSelector:@selector(decorateLabelFieldCell:descriptor:tableView:)]) {
					[self.delegate decorateLabelFieldCell:cell descriptor:fieldDescriptor tableView:tableView];
				}
			}
			cell.nameLabel.text = fieldDescriptor.name;
			NSString *text = [self.model objectForKey:fieldDescriptor.identifier];
			cell.fieldLabel.text = text;
			cell.state = [self evalFieldState:fieldDescriptor];
			return cell;
		}
		case BAFormFieldTypeText: {
			BAFormTextFieldCell *cell = (BAFormTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"BAFormTextFieldCell"];
			if (!cell) {
				cell = [[[BAFormTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
												   reuseIdentifier:@"BAFormTextFieldCell"] autorelease];
				[cell.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
				if ([self.delegate respondsToSelector:@selector(decorateTextFieldCell:descriptor:tableView:)]) {
					[self.delegate decorateTextFieldCell:cell descriptor:fieldDescriptor tableView:tableView];
				}
			}
			cell.nameLabel.text = fieldDescriptor.name;
			cell.textField.text = fieldDescriptor.placeholder;
			cell.textField.textAlignment = fieldDescriptor.textAlignment;
			cell.textField.autocapitalizationType = fieldDescriptor.autocapitalizationType;
			cell.textField.autocorrectionType = fieldDescriptor.autocorrectionType;
			cell.textField.keyboardType = fieldDescriptor.keyboardType;
			cell.textField.keyboardAppearance = fieldDescriptor.keyboardAppearance;
			cell.textField.returnKeyType = fieldDescriptor.returnKeyType;
			cell.textField.enablesReturnKeyAutomatically = fieldDescriptor.enablesReturnKeyAutomatically;
			cell.textField.secureTextEntry = fieldDescriptor.secureTextEntry;
			NSString *text = [self.model objectForKey:fieldDescriptor.identifier];
			cell.textField.text = text;
			cell.textField.placeholder = fieldDescriptor.placeholder;
			cell.textField.delegate = self;
			cell.textField.tag = [self viewTagForField:indexPath.row inSection:indexPath.section];
			cell.state = [self evalFieldState:fieldDescriptor];
			return cell;
		}
		case BAFormFieldTypeButton: {
			BAFormButtonFieldCell *cell = (BAFormButtonFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"BAFormButtonFieldCell"];
			if (!cell) {
				cell = [[[BAFormButtonFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
													 reuseIdentifier:@"BAFormButtonFieldCell"] autorelease];
				if ([self.delegate respondsToSelector:@selector(decorateButtonFieldCell:descriptor:tableView:)]) {
					[self.delegate decorateButtonFieldCell:cell descriptor:fieldDescriptor tableView:tableView];
				}
			}
			cell.nameLabel.text = fieldDescriptor.name;
			[cell.fieldButton setTitle:fieldDescriptor.placeholder forState:UIControlStateNormal];
			cell.state = [self evalFieldState:fieldDescriptor];
			return cell;
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:indexPath.section];
	BAFormFieldDescriptor *fieldDescriptor = [sectionDescriptor.fieldDescriptors objectAtIndex:indexPath.row];
	return [self tableView:tableView cellForField:fieldDescriptor atIndexPath:indexPath];
}

#pragma mark -
#pragma mark Text Field Support

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
	BAFormFieldDescriptor *fieldDescriptor = [self fieldDescriptorWithViewTag:textField.tag];
	if (!fieldDescriptor) {
		return;
	}
	NSString *fieldValue = textField.text;
	if ([fieldValue length] > 0) {
		[self.model setObject:fieldValue forKey:fieldDescriptor.identifier];
	} else {
		[self.model removeObjectForKey:fieldDescriptor.identifier];
	}
	if ([self.delegate respondsToSelector:@selector(formProvider:fieldDidChange:)]) {
		[self.delegate formProvider:self fieldDidChange:fieldDescriptor];
	}
}

@end
