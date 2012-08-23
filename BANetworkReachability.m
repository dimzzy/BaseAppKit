/*
 Copyright 2012 Dmitry Stadnik. All rights reserved.

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

#import "BANetworkReachability.h"
#import <sys/socket.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <CoreFoundation/CoreFoundation.h>

NSString * const BANetworkReachabilityDidChangeNotification = @"BANetworkReachabilityDidChange";

static void BANetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
	// We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someone uses the BANetworkReachability object in a different thread.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BANetworkReachability *reachability = (BANetworkReachability *)info;
	[[NSNotificationCenter defaultCenter] postNotificationName:BANetworkReachabilityDidChangeNotification
														object:reachability];
	[pool release];
}

@implementation BANetworkReachability {
	SCNetworkReachabilityRef _reachabilityRef;
	BOOL _localWiFiRef;
	BOOL _started;
}

- (void)dealloc {
	[self stop];
	if (_reachabilityRef) {
		CFRelease(_reachabilityRef);
	}
	[super dealloc];
}

- (id)initWithRef:(SCNetworkReachabilityRef)reachabilityRef /*retained*/ localWiFi:(BOOL)localWiFiRef {
	if ((self = [super init])) {
		_reachabilityRef = reachabilityRef;
		_localWiFiRef = localWiFiRef;
	}
	return self;
}

+ (BANetworkReachability *)reachabilityWithHostName:(NSString *)hostName {
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
	return reachabilityRef ? [[[BANetworkReachability alloc] initWithRef:reachabilityRef localWiFi:NO] autorelease] : nil;
}

+ (BANetworkReachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress {
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);
	return reachabilityRef ? [[[BANetworkReachability alloc] initWithRef:reachabilityRef localWiFi:NO] autorelease] : nil;
}

+ (BANetworkReachability *)reachabilityForInternetConnection {
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	return [self reachabilityWithAddress:&zeroAddress];
}

+ (BANetworkReachability *)reachabilityForLocalWiFi {
	struct sockaddr_in localWifiAddress;
	bzero(&localWifiAddress, sizeof(localWifiAddress));
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	BANetworkReachability *retVal = [self reachabilityWithAddress:&localWifiAddress];
	if (retVal) {
		retVal->_localWiFiRef = YES;
	}
	return retVal;
}

- (void)stop {
	if (_reachabilityRef && _started) {
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		_started = NO;
	}
}

- (BOOL)start {
	if (_started) {
		return YES;
	}
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	return _started = SCNetworkReachabilitySetCallback(_reachabilityRef, BANetworkReachabilityCallback, &context) &&
	SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (BANetworkStatus)currentStatus {
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return BANetworkNotReachable;
	}
	return _localWiFiRef ? [self localWiFiStatusForFlags:flags] : [self networkStatusForFlags:flags];
}

- (BANetworkStatus)localWiFiStatusForFlags:(SCNetworkReachabilityFlags)flags {
	BOOL retVal = BANetworkNotReachable;
	if ((flags & kSCNetworkReachabilityFlagsReachable) &&
		(flags & kSCNetworkReachabilityFlagsIsDirect))
	{
		retVal = BANetworkReachableViaWiFi;
	}
	return retVal;
}

- (BANetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
		return BANetworkNotReachable;
	}

	BOOL retVal = BANetworkNotReachable;

	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
		// If target host is reachable and no connection is required
		// then we'll assume (for now) that your on Wi-Fi
		retVal = BANetworkReachableViaWiFi;
	}

	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
		 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
		// ... and the connection is on-demand (or on-traffic) if the
		// calling application is using the CFSocketStream or higher APIs
		if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
			// ... and no [user] intervention is needed
			retVal = BANetworkReachableViaWiFi;
		}
	}

	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
		// ... but WWAN connections are OK if the calling application
		// is using the CFNetwork (CFSocketStream?) APIs.
		retVal = BANetworkReachableViaWWAN;
	}
	return retVal;
}

- (BOOL)connectionRequired; {
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
	}
	return NO;
}

- (SCNetworkReachabilityFlags)flags {
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return flags;
	}
	return 0;
}

- (NSString *)flagsString {
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
				(flags & kSCNetworkReachabilityFlagsIsWWAN)				  ? 'W' : '-',
				(flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
				(flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
				(flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
				(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
				(flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
				(flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
				(flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
				(flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
	}
	return @"";
}

@end
