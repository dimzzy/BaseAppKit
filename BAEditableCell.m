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

#import "BAEditableCell.h"

static const CGFloat kTextFieldDefaultX = 120;

@implementation BAEditableCell

@synthesize textField, textFieldX;

- (void)dealloc {
	self.textField = nil;
	[super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
		self.textField.autoresizingMask = self.detailTextLabel.autoresizingMask;
		self.textField.font = [UIFont systemFontOfSize:17];
		self.textField.textColor = self.detailTextLabel.textColor;
		[self.contentView addSubview:self.textField];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	const CGFloat width = self.contentView.bounds.size.width;
	const CGFloat height = self.contentView.bounds.size.height;
	const CGFloat textX = self.textFieldX > 0 ? self.textFieldX : kTextFieldDefaultX;
	const CGFloat textHeight = self.textLabel.bounds.size.height;
	const CGFloat spacing = self.textLabel.frame.origin.x;
	self.textField.frame = CGRectMake(spacing + textX, (height - textHeight) / 2,
									  (width - textX - spacing - spacing), textHeight);
}

+ (void)stopEditing:(UITableView *)tableView {
	NSArray *cells = [[[tableView visibleCells] copy] autorelease];
	if ([cells count] == 0) {
		return;
	}
	for (UITableViewCell *cell in cells) {
		if ([cell isKindOfClass:[BAEditableCell class]]) {
			BAEditableCell *editableCell = (BAEditableCell *)cell;
			[editableCell.textField resignFirstResponder];
		}
	}
}

@end
