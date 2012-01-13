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

// Day is an NSDate object at this time, which allows NSDate objects to be used as hash keys
#define kBADayHour 12

@interface NSDate (BADays)

- (NSDate *)nextDay;
- (NSDate *)nextDayInCalendar:(NSCalendar *)calendar;
- (NSDate *)prevDay;
- (NSDate *)prevDayInCalendar:(NSCalendar *)calendar;
- (NSDate *)currDay;
- (NSDate *)currDayInCalendar:(NSCalendar *)calendar;
- (BOOL)sameDay:(NSDate *)anotherDate;
- (BOOL)sameDay:(NSDate *)anotherDate inCalendar:(NSCalendar *)calendar;
- (NSInteger)daysSinceNow;
- (NSInteger)daysSinceNowInCalendar:(NSCalendar *)calendar;
- (NSInteger)currHour;
- (NSInteger)currHourInCalendar:(NSCalendar *)calendar;

@end
