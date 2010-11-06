//
//  DUDynDNSUpdater.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUDynDNSUpdater.h"
#import "HTTPLoader.h"
#import "DUHost.h"
#import "DUUser.h"
#import "DUInterface.h"

#define FORCEUPDATE_DAYS 25

NSString *dynDNSURL=@"members.dyndns.org/nic/update";
NSSet *_dyndnsValidOptions=nil;

NSCharacterSet *_whiteSpaces;
NSCharacterSet *_nonDigitSet;
NSArray *_returnCommands;
NSTimeZone *_GMTTimeZone;
#define TIMELOST 2.0
#define TIMETOWAIT 10.0*60.0

@implementation DUDynDNSUpdater

+ (void)initialize {
    _dyndnsValidOptions=[[NSSet setWithObjects:@"system",@"wildcard",@"backmx",@"mx",nil] retain];
    _whiteSpaces=[[NSCharacterSet whitespaceCharacterSet] retain];
    _nonDigitSet=[[[NSCharacterSet decimalDigitCharacterSet] invertedSet] retain];
    _returnCommands=[[NSArray arrayWithObjects:
                                    @"badauth", @"badsys", @"badagent", @"numhost", @"dnserr",
                                    @"911", @"999", @"!yours", @"abuse", @"nohost", @"good", @"nochg",
                                    @"notfqdn",nil] retain];
#define _badauth 0
#define _badsys 1
#define _badagent 2
#define _numhost 3
#define _dnserr 4
#define _911 5
#define _999 6
#define _notyours 7
#define _abuse 8
#define _nohost 9
#define _good 10
#define _nochg 11
#define _notfqdn 12

    _GMTTimeZone=[NSTimeZone timeZoneWithName:@"GMT"];
}

- (void)setServiceName:(NSString *)theName {
    NSLog(@"Warning: trying to change service name");
}

- (NSString *)getServiceName {
    return @"DynDNS.org";
}

- description {
    return @"<DynDNS.org updater>";
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
        return ((![[[theHost interface] getAddress] isEqualToString:[theHost getAddress]])||([[theHost lastUpdate] timeIntervalSinceNow]<-FORCEUPDATE_DAYS*24.0*3600.0))&&([[theHost interface] isActive]);
    }
    return NO;
}

- (void)updateHosts:(NSArray *)hosts user:(DUUser *)theUser withKey:(NSString *)key {
    NSString *query;
    NSURL *theURL;
    NSDictionary *serverOutput;
    NSArray *serverLines;
    NSString *line=nil;
    int serverCode;

    [DUUser updating];
    [theUser setUserStatus:@"Ok"];
    
    query=[NSString stringWithFormat:@"http://%@?hostname=%@&%@",
                            dynDNSURL,
                            [hosts componentsJoinedByString:@","],
                            key];
                            
    //NSLog(@"Query : %@",query);
    
    theURL=[NSURL URLWithString:query];

    NS_DURING
        serverOutput=getURL(theURL, [theUser getName], [theUser getPassword]);
    NS_HANDLER
        NSLog(@"Network unreachable: %@", localException);
        {
            NSEnumerator *hostEnumerator=[hosts objectEnumerator];
            DUHost *theHost;

            while(theHost=[hostEnumerator nextObject]) {
                [theHost setStatus:@"Network unreachable"];
            }

            return;
        }
    NS_ENDHANDLER

    if(!serverOutput) {
        NSLog(@"error while updating with DynDNS.org. Will retry later");
        //[theUser setActive:NO];
        [theUser setUserStatus:@"No Server Answer"];
        {
            NSEnumerator *hostEnumerator=[hosts objectEnumerator];
            DUHost *theHost;
            
            while(theHost=[hostEnumerator nextObject]) {
                NSDate *aDate=[NSDate dateWithTimeIntervalSinceNow:TIMETOWAIT];
                [theHost setStatus:@"Waiting"];
                [theHost setHostProperty:aDate forKey:@"DUDateForUpdate"  internalProperty:YES];
            }
        }
        [theUser addATry];
        if([theUser tries]>MAX_TRIES) {
            NSEnumerator *hostEnumerator=[hosts objectEnumerator];
            DUHost *theHost;
            
            while(theHost=[hostEnumerator nextObject]) {
                [theHost setActive:NO];
            }
            [theUser resetTries];
        }
        return;
    }
    
    [theUser resetTries];
    
    serverLines=[serverOutput objectForKey:Output];
    serverCode=[[serverOutput objectForKey:ServerCode] intValue];

    //NSLog(@"server output: %@",serverLines);
    
    switch(serverCode) {
        case HTTPBADAUTH:
        case HTTPSUCCESSCODE:
            break;
        case 502:
            NSLog(@"502 error (Proxy error)");
            [hosts makeObjectsPerformSelector:@selector(setStatus:) withObject:@"No Server Answer"];
            return;
        default:
            NSLog(@"While updating, unexpected DynDNS.org server code: %i (Contact support: %@)",serverCode,authorMail);
            NSLog(@"Server output: %@",serverLines);
            [theUser setUserStatus:@"DynDNS Critical"];
            [theUser setActive:NO];
            return;
    }
    
    if([serverLines count]==[hosts count]) {
        // the output is, a priori, for each host (except if there is
        // just one host)
        NSEnumerator *hostEnumerator=[hosts objectEnumerator];
        NSEnumerator *lineEnumerator=[serverLines objectEnumerator];
        DUHost *host;

        //NSLog(@"Analyzing output for each host");
        
        while(line=[lineEnumerator nextObject]) {
            NSString *command, *argument;
            NSRange aRange;
            int theCommand;
            BOOL notAnHostCommand=NO;
            
            host=[hostEnumerator nextObject];
            aRange=[line rangeOfCharacterFromSet:_whiteSpaces];
            if(aRange.length==0) {
                // no argument
                command=line;
                argument=nil;
            } else {
                command=[line substringWithRange: NSMakeRange(0,aRange.location)]; // XXX should try to remove
                argument=[line substringFromIndex: aRange.location+1];	           // leading white spaces
            }
            
            theCommand=[_returnCommands indexOfObject:command];
            
            //NSLog(@"command : %@",[_returnCommands objectAtIndex:theCommand]);
            
            // test if line is a good response for a host
            // else break (and will be treated as a global error or wait)
            switch(theCommand) {
                case _notyours:
                    NSLog(@"%@: not owned by %@ (Deactivating this host for this user)",host,theUser);
                    [host setActive:NO];
                    [host setStatus:@"Not yours"];
                    break;
                case _abuse:
                    NSLog(@"%@: host blocked for abuse (Deactivating this host for this user)",host);
                    [host setActive:NO];
                    [host setStatus:@"Abuse"];
                    break;
                case _nohost:
                    NSLog(@"%@: no such host in database (Deactivating this host for this user)",host);
                    [host setActive:NO];
                    [host setStatus:@"No such host"];
                    break;
                case _good:
                    NSLog(@"%@: update suceeded",host);
                    [host updateAddressTo:[[host interface] getAddress]]; // XXX must cache all those addresses
                    [host setStatus:@"Ok"];
                    break;
                case _nochg:
                    NSLog(@"%@: no need to update. Beware of abuse",host);
                    [host updateAddressTo:[[host interface] getAddress]]; // XXX must cache all those addresses
                    [host setStatus:@"Ok"];
                    break;
                case _notfqdn:
                    NSLog(@"%@: not a fully qualified domain name (Deactivating this host for this user)",host);
                    [host setActive:NO];
                    [host setStatus:@"Bad domain name"];
                    break;
                default:
                    notAnHostCommand=YES;
            }
            
            if(notAnHostCommand)
                break;  // not an host return command, should be an other command
        }
    } else if([serverLines count]!=1) {
        // output should be 1 only line or 1 line per host
        NSLog(@"unexpected DynDNS.org output : %@",serverLines);
        [theUser setUserStatus:@"DynDNS Critical (2)"];
        [theUser setActive:NO];
        return;
    } else line=[serverLines objectAtIndex:0];
    
    if (line) {
        // the output is a global error or wait
        // badauth, badsys, badagent, numhost, dnserr, 911, 999
        // or wXX[smh] or wuHHMM
        NSString *command, *argument;
        NSRange aRange;
        int theCommand;
                
        aRange=[line rangeOfCharacterFromSet:_whiteSpaces];
        if(aRange.length==0) {
            // no argument
            command=line;
            argument=nil;
        } else {
            command=[line substringWithRange: NSMakeRange(0,aRange.location)]; // XXX should try to remove
            argument=[line substringFromIndex: aRange.location+1];	       // leading white spaces
        }
            
        theCommand=[_returnCommands indexOfObject:command];
        
        switch(theCommand) {
            case _badauth:
                NSLog(@"Login failed for user %@ (Deactivating this user)",theUser);
                [theUser setUserStatus:@"Bad Auth"];
                [theUser setActive:NO];
                break;
            case _badsys:
                NSLog(@"Bad system parameters. Odd. (Contact support: %@)",authorMail);
                [theUser setUserStatus:@"DNSUpdate Critical"];
                [theUser setActive:NO];
                break;
            case _badagent:
                NSLog(@"DynDNS.org does not appreciate this agent: %@ (Contact support: %@)", UserAgent, authorMail);
                [theUser setUserStatus:@"Bad Agent"];
                [theUser setActive:NO];
                break;
            case _numhost:
                NSLog(@"Too many or too few hosts found. Odd (Contact the author: %@)",authorMail);
                [theUser setUserStatus:@"Num. Host"];
                [theUser setActive:NO];
                break;
            case _dnserr:
                NSLog(@"DynDNS.org DNS error. Report the following line to DynDNS.org support departement :\nPacket ID: %@",(argument?argument:@"NoPacketId"));
                [theUser setUserStatus:@"DNS Error"];
                [theUser setActive:NO];
                break;
            case _911:
                NSLog(@"DynDNS.org is shut down. Reactivate until notified otherwise via :\n<http://www.dyndns.org/status.shtml>");
                [theUser setUserStatus:@"DNS Down"];
                [theUser setActive:NO];
                break;
            case _999:
                NSLog(@"DynDNS.org is shut down. Reactivate until notified otherwise via :\n<http://www.dyndns.org/status.shtml>");
                [theUser setUserStatus:@"DNS Down"];
                [theUser setActive:NO];
                break;
            default:
                // should be a wait command
                if([command hasPrefix:@"w"]) {

                    NSDate *untilDate=nil;

                    if([command hasPrefix:@"wu"]) {
                        // wait until command
                        NSString *waitArgument=[command substringFromIndex:2];
                        NSString *waitHour, *waitMinute;
                        
                        if(([command length]==4)&&(![waitArgument rangeOfCharacterFromSet:_nonDigitSet].length)) {
                            waitHour=[waitArgument substringToIndex:2];
                            waitMinute=[waitArgument substringFromIndex:2];
                            untilDate=[NSDate dateWithString:
                                            [NSString stringWithFormat:
                                                [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %@:%@:00 +0000"
                                                            timeZone:_GMTTimeZone
                                                            locale:nil], waitHour, waitMinute]];
                            if([untilDate timeIntervalSinceNow]<-TIMELOST) {
                                // the date is for tommorrow then add 24h to untilDate
                                untilDate=[[[NSDate alloc]
                                                initWithTimeInterval:24*3600.0 sinceDate:untilDate] autorelease];
                            }
                        }
                    } else {
                        // wait time interval command
                        NSString *interval;
                        char unit;
                        
                        if([command length]==4) {
                            interval=[command substringWithRange:NSMakeRange(1,2)];
                            unit=*[[command substringFromIndex:3] cString];
                            if(![interval rangeOfCharacterFromSet:_nonDigitSet].length) {
                                float timeInterval=(float)[interval intValue];
                                BOOL unitIsOk=YES;
                                
                                switch(unit) {
                                    case 'h':
                                        timeInterval*=3600.0;
                                        break;
                                    case 'm':
                                        timeInterval*=3600.0;
                                        break;
                                    case 's':
                                        break;
                                    default:
                                        unitIsOk=NO;
                                }
                                if(unitIsOk) {
                                    untilDate=[NSDate dateWithTimeIntervalSinceNow:timeInterval];
                                }
                            }
                        }
                    }
                    
                    if(!untilDate) {
                        NSLog(@"While updating, wrong wait command: %@ (Contact support: %@)",command,authorMail);
                        [theUser setUserStatus:@"DynDNS Wait Error"];
                        [theUser setActive:NO];
                        return;
                    }
                    {
                        NSEnumerator *hostEnumerator=[hosts objectEnumerator];
                        DUHost *host;

                        while(host=[hostEnumerator nextObject]) {
                            [host setStatus:@"Waiting"];
                            [host setHostProperty:untilDate forKey:@"DUDateForUpdate"  internalProperty:YES];
                        }
                    }
                    
                }
        }
    }
}

- (BOOL)isValidOption:(NSString *)theOption {
    return [_dyndnsValidOptions member:theOption]!=nil;
}

- (BOOL)canGroupHosts {
    return YES;
}

- (NSString *)ipOption {
    return @"myip";
}

@end
