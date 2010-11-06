//
//  DUEasyDNSUpdater.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Sun Jul 21 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUEasyDNSUpdater.h"
#import "HTTPLoader.h"
#import "DUHost.h"
#import "DUUser.h"
#import "DUInterface.h"

#define TIMETOWAIT 15.0*60.0

NSString *easyDNSURL=@"members.easydns.com/dyn/dyndns.php";

NSSet *_easyDNSValidOptions=nil;

@implementation DUEasyDNSUpdater
+ (void)initialize {
    _easyDNSValidOptions=[[NSSet set] retain];
}

- (void)setServiceName:(NSString *)theName {
    NSLog(@"Warning: trying to change service name");
}

- (NSString *)getServiceName {
    return @"EasyDNS.com";
}

- description {
    return @"<EasyDNS.com updater>";
}

- (BOOL)needUpdate:(DUHost *)theHost {
    if([theHost isActive]) {
        NSDate *dateForUpdate;
        if(dateForUpdate=[theHost hostPropertyForKey:@"DUDateForUpdate"]) {
            if([dateForUpdate timeIntervalSinceNow]>0) {
                return NO;
            }
            [theHost removeHostPropertyForKey:@"DUDateForUpdate"];
        }
        return [super needUpdate:theHost];
    }
    return NO;
}

- (void)updateHosts:(NSArray *)hosts user:(DUUser *)theUser withKey:(NSString *)key {
    DUHost *host=[hosts objectAtIndex:0];
    NSString *query;
    NSURL *theURL;
    NSDictionary *serverOutput;
    NSArray *serverLines;
    int serverCode;

    [DUUser updating];
    [theUser setUserStatus:@"Ok"];

    query=[NSString stringWithFormat:@"http://%@?hostname=%@&%@",
        easyDNSURL,
        [hosts objectAtIndex:0],
        key];

    NSLog(@"Query : %@",query);

    theURL=[NSURL URLWithString:query];

    NS_DURING
        serverOutput=getURL(theURL, [theUser getName], [theUser getPassword]);
    NS_HANDLER
        NSLog(@"Network unreachable: %@", localException);

        [host setStatus:@"Network unreachable"];
        return;
    NS_ENDHANDLER
    
    if(!serverOutput) {
        NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
        NSLog(@"error while updating with EasyDNS.com. Will retry later");

        [theUser setUserStatus:@"No Server Answer"];
        [host setStatus:@"Waiting"];
        [host setHostProperty:aDate forKey:@"DUDateForUpdate"  internalProperty:YES];

        [theUser addATry];
        if([theUser tries]>MAX_TRIES) {

            [host setActive:NO];

            [theUser resetTries];
        }
        return;
    }

    [theUser resetTries];

    serverLines=[serverOutput objectForKey:Output];
    serverCode=[[serverOutput objectForKey:ServerCode] intValue];

    NSLog(@"%i - %@",serverCode,serverLines);

    switch(serverCode) {
        case HTTPBADAUTH:
            NSLog(@"Login failed for user %@ (Deactivating this user)",theUser);
            [theUser setUserStatus:@"Bad Auth"];
            [theUser setActive:NO];
            return;
        case HTTPSUCCESSCODE:
            break;
        case 502:
            NSLog(@"502 error (Proxy error)");
            [hosts makeObjectsPerformSelector:@selector(setStatus:) withObject:@"No Server Answer"];
            return;
        default:
            NSLog(@"While updating, unexpected EasyDNS.com server code: %i (Contact support: %@)",serverCode,authorMail);
            NSLog(@"Server output: %@",serverLines);
            [theUser setUserStatus:@"DynDNS Critical"];
            [theUser setActive:NO];
            return;
    }

    {
        NSString *line=[serverLines objectAtIndex:0];
        NSArray *words=[line componentsSeparatedByString:@" "];

        if([words count]) {
            NSString *returnCode=[words objectAtIndex:0];

            if([returnCode isEqualToString:@"NOACCESS"]) {
                NSLog(@"Access denyied for %@ or host is not yours (Deactivating this user)",theUser);
                [theUser setUserStatus:@"Bad Auth"];
                [theUser setActive:NO];
                return;
            } else if([returnCode isEqualToString:@"NOSERVICE"]) {
                NSLog(@"No such host");
                [host setStatus:@"No such host"];
                [host setActive:NO];
            } else if([returnCode isEqualToString:@"ILLEGAL"]) {
                // unexpected output
                NSLog(@"While updating, unexpected EasyDNS.com output: (Contact support: %@)", authorMail);
                NSLog(@"Server output: %@",serverOutput);
                [theUser setUserStatus:@"DynDNS Critical"];
                [theUser setActive:NO];                
            } else if([returnCode isEqualToString:@"TOOSOON"]) {
                NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
                NSLog(@"%@: too frequent update. Will wait",host);

                [host setStatus:@"Waiting"];
                [host setHostProperty:aDate forKey:@"DUDateForUpdate"  internalProperty:YES];
            } else  if([returnCode isEqualToString:@"NOERROR"]) {
                NSLog(@"%@: update suceeded",host);
                [host updateAddressTo:[[host interface] getAddress]];
                [host setStatus:@"Ok"];
            } else {
                // unexpected output
                NSLog(@"While updating, unexpected EasyDNS.com output: (Contact support: %@)",serverOutput,authorMail);
                NSLog(@"Server output: %@",serverOutput);
                [theUser setUserStatus:@"DynDNS Critical"];
                [theUser setActive:NO];
            }
        } else {
            // unexpected output
            NSLog(@"While updating, unexpected EasyDNS.com output: (Contact support: %@)",serverOutput,authorMail);
            NSLog(@"Server output: %@",serverOutput);
            [theUser setUserStatus:@"DynDNS Critical"];
            [theUser setActive:NO];
        }
    }
}

- (BOOL)isValidOption:(NSString *)theOption {
    return [_easyDNSValidOptions member:theOption]!=nil;
}

- (NSString *)ipOption {
    return @"myip";
}

@end
