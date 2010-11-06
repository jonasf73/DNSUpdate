//
//  DUInterface.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *DUInterfaceOk;
extern NSString *DUIPCheckError;

@interface DUInterface : NSObject {
    NSString *interfaceName;
    NSString *interfaceError;
    NSString *cachedIP;
    BOOL active;
}

+ (NSDictionary *)interfaces;
+ (void)registerInterface:(DUInterface *)theInterface;
+ getInterface:(NSString *)theName;

+ (void)resetMustNotifyObservers;
+ (BOOL)mustNotifyObservers;
+ (void)setMustNotifyObservers;
+ (void)resetCachedAddresses;

- initWithName:(NSString *)theName;

- (void)cacheAddress;
- (NSString *)getAddress;
- (void)resetCachedAddress;
- (void)setActive:(BOOL)flag;
- (BOOL)isActive;
- (NSString *)getError;
- (void)resetError;
- (NSString *)getName;
- (void)setName:(NSString *)theName;

@end
