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

@implementation BAFormProvider

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

- (void)decorateLabelFieldCell:(BAFormLabelFieldCell *)cell {
}

- (void)decorateTextFieldCell:(BAFormTextFieldCell *)cell {
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForField:(BAFormFieldDescriptor *)fieldDescriptor {
	switch (fieldDescriptor.type) {
		case BAFormFieldTypeLabel: {
			BAFormLabelFieldCell *cell = (BAFormLabelFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"BAFormLabelFieldCell"];
			if (!cell) {
				cell = [[[BAFormLabelFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
													reuseIdentifier:@"BAFormLabelFieldCell"] autorelease];
				[self decorateLabelFieldCell:cell];
			}
			cell.nameLabel.text = fieldDescriptor.name;
			NSString *text = [self.model objectForKey:fieldDescriptor.identifier];
			cell.fieldLabel.text = text;
			return cell;
		}
		case BAFormFieldTypeText: {
			BAFormTextFieldCell *cell = (BAFormTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"BAFormTextFieldCell"];
			if (!cell) {
				cell = [[[BAFormTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
												   reuseIdentifier:@"BAFormTextFieldCell"] autorelease];
				[self decorateTextFieldCell:cell];
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
			return cell;
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	BAFormSectionDescriptor *sectionDescriptor = [self.sectionDescriptors objectAtIndex:indexPath.section];
	BAFormFieldDescriptor *fieldDescriptor = [sectionDescriptor.fieldDescriptors objectAtIndex:indexPath.row];
	return [self tableView:tableView cellForField:fieldDescriptor];
}

#pragma mark -
#pragma mark Text Field Support

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
