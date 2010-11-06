//
//  DUInterface.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUInterface.h"

NSString *DUIPCheckError=@"DUIPCheckError";

NSString *DUInterfaceOk = @"DUInterfaceOk";

static NSMutableDictionary *_interfaces=nil;

static BOOL _duMustNotify=NO;

@implementation DUInterface

+ (NSDictionary *)interfaces {
    if(_interfaces==nil) {
        _interfaces=[[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return _interfaces;
}
    
+ (void)registerInterface:(DUInterface *)theInterface {
    [DUInterface interfaces];
    [_interfaces setObject:theInterface forKey:[theInterface getName]];
    NSLog(@"Registering interface %@ (%@)",[theInterface getName],theInterface);
}
    
+ getInterface:(NSString *)theName {
    return [[DUInterface interfaces] objectForKey:theName];
}

+ (void)resetMustNotifyObservers {
    _duMustNotify=NO;
}

+ (BOOL)mustNotifyObservers {
    return _duMustNotify;
}

+ (void)setMustNotifyObservers {
    _duMustNotify=YES;
}

+ (void)resetCachedAddresses {
    NSEnumerator *interfaceEnumerator=[_interfaces objectEnumerator];
    DUInterface *theInterface;
    
    while(theInterface=[interfaceEnumerator nextObject]) {
        [theInterface resetCachedAddress];
    }
}

- initWithName:(NSString *)theName {
    [super init];
    interfaceName=[theName copy];
    interfaceError=DUInterfaceOk;
    cachedIP=nil;
    active=YES;
    [DUInterface registerInterface:self];
    return self;
}

- (void)cacheAddress {
    // must be implemented by subclasses
    NSLog(@"%@: Code error. cacheAddress must be implemented by subclasses", self);
}

- (NSString *)getAddress {
    if(!cachedIP) {
        [self cacheAddress];
    }
    return cachedIP;
}

- (void)resetCachedAddress {
    [cachedIP release];
    cachedIP=nil;
}

- (void)setActive:(BOOL)flag
{
    active=flag;
}

- (BOOL)isActive {
    return active;
}

- (NSString *)getError {
    return interfaceError;
}

- (void)resetError {
    interfaceError=DUInterfaceOk;
}

- (NSString *)getName {
    return interfaceName;
}

- (NSString *)description {
    return [self getName];
}

- (void)setName:(NSString *)theName {
    [interfaceName release];
    interfaceName=[theName copy];
}

- (void)dealloc {
    [interfaceName release];
    [interfaceError release];
    [super dealloc];
}

@end
