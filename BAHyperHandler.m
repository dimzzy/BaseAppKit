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

#import "BAHyperHandler.h"

@interface BAElementTracker : NSObject {
@private
	NSString *_handle;
	NSString *_name;
	NSString *_CSSClass;
	NSString *_identifier;
	SEL _onStart;
	SEL _onEnd;
	int _level;
}

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *CSSClass;
@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, readonly) NSString *handle;
@property(nonatomic, readonly) SEL onStart;
@property(nonatomic, readonly) SEL onEnd;
@property(nonatomic, assign) int level;

- (id)initWithHandle:(NSString *)handle
				name:(NSString *)name
			CSSClass:(NSString *)CSSClass
		  identifier:(NSString *)identifier
			 onStart:(SEL)onStart
			   onEnd:(SEL)onEnd;
- (BOOL)hasCSSClass:(NSString *)CSSClass;
- (BOOL)hasIdentifier:(NSString *)identifier;

@end

@implementation BAElementTracker

@synthesize handle = _handle;
@synthesize name = _name;
@synthesize CSSClass = _CSSClass;
@synthesize identifier = _identifier;
@synthesize onStart = _onStart;
@synthesize onEnd = _onEnd;
@synthesize level = _level;

- (id)initWithHandle:(NSString *)handle
				name:(NSString *)name
			CSSClass:(NSString *)CSSClass
		  identifier:(NSString *)identifier
			 onStart:(SEL)onStart
			   onEnd:(SEL)onEnd
{
	if ((self = [super init])) {
		_handle = [handle retain];
		_name = [name retain];
		_CSSClass = [CSSClass retain];
		_identifier = [identifier retain];
		_onStart = onStart;
		_onEnd = onEnd;
		_level = -1;
	}
	return self;
}

- (void)dealloc {
	[_handle release];
	[_name release];
	[_CSSClass release];
	[_identifier release];
	[super dealloc];
}

- (BOOL)hasCSSClass:(NSString *)CSSClass {
	if (_CSSClass) {
		return [@"*" isEqualToString:_CSSClass] || [_CSSClass isEqualToString:CSSClass];
	}
	return !CSSClass;
}

- (BOOL)hasIdentifier:(NSString *)identifier {
	if (_identifier) {
		return [@"*" isEqualToString:_identifier] || [_identifier isEqualToString:identifier];
	}
	return !identifier;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@> %@[%@ %@] %d", _handle, _name, _CSSClass, _identifier, _level];
}

@end

@implementation BAHyperHandler

@synthesize currentElementName = _currentElementName;

- (id)init {
	if ((self = [super init])) {
		_elementTrackersByHandle = [[NSMutableDictionary alloc] init];
		_elementTrackersByName = [[NSMutableDictionary alloc] init];
		_elementLevels = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_elementTrackersByHandle release];
	[_elementTrackersByName release];
	[_elementLevels release];
	[_currentText release];
	[_currentElementName release];
	[super dealloc];
}

- (void)trackElement:(NSString *)handle
				name:(NSString *)name
			CSSClass:(NSString *)CSSClass
		  identifier:(NSString *)identifier
			 onStart:(SEL)onStart
			   onEnd:(SEL)onEnd
{
	BAElementTracker *tracker = [[[BAElementTracker alloc] initWithHandle:handle
																	 name:name
																 CSSClass:CSSClass
															   identifier:identifier
																  onStart:onStart
																	onEnd:onEnd] autorelease];
	[_elementTrackersByHandle setObject:tracker forKey:handle];
	NSMutableArray *trackers = [_elementTrackersByName objectForKey:name];
	if (!trackers) {
		trackers = [NSMutableArray arrayWithCapacity:3];
		[_elementTrackersByName setObject:trackers forKey:name];
	}
	[trackers addObject:tracker];

	if (![_elementLevels objectForKey:name]) {
		BAElementTracker *levelTracker = [[[BAElementTracker alloc] initWithHandle:nil
																			  name:nil
																		  CSSClass:nil
																		identifier:nil
																		   onStart:NULL
																			 onEnd:NULL] autorelease];
		[_elementLevels setObject:levelTracker forKey:name];
	}
}

- (BOOL)parsing:(NSString *)handle {
	BAElementTracker *tracker = [_elementTrackersByHandle objectForKey:handle];
	return tracker && tracker.level >= 0;
}

- (void)enableBuffer {
	[_currentText release];
	_currentText = [[NSMutableString stringWithCapacity:20] retain];
}

- (void)disableBuffer {
	[_currentText release];
	_currentText = nil;
}

- (void)appendText:(NSString *)text {
	[_currentText appendString:text];
}

- (NSString *)bufferText {
	return _currentText ? [_currentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
}

- (void)parser:(BAHyperParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
	[_currentElementName release];
	_currentElementName = [elementName retain];

	BAElementTracker *levelTracker = [_elementLevels objectForKey:elementName];
	if (levelTracker) {
		levelTracker.level++;
		NSArray *trackers = [_elementTrackersByName objectForKey:elementName];
		if (trackers) {
			NSString *cssClass = [attributeDict objectForKey:@"class"];
			NSString *identifier = [attributeDict objectForKey:@"id"];
			for (BAElementTracker *tracker in trackers) {
				if ([tracker hasCSSClass:cssClass] && [tracker hasIdentifier:identifier]) {
					tracker.level = levelTracker.level;
					if (tracker.onStart) {
						[self performSelector:tracker.onStart withObject:parser withObject:attributeDict];
					}
				}
			}
		}
	}
}

- (void)parser:(BAHyperParser *)parser didEndElement:(NSString *)elementName {
	BAElementTracker *levelTracker = [_elementLevels objectForKey:elementName];
	if (levelTracker) {
		NSArray *trackers = [_elementTrackersByName objectForKey:elementName];
		if (trackers) {
			for (BAElementTracker *tracker in trackers) {
				if (tracker.level == levelTracker.level) {
					if (tracker.onEnd) {
						[self performSelector:tracker.onEnd withObject:parser];
					}
					tracker.level = -1;
				}
			}
		}
		if (levelTracker.level >= 0) {
			levelTracker.level--;
		}
	}

	[_currentElementName release];
	_currentElementName = nil;
}

- (void)parser:(BAHyperParser *)parser foundCharacters:(NSString *)string {
	[self appendText:string];
}

- (void)parse:(NSData *)data {
	[self parse:data usingEncoding:NSISOLatin1StringEncoding];
}

- (void)parse:(NSData *)data usingEncoding:(NSStringEncoding)encoding {
	NSString *string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	if (string) {
		[self parseString:string];
	}
}

- (void)parseString:(NSString *)string {
	BAHyperParser *parser = [[BAHyperParser alloc] initWithString:string];
	if (parser) {
		parser.delegate = self;
		[parser parse];
		[parser release];
	}
}

@end
