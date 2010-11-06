//
//  DUClient.m
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUClient.h"
#import "DUCommon.h"
#import "DUProtocols.h"

NSString *UserAgent=@"DNSUpdate/2.8 agent@dnsupdate.org";

#define TIMEOUT 100.0

@implementation DUClient

+ (id <DUProxy>)connectAndGetDaemonFor:delegate {
    NSConnection *theServer;
    id guardian;
    id <DUProxy> theProxy;
    NSString *theKey=[NSString stringWithContentsOfFile:KEYFILE];

    if(!theKey) {
        NSLog(@"Can't get the key to connect to the daemon");
        NSLog(@"Maybe you don't have enough permissions");
        NSLog(@"Or the daemon is not launched");
        return nil;
    }
    
    theServer=[NSConnection connectionWithRegisteredName:DNSUPDATE host:nil];
    if(!theServer) {
        NSLog(@"Can't connect to daemon");
        return nil;
    }
    
    guardian=[theServer rootProxy];
    
    [guardian setProtocolForProxy:@protocol(DUGuardian)];
    
    theProxy=[guardian getProxyWithKey:theKey];
    
    if(!theProxy) {
        NSLog(@"Can't get permission with daemon");
        return nil;
    }

    [theServer setRequestTimeout:TIMEOUT];
    [theServer setReplyTimeout:TIMEOUT];
    if(delegate) {
        [[NSNotificationCenter defaultCenter] addObserver:delegate
            selector:@selector(connectionDidDie:)
            name:NSConnectionDidDieNotification
            object:theServer];
        [delegate setConnection:theServer];
    }

    return theProxy;
}

@end
