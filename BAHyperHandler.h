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

#import <Foundation/Foundation.h>
#import "BAHyperParser.h"

@interface BAHyperHandler : NSObject <BAHyperParserDelegate> {
@private
	NSString *_currentElementName;
	NSMutableString *_currentText;
	NSMutableDictionary *_elementTrackersByHandle; // handle -> tracker
	NSMutableDictionary *_elementTrackersByName; // name -> tracker[]
	NSMutableDictionary *_elementLevels; // name -> tracker
}

@property(readonly) NSString *currentElementName;

- (void)parseString:(NSString *)str;
- (void)parse:(NSData *)data;
- (void)parse:(NSData *)data usingEncoding:(NSStringEncoding)encoding;

- (void)trackElement:(NSString *)handle
				name:(NSString *)name
			CSSClass:(NSString *)CSSClass
		  identifier:(NSString *)identifier
			 onStart:(SEL)onStart
			   onEnd:(SEL)onEnd;
- (BOOL)parsing:(NSString *)handle;
- (void)enableBuffer;
- (void)disableBuffer;
- (void)appendText:(NSString *)text;
- (NSString *)bufferText;

@end
