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

#import "BAFormFieldDescriptor.h"

@implementation BAFormFieldDescriptor

@synthesize identifier = _identifier;
@synthesize name = _name;
@synthesize type = _type;
@synthesize placeholder = _placeholder;
@synthesize textAlignment = _textAlignment;
@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;
@synthesize keyboardType = _keyboardType;
@synthesize keyboardAppearance = _keyboardAppearance;
@synthesize returnKeyType = _returnKeyType;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize validator = _validator;

- (void)dealloc {
	[_identifier release];
	[_name release];
	[_placeholder release];
	[_validator release];
	[super dealloc];
}

- (id)init {
    if ((self = [super init])) {
		_type = BAFormFieldTypeText;
		_textAlignment = UITextAlignmentLeft;
		_autocapitalizationType = UITextAutocapitalizationTypeSentences;
		_autocorrectionType = UITextAutocorrectionTypeDefault;
		_keyboardType = UIKeyboardTypeDefault;
		_keyboardAppearance = UIKeyboardAppearanceDefault;
		_returnKeyType = UIReturnKeyDefault;
		_enablesReturnKeyAutomatically = NO;
		_secureTextEntry = NO;
    }
    return self;
}

- (void)useRegexpValidator:(NSString *)regexp withErrorMessage:(NSString *)error {
	_validator = [^NSString *(id fieldValue, BAFormFieldDescriptor *fieldDescriptor, NSDictionary *formModel) {
		if (!fieldValue || ![fieldValue isKindOfClass:[NSString class]]) {
			return error;
		}
		NSString *fieldText = (NSString *)fieldValue;
		NSRegularExpression *regexpObject = [NSRegularExpression regularExpressionWithPattern:regexp
																					  options:0
																						error:NULL];
		NSRange range = [regexpObject rangeOfFirstMatchInString:fieldValue
														options:0
														  range:NSMakeRange(0, [fieldText length])];
		if (range.location == NSNotFound || range.length != [fieldText length]) {
			return error;
		}
		return nil;
	} retain];
}

@end
