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

#import "NSDate+BADays.h"

@implementation NSDate (BADays)

- (NSDate *)nextDay {
	return [self nextDayInCalendar:[NSCalendar currentCalendar]];
}

- (NSDate *)nextDayInCalendar:(NSCalendar *)calendar {
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	[components setDay:1];
	return [calendar dateByAddingComponents:components toDate:self options:0];
}

- (NSDate *)prevDay {
	return [self prevDayInCalendar:[NSCalendar currentCalendar]];
}

- (NSDate *)prevDayInCalendar:(NSCalendar *)calendar {
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	[components setDay:-1];
	return [calendar dateByAddingComponents:components toDate:self options:0];
}

- (NSDate *)currDay {
	return [self currDayInCalendar:[NSCalendar currentCalendar]];
}

- (NSDate *)currDayInCalendar:(NSCalendar *)calendar {
	const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
	if (!components) {
		return self;
	}
	[components setHour:kBADayHour];
	NSDate *day = [calendar dateFromComponents:components];
	if (!day) {
		return self;
	}
	return day;
}

- (BOOL)sameDay:(NSDate *)anotherDate {
	return [self sameDay:anotherDate inCalendar:[NSCalendar currentCalendar]];
}

- (BOOL)sameDay:(NSDate *)anotherDate inCalendar:(NSCalendar *)calendar {
	if (!anotherDate) {
		return NO;
	}
	const unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *c1 = [calendar components:unitFlags fromDate:self];
	NSDateComponents *c2 = [calendar components:unitFlags fromDate:anotherDate];
	if (!c1 || !c2) {
		return NO;
	}
	return [c1 year] == [c2 year] && [c1 month] == [c2 month] && [c1 day] == [c2 day];
}

- (NSInteger)daysSinceNow {
	return [self daysSinceNowInCalendar:[NSCalendar currentCalendar]];
}

- (NSInteger)daysSinceNowInCalendar:(NSCalendar *)calendar {
	NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:[NSDate date] toDate:self options:0];
	return [components day];
}

- (NSInteger)currHour {
	return [self currHourInCalendar:[NSCalendar currentCalendar]];
}

- (NSInteger)currHourInCalendar:(NSCalendar *)calendar {
	NSDateComponents *components = [calendar components:NSHourCalendarUnit fromDate:self];
	return [components hour];
}

@end
