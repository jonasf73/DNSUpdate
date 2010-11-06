//
//  DUFakeInterface.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Sat Mar 30 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUFakeInterface.h"

DUInterface *_fakeOfflineInterface=nil;

@implementation DUFakeInterface

+ (DUInterface *)fakeOfflineInterface {
    if(_fakeOfflineInterface==nil) {
        _fakeOfflineInterface=[[DUFakeInterface alloc] initWithName:@"Offline" address:@"111.111.111.111"];
    }
    return _fakeOfflineInterface;
}

- initWithName:(NSString *)theName address:(NSString *)theAddress {
    [super initWithName:theName];
    fakeAddress=[theAddress copy];
    return self;
}

- (void)cacheAddress {
    cachedIP=fakeAddress;
}

- (void)dealloc {
    [fakeAddress release];
    [super dealloc];
}

@end
