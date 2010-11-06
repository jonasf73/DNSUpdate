//
//  DUProxy.m
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUProxy.h"
#import "DUInterface.h"
#import "DUDaemon.h"
#import "DUUser.h"
#import "DUServiceUpdater.h"
#import "DUHost.h"
#import "DUGuardian.h"

#include <sys/types.h>
#include <unistd.h>

DUProxy *_sharedProxy=nil;
NSArray *startOptions=nil;

@implementation DUProxy

+ (void)initialize {
    startOptions=[[NSArray arrayWithObjects:
                            @"DUPersistentStart",
                            @"DUActivatedOnStart",
                            @"DUDesactivatedOnStart",
                            @"DUAutoStart", nil] retain];
}

                                    
    
+ (DUProxy *)sharedInstance {
    if(!_sharedProxy) {
        _sharedProxy=[[DUProxy alloc] init];
    }
    return _sharedProxy;
}

- (NSDictionary *)users {
    return [DUUser users];
}

- (oneway void)saveUsers {
    [DUUser saveUsers];
}

- (DUUser *)addUserWithName:(NSString *)theName andPassword:(NSString *)thePassword andService:(DUServiceUpdater *)theService {
    return [DUUser addUserWithName:theName andPassword:thePassword andService:theService];
}

- (DUHost *)newHostWithName:(NSString *)theName andInterface:(DUInterface *)interface forUser:(DUUser *)user {
    DUHost *aHost;
    aHost=[[[DUHost alloc] initWithName:theName] autorelease];
    [aHost setInterface:interface];
    [user addHost:aHost];
    [user saveUser];
    return aHost;
}

- (oneway void)removeHost:(DUHost *)host {
    DUUser *user=[host user];
    [user removeHost:host];
    [user saveUser];
}

- (NSDictionary *)interfaces {
    return [DUInterface interfaces];
}

- (BOOL)isPaused {
    return [[DUDaemon sharedInstance] isPaused];
}

- (oneway void)pause {
    [[DUDaemon sharedInstance] pause];
}

- (oneway void)daemonStart {
    [[DUDaemon sharedInstance] daemonStart];
}

- (oneway void)quitDaemon {
    
    NSLog(@"killing dnsupdate daemon process (%i)",getpid());
    exit(0);
//    system([[NSString stringWithFormat:@"kill %i",getpid()] cString]);
    
}

- (NSDictionary *)services {
    return [DUServiceUpdater serviceUpdaters];
}

- (BOOL)registerAsApplication:idObject {
    if(![idObject isProxy]) {
        return NO;
    }
    if(duApplicationConnection!=nil) {
        return NO;
    }
    NSLog(@"Connection registered for the application");
    duApplicationConnection=[idObject connectionForProxy];
    // only if auto-start is on
    if([[[NSUserDefaults standardUserDefaults] stringForKey:@"DUDaemonStartOption"] isEqualToString:@"DUAutoStart"]) {
        [[DUDaemon sharedInstance] daemonStart];
    }
    
    return YES;
}

- (int)startOption {
    return [startOptions indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"DUDaemonStartOption"]];
}

- (oneway void)setStartOption:(int)theOption {
    if(theOption>=0&&theOption<[startOptions count]) {
        [[NSUserDefaults standardUserDefaults] setObject:[startOptions objectAtIndex:theOption] forKey:@"DUDaemonStartOption"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
