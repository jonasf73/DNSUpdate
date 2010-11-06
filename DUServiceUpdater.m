//
//  DUServiceUpdater.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUServiceUpdater.h"
#import "DUUser.h"
#import "DUHost.h"
#import "DUInterface.h"

NSString *authorMail=@"support@dnsupdate.org";

NSMutableDictionary *_updaters=nil;

@implementation DUServiceUpdater

+ (void)registerServiceUpdater:(DUServiceUpdater *)theUpdater {
    [DUServiceUpdater serviceUpdaters];
    [_updaters setObject:theUpdater forKey:[theUpdater getServiceName]];
    NSLog(@"Registering service %@",[theUpdater getServiceName]);
}

+ (NSDictionary *)serviceUpdaters {
    if(_updaters==nil) {
        _updaters=[[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return _updaters;
}

+ (DUServiceUpdater *)getServiceUpdaterFor:(NSString *)theName {
    return [_updaters objectForKey:theName];
}

+ (void)registerService
{
    [DUServiceUpdater registerServiceUpdater:[[[self alloc] init] autorelease]];
}

- (NSString *)getServiceName {
    return nil;
}

- description {
    return [self getServiceName];
}

- (void)updateUser:(DUUser *)theUser {
    [theUser saveUser];
}

- (BOOL)needUpdate:(DUHost *)theHost {
    BOOL isIPUpToDate = [[[theHost interface] getAddress] isEqualToString:[theHost getAddress]];
    if(([theHost isActive]) && (!isIPUpToDate) && ([[theHost interface] isActive])) {
        return YES;
    }
    if(isIPUpToDate && [[theHost interface] isActive]) {
        [theHost setStatus: @"Ok"];
    }
    return NO;
}

@end
