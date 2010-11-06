//
//  DUServiceInterface.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Mon Feb 11 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUServiceInterface.h"

NSMutableDictionary *_Interfaces=nil;

@implementation DUServiceInterface

+ (void)registerServiceInterface:(DUServiceInterface *)theInterface {
    [DUServiceInterface serviceInterfaces];
    [_Interfaces setObject:theInterface forKey:[theInterface getServiceName]];
    NSLog(@"Registering service %@",[theInterface getServiceName]);
}

+ (NSDictionary *)serviceInterfaces {
    if(_Interfaces==nil) {
        _Interfaces=[[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return _Interfaces;
}

+ (DUServiceInterface *)getServiceInterfaceFor:(NSString *)theName {
    return [_Interfaces objectForKey:theName];
}

+ (void)registerService
{
    [DUServiceInterface registerServiceInterface:[[[self alloc] init] autorelease]];
}

- init {
    duServiceUserView=nil;
    duServiceHostView=nil;
    return [super init];
}

- (NSString *)getServiceName {
    return nil; // Must be implemented by subclass
}

- (void)_loadInterface {
    NSLog(@"Loading interface for %@",[self getServiceName]);
    [NSBundle loadNibNamed:[self getServiceName] owner:self];
    duServiceUserView=[duServiceUserView contentView];
    duServiceHostView=[duServiceHostView contentView];
    [[duServiceUserView retain] removeFromSuperview];
    [[duServiceHostView retain] removeFromSuperview];
}

- (NSView *)serviceUserView {
    if(!duServiceUserView) {
        [self _loadInterface];
    }
    return duServiceUserView;
}

- (NSView *)serviceHostView {
    if(!duServiceHostView) {
        [self _loadInterface];
    }
    return duServiceHostView;
}

- (void)dealloc {
    [duServiceHostView release];
    [duServiceUserView release];
    [super dealloc];
}

- (void)validateUser:(DUUser *)theUser {
    // Must be implemented by subclass
}

- (void)validateHost:(DUHost *)theHost {
    // Must be implemented by subclass
}

- (void)prepareHostViewForHost:(DUHost *)DUHost {
    // Must be implemented by subclass
}

- (void)prepareUserViewForUser:(DUUser *)DUUser {
    // Must be implemented by subclass
}

- (void)clearHostView {
    // Must be implemented by subclass
}

- (void)clearUserView {
    // Must be implemented by subclass
}

@end
