//
//  DUDaemon.m
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUDaemon.h"
#import "DUUser.h"
#import "DUCommon.h"
#import "DULibraryManager.h"

#define REPEATINTERVAL 60.0

DUDaemon *_duDaemon=nil;
BOOL _paused=YES;
NSTimer *_timer=nil;

@implementation DUDaemon

+ (DUDaemon *)sharedInstance {
    if(!_duDaemon) {
        _duDaemon=[[DUDaemon alloc] init];
    }
    return _duDaemon;
}

- (oneway void)launch {
    if(_timer) {
        [_timer invalidate];
        [_timer release];
    }

    _timer=[[NSTimer scheduledTimerWithTimeInterval:REPEATINTERVAL target:self
                        selector:@selector(updateDNS)
                        userInfo:nil repeats:YES] retain];
    
    if(_paused) {
        [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDataUpdated];
    }
    _paused=NO;
}

- (oneway void)updateDNS {
    NS_DURING
        [DUUser update];
    NS_HANDLER
        NSLog(@"Exception during update: %@", localException);
    NS_ENDHANDLER
}

-(oneway void)daemonStart {
    NSLog(@"Waking up daemon");
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DUDaemonIsPaused"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateDNS];
    [self launch];
}

-(oneway void)pause {
    if(!_paused) {
        [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDataUpdated];
    }
    if(_timer) {
        [_timer invalidate];
        [_timer release];
        _timer=nil;
        _paused=YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DUDaemonIsPaused"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"Daemon paused");
    }
}

-(BOOL)isPaused {
    return _paused;
}

@end
