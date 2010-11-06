//
//  DUZoneEditUpdater.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Tue Feb 12 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUZoneEditUpdater.h"
#import "HTTPLoader.h"
#import "DUHost.h"
#import "DUUser.h"
#import "DUInterface.h"

NSString *zoneEditURL=@"dynamic.zoneedit.com/auth/dynamic.html";

#define TIMELOST 2.0
#define TIMETOWAIT 20.0*60.0

NSSet *_zoneEditValidOptions=nil;

@implementation DUZoneEditUpdater

+ (void)initialise {
    _zoneEditValidOptions=[NSSet set];
}

- (void)setServiceName:(NSString *)theName {
    NSLog(@"Warning: trying to change service name");
}

- (NSString *)getServiceName {
    return @"ZoneEdit.com";
}

- description {
    return @"<ZoneEdit.com updater>";
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

    query=[NSString stringWithFormat:@"http://%@?host=%@&%@",
        zoneEditURL,
        [hosts objectAtIndex:0],
        key];

    NSLog(@"Query : %@",query);

    theURL=[NSURL URLWithString:query];

    NS_DURING
        serverOutput=getURL(theURL, [theUser getName], [theUser getPassword]);
    NS_HANDLER
        NSLog(@"Network unreachable: %@", localException);

        {
            [host setStatus:@"Network unreachable"];
            return;
        }
    NS_ENDHANDLER

    if(!serverOutput) {
        NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
        NSLog(@"error while updating with ZoneEdit.com. Will retry later");

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

    //NSLog(@"%i - %@",serverCode,serverLines);

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
            NSLog(@"While updating, unexpected ZoneEdit.com server code: %i (Contact support: %@)",serverCode,authorMail);
            NSLog(@"Server output: %@",serverLines);
            [theUser setUserStatus:@"DynDNS Critical"];
            [theUser setActive:NO];
            return;
    }

    {
        NSString *line=[serverLines objectAtIndex:0];
        NSScanner *scanner=[NSScanner scannerWithString:line];
        int theCode;
        
        if([scanner scanString:@"<SUCCESS" intoString:NULL]) {
            // update succeeded
            [scanner scanString:@"CODE=\"" intoString:NULL];
            [scanner scanInt:&theCode];
            switch(theCode) {
                case 200:
                    NSLog(@"%@: update suceeded",host);
                    break;
                case 201:
                    NSLog(@"%@: no such host in database or no need to update",host);
            }
            [host updateAddressTo:[[host interface] getAddress]]; // XXX must cache all those addresses
            [host setStatus:@"Ok"];
        } else if([scanner scanString:@"<ERROR" intoString:NULL]) {
            // error while updating
            [scanner scanString:@"CODE=\"" intoString:NULL];
            [scanner scanInt:&theCode];
            switch(theCode) {
                case 707:
                    // either nochg or abuse
                    {
                        NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
                        NSLog(@"%@: too frequent update. Will wait",host);

                        [host setStatus:@"Waiting"];
                        [host setHostProperty:aDate forKey:@"DUDateForUpdate"  internalProperty:YES];
                    }
                    break;
                case 704:
                    // not a fully qualified domain name
                    NSLog(@"%@: not a fully qualified domain name (Deactivating this host for this user)",host);
                    [host setActive:NO];
                    [host setStatus:@"Bad domain name"];
                    break;
                case 701:
                    // not yours
                    NSLog(@"%@: not owned by %@ (Deactivating this host for this user)",host,theUser);
                    [host setActive:NO];
                    [host setStatus:@"Not yours"];
                    break;
                case 702:
                    // update failed. no reason
                    {
                        NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
                        NSLog(@"%@: update failed. No reason. Will wait",host);
    
                        [host setStatus:@"Waiting"];
                        [host setHostProperty:aDate forKey:@"DUDateForUpdate"  internalProperty:YES];
                    }
                    break;
                default:
                    // unexpected output
                    NSLog(@"While updating, unexpected ZoneEdit.com output: (Contact support: %@)",serverOutput,authorMail);
                    NSLog(@"Server output: %@",serverOutput);
                    [theUser setUserStatus:@"DynDNS Critical"];
                    [theUser setActive:NO];
            }
        } else {
            // unexpected output
            NSLog(@"While updating, unexpected ZoneEdit.com output: (Contact support: %@)",serverOutput,authorMail);
            NSLog(@"Server output: %@",serverOutput);
            [theUser setUserStatus:@"DynDNS Critical"];
            [theUser setActive:NO];
        }
    }
}

- (BOOL)isValidOption:(NSString *)theOption {
    return [_zoneEditValidOptions member:theOption]!=nil;
}

- (NSString *)ipOption {
    return @"dnsto";
}

@end
