//
//  DNSUpdate_main.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUInterface.h"
#import "DUDefaultInterface.h"
#import "DUInternalInterface.h"
#import "DUExternalInterface.h"
#import "DUFakeInterface.h"
#import "HTTPLoader.h"
#import "DUServiceUpdater.h"
#import "DUUser.h"
#import "DUHost.h"
#import "DUDaemon.h"
#import "DUGuardian.h"
#import "DUClient.h"

#import "DUDynDNSUpdater.h"
#import "DUZoneEditUpdater.h"
#import "DUEasyDNSUpdater.h"

#include <sys/types.h>
#include <unistd.h>

NSArray *arguments;
int count;

void usage() {
    NSLog(@"usage:\ndnsupdate pause: pauses the daemon\ndnsupdate start: starts the daemon\ndnsupdate quit: deprecated\ndnsupdate daemon: launches as a daemon");

    exit(1);
}

int main (int argc, const char *argv[]) {
    NSAutoreleasePool *pool;
    NSString *command;


    pool = [[NSAutoreleasePool alloc] init];
    
    arguments=[[NSProcessInfo processInfo] arguments];
    count=[arguments count];
    
    if(count<2)
        usage();
        
    command=[arguments objectAtIndex:1];
    
    if([command isEqualToString:@"magic"]) {
        printf("%s",[UserAgent cString]);
    } else if([command isEqualToString:@"daemon"]) {
        DUInterface *defaultInterface,*en0, *en1, *ppp0, *pppoe0, *external;
        NSUserDefaults *duDefaults;

        NSLog(@"Launching as daemon");
        
        if(geteuid()!=0) {
            NSLog(@"DNSUpdate daemon has to be launched as root!");
            exit(2);
        }
        
        NSLog(@"Launching daemon with version %@",UserAgent);

        
        duDefaults=[NSUserDefaults standardUserDefaults];
        
        defaultInterface=[DUDefaultInterface defaultInterface];
        en0=[DUInternalInterface internalInterfaceWithName:@"Built-in Ethernet" interface:@"en0"];
        en1=[DUInternalInterface internalInterfaceWithName:@"Secondary Ethernet" interface:@"en1"];
        ppp0=[DUInternalInterface internalInterfaceWithName:@"Internal Modem" interface:@"ppp0"];
        pppoe0=[DUInternalInterface internalInterfaceWithName:@"ADSL Modem (PPPoE)" interface:@"ppp0"];
        
        external=[DUExternalInterface externalInterfaceWithName:@"External" andURL:@"http://checkip.dyndns.org/"];
        
        [DUExternalInterface externalInterfaceWithName:@"External (bypassing Proxy)" andURL:@"http://checkip.dyndns.org:8245/"];
        [DUFakeInterface fakeOfflineInterface];
        
        [DUDynDNSUpdater registerService];
        [DUZoneEditUpdater registerService];
        [DUEasyDNSUpdater registerService];
        
        [duDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], @"DUDaemonIsPaused",
                                    @"DUPersistentStart", @"DUDaemonStartOption",
                                    nil]];
                                    
        /* DUDaemonStartOption:
                DUPersistentStart
                DUActivatedOnStart
                DUDesactivatedOnStart
                DUAutoStart
        */
                                    
        [DUUser loadUsers];
    
        [[DUDaemon sharedInstance] launch];
        
        if(([[duDefaults stringForKey:@"DUDaemonStartOption"] isEqualToString:@"DUPersistentStart"]&&[duDefaults boolForKey:@"DUDaemonIsPaused"])||([[duDefaults stringForKey:@"DUDaemonStartOption"] isEqualToString:@"DUDesactivatedOnStart"])||([[duDefaults stringForKey:@"DUDaemonStartOption"] isEqualToString:@"DUAutoStart"])) {
            [[DUDaemon sharedInstance] pause];
        }
        
        [DUGuardian sharedInstance];
        
        [[NSRunLoop currentRunLoop] run];
        
        NSLog(@"DNSUpdate daemon run loop terminated");
    } else {
        id <DUProxy> daemon=[DUClient connectAndGetDaemonFor:nil];
        
        if(daemon) {
            if([command isEqualToString:@"pause"]) {
                [daemon pause];
            } else if([command isEqualToString:@"start"]) {
                [daemon daemonStart];
            } else if([command isEqualToString:@"quit"]) {
                NSLog(@"Deprecated command");
//                [daemon quitDaemon];
            } else
                usage();
        }
    }

    [pool release];
    exit(0);
}