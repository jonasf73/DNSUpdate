//
//  DUGuardian.m
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUGuardian.h"
#import "DUProxy.h"
#import "DUDaemon.h"
#import "DUCommon.h"
#import "DULibraryManager.h"
#import "DUMachBootstrapServer.h"

#define KEYFILEPERMISSIONS [NSNumber numberWithInt:432]

DUGuardian *_sharedGuardian=nil;
NSString *_guardianKey=nil;

NSConnection *duApplicationConnection=nil;

@implementation DUGuardian

+ (DUGuardian *)sharedInstance {
    if(!_sharedGuardian) {
        NSConnection *theServer=[NSConnection defaultConnection];

        _guardianKey=[[[NSProcessInfo processInfo] globallyUniqueString] retain];

        NSLog(@"Creating KEYFILE %@",KEYFILE);
        
        if(![[NSFileManager defaultManager] createFileAtPath:KEYFILE
                    contents:[_guardianKey dataUsingEncoding:NSASCIIStringEncoding]
                    attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"admin",NSFileGroupOwnerAccountName,
                                KEYFILEPERMISSIONS,NSFilePosixPermissions,nil]]) {
            NSLog(@"Problems creating DNSUpdate key file");
            exit(3);
        }
        _sharedGuardian=[[DUGuardian alloc] init];
        
        
        if(theServer) {
            [theServer setRootObject:_sharedGuardian];
#if 0
            [theServer registerName:DNSUPDATE];
#else
            NSPortNameServer* nameServer = [DUMachBootstrapServer defaultServer];
            NSLog(@"Registering DNSUpdate daemon server with name %@ with name server %@", DNSUPDATE, nameServer);
            if(![theServer registerName:DNSUPDATE withNameServer:nameServer]) {
                NSLog(@"Can't register DNSUpdate daemon server");
            }
#endif
            
            [theServer setDelegate:_sharedGuardian];
            
            NSLog(@"Guardian starting to listen to clients");
            
            [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDaemonLaunched];
        } else {
            NSLog(@"Can't get default connection");
            exit(4);
        }
    }
    return _sharedGuardian;
}

- (id <DUProxy>)getProxyWithKey:(NSString *)theKey {
    if([_guardianKey isEqualToString:theKey]) {
        NSLog(@"Guardian: Get a client");
        return [DUProxy sharedInstance];
    } else {
        NSLog(@"Unauthorized client tried to connect");
    }
    return nil;
}

- (BOOL)connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnection  {
    NSLog(@"Connecting to the Guardian");
    [[NSNotificationCenter defaultCenter] addObserver:self
                        selector:@selector(connectionDidDie:)
                        name:NSConnectionDidDieNotification
                        object:newConnection];

    return YES;
}

- (void)connectionDidDie:theNotification {
    if([theNotification object] == duApplicationConnection) {
        NSLog(@"Lost connection with the application");
        if([[[NSUserDefaults standardUserDefaults] stringForKey:@"DUDaemonStartOption"] isEqualToString:@"DUAutoStart"]) {
            [[DUDaemon sharedInstance] pause];
        }
        duApplicationConnection=nil;
    } else {
        NSLog(@"Lost connection with a client");
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[theNotification name]];
}

@end
