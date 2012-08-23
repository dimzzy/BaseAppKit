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

// Based on Reachability sample project

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

extern NSString * const BANetworkReachabilityDidChangeNotification;

typedef enum {
	BANetworkNotReachable = 0,
	BANetworkReachableViaWiFi,
	BANetworkReachableViaWWAN
} BANetworkStatus;

@interface BANetworkReachability : NSObject

// Use to check the reachability of a particular host name.
+ (BANetworkReachability *)reachabilityWithHostName:(NSString *)hostName;

// Use to check the reachability of a particular IP address.
+ (BANetworkReachability *)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

// Checks whether the default route is available.
// Should be used by applications that do not connect to a particular host.
+ (BANetworkReachability *)reachabilityForInternetConnection;

// Checks whether a local wifi connection is available.
+ (BANetworkReachability *)reachabilityForLocalWiFi;

// Start listening for reachability notifications on the current run loop.
- (BOOL)start;

// Stop listening for reachability notifications on the current run loop.
- (void)stop;

@property(nonatomic, readonly) BANetworkStatus currentStatus;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
@property(nonatomic, readonly) BOOL connectionRequired;

- (SCNetworkReachabilityFlags)flags;

- (NSString *)flagsString;

@end
