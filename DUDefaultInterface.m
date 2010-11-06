//
//  DUDefaultInterface.m
//  DNSUpdate2
//
//  Created by jalon on Fri Nov 30 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUDefaultInterface.h"

#include <SystemConfiguration/SystemConfiguration.h>

static DUInterface *_duDefaultInterface=nil;

@implementation DUDefaultInterface

+ (DUInterface *)defaultInterface {
    if(!_duDefaultInterface) {
    	_duDefaultInterface=[[self alloc] initWithName:@"Default Interface"];
    }
    return _duDefaultInterface;
}

- (void)cacheAddress {
    NSString *ipAddress=nil;
    SCDynamicStoreRef dynRef=SCDynamicStoreCreate(NULL, (CFStringRef)@"DNSUpdate daemon", NULL, NULL);
    NSDictionary *objects;
    NSArray *addresses;
    NSString *currentInterface;
    
    if(!dynRef) {
        if([self isActive]) {
            NSLog(@"\"%@\": can't contact system configuration",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;

        cachedIP=nil;
        return;
    }

    objects=(NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)@"State:/Network/Global/IPv4");
    if(!objects) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't locate Network configuration",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }
    
    currentInterface=[[objects objectForKey:@"PrimaryInterface"] copy];
    if(!currentInterface) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't locate Primary Interface",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        [objects release];
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }

    [objects release];
    
    objects=(NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)[NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",currentInterface]);

    [currentInterface release];
    
    if(!objects) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't get Interface configuration",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }
    
    addresses=[objects objectForKey:@"Addresses"];
    if(!addresses) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't get addresses",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        [objects release];
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }
    
    ipAddress=[[[addresses objectAtIndex:0] copy] autorelease];
    if(!ipAddress) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't get address",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        [objects release];
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }

    if(![self isActive]) {
        NSLog(@"Activate interface %@",[self getName]);
        [DUInterface setMustNotifyObservers];
    }
    
    [self setActive:YES];
    
    [objects release];
    CFRelease(dynRef);
    cachedIP=[ipAddress retain];
}


@end
