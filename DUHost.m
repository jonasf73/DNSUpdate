//
//  DUHost.m
//  DNSUpdate2
//
//  Created by jalon on Wed Apr 04 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUHost.h"
#import "DUUser.h"
#import "DUInterface.h"

@implementation DUHost

- initWithName:(NSString *)theName {
    [super init];
    hostname=[theName copy]; // - copy returns a retained object
    registeredAddress=@"-not registered-";
    hostProperties=[[NSMutableDictionary alloc] initWithCapacity:0];
    interface=nil;
    lastUpdate=[[NSDate distantPast] retain];
    active=YES;
    dirty=YES;
    isUpdating=NO;
    hostStatus=@"Not tested";
    return self;
}

- (BOOL)isUser {
    return NO;
}

- (void)setUser:(DUUser *)theUser {
    user=theUser;
}

- (DUUser *)user {
    return user;
}

- (void)setName:(NSString *)theName {
    if(![theName isEqualToString:hostname]) {
        dirty=YES;
        [hostname release];
        hostname=[theName copy]; // - copy returns a retained object
        [self resetAddress];
    }
}

- (NSString *)getName {
    return hostname;
}

- (void)resetAddress {
    lastUpdate=[[NSDate distantPast] retain];
    [registeredAddress release];
    registeredAddress=@"-not registered-";
    [self setStatus:@"Not tested"];
    dirty=YES;
}

- (NSDate *)lastUpdate {
    return lastUpdate;
}

- (void)setLastUpdate:(NSDate *)theDate {
    [lastUpdate release];
    lastUpdate=[theDate retain];
    dirty=YES;
}

- (void)updateAddressTo:(NSString *)newAddress {
    [registeredAddress release];
    registeredAddress=[newAddress copy]; // - copy returns a retained object
    [lastUpdate release];
    lastUpdate=[[NSDate date] retain];
    dirty=YES;
}
    
- (NSString *)getAddress {
    return registeredAddress;
}

- (void)setAddress:(NSString *)theAddress {
    [registeredAddress release];
    registeredAddress=[theAddress copy]; // - copy returns a retained object
    dirty=YES;
}

- hostPropertyForKey:(NSString *)theKey {
    return [hostProperties objectForKey:theKey];
}

- (void)setHostProperty:object forKey:(NSString *)theKey internalProperty:(BOOL)flag
{
    id oldObject=[hostProperties objectForKey:theKey];
    BOOL isModifying=NO;
    
    if((!oldObject)||(!object)) {
        if(oldObject!=object) {
            isModifying=YES;
        }
    }
    else {
        if(![object isEqual:oldObject]) {
            isModifying=YES;
        }
    }
    
    if(isModifying) {
        if(!flag)
            [self resetAddress];
        
        if(object) {
            [hostProperties setObject:object forKey:theKey];
        } else {
            [hostProperties removeObjectForKey:theKey];
        }
    }
}

- (void)removeHostPropertyForKey:(NSString *)theKey {
    [hostProperties removeObjectForKey:theKey];
}

- (NSArray *)propertiesKeys {
    return [hostProperties allKeys];
}

- (void)setHostProperties:(NSDictionary *)theProperties {
    [hostProperties release];
    hostProperties=[theProperties mutableCopy]; // - mutableCopy returns a retained object
}

- (NSDictionary *)hostProperties {
    return hostProperties;
}

- (DUInterface *)interface {
    return interface;
}

- (void)setInterface:(DUInterface *)theInterface {
    interface=theInterface;
    dirty=YES;
}

- (BOOL)isDirty {
    return dirty;
}

- (void)setDirty:(BOOL)flag {
    dirty=flag;
}

- (BOOL)isUpdating {
    return isUpdating;
}

- (void)setUpdating:(BOOL)flag {
    isUpdating=flag;
}

- description {
    return hostname;
}

- (BOOL)isActive {
    return active;
}

- (void)setActive:(BOOL)flag {
    dirty=(active!=flag);
    active=flag;
}

- (void)setStatus:(NSString *)theStatus {
    [hostStatus release];
    hostStatus=[theStatus copy]; // - copy returns a retained object
}

- (NSString *)hostStatus {
    if(![[self user] isActive])
        return @"User inactive";
    else if(![[self interface] isActive])
        return @"Interface is inactive";
    else
        return hostStatus;
}

- (NSString *)realStatus {
    return hostStatus;
}

- (void)dealloc {
    NSLog(@"Deallocating host %@",hostname);
    
    [hostname release];
    [hostProperties release];
    [registeredAddress release];
    [lastUpdate release];
    [hostStatus release];
    
    [super dealloc];
}

@end
