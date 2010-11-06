//
//  DUHost.h
//  DNSUpdate2
//
//  Created by jalon on Wed Apr 04 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUProtocols.h"

@class DUUser;
@class DUInterface;

@interface DUHost : NSObject <DUIdentify> {
    DUUser *user;
    NSString *hostname;
    NSMutableDictionary *hostProperties;
    NSString *registeredAddress;
    DUInterface *interface;
    NSDate *lastUpdate;
    BOOL active;
    NSString *hostStatus;
    BOOL dirty;
    BOOL isUpdating;
}

- initWithName:(NSString *)theName;

- (void)setUser:(DUUser *)theUser;
- (DUUser *)user;

- (void)setName:(NSString *)theName;
- (NSString *)getName;
- (void)resetAddress;
- (NSDate *)lastUpdate;
- (void)setLastUpdate:(NSDate *)theDate;
- (void)updateAddressTo:(NSString *)newAddress;
- (NSString *)getAddress;
- (void)setAddress:(NSString *)theAddress;

- hostPropertyForKey:(NSString *)theKey;
- (void)setHostProperty:object forKey:(NSString *)theKey internalProperty:(BOOL)flag;
- (void)removeHostPropertyForKey:(NSString *)theKey;
- (NSArray *)propertiesKeys;
- (NSDictionary *)hostProperties;
- (void)setHostProperties:(NSDictionary *)theProperties;

- (DUInterface *)interface;
- (void)setInterface:(DUInterface *)theInterface;

- (BOOL)isDirty;
- (void)setDirty:(BOOL)flag;

- (BOOL)isUpdating;
- (void)setUpdating:(BOOL)flag;

- (BOOL)isActive;
- (void)setActive:(BOOL)flag;
- (void)setStatus:(NSString *)theStatus;
- (NSString *)hostStatus;
- (NSString *)realStatus;

@end