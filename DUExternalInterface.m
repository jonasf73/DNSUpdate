//
//  DUExternalInterface.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUExternalInterface.h"
#import "HTTPLoader.h"

NSString *ADDRESSTESTPREFIX=@"Current IP Address: ";
int prefixLength;

@implementation DUExternalInterface

+ (DUInterface *)externalInterfaceWithName:(NSString *)theName andURL:(NSString *)theURL {
    DUExternalInterface *interface=[[[self alloc] initWithName:theName URL:theURL] autorelease];
    [interface setURL:(NSString *)theURL];
    return interface;
}

- initWithName:(NSString *)theName URL:(NSString *)theURL {
    testURL=[[NSURL URLWithString:theURL] retain];
    [super initWithName:theName];
    lastUpdate=[[NSDate distantPast] retain];
    lastAddress=nil;
    
    prefixLength=[ADDRESSTESTPREFIX length];
    
    return self;
}

- (void)setURL:(NSString *)theURL {
    [testURL release];
    testURL=[[NSURL URLWithString:theURL] retain];
    [lastUpdate release];
    lastUpdate=[[NSDate distantPast] retain];
}

- (NSURL *)getURL {
    return [[testURL copy] autorelease];
}

- (void)cacheAddress {
    NSLog(@"Caching external address");
    if([lastUpdate timeIntervalSinceNow]<=-EXTIPTEST_INTERVAL*60.0) {
        NSDictionary *serverReturn;

        NS_DURING
            serverReturn=getURL(testURL,nil,nil);
        NS_HANDLER
            NSLog(@"Network unreachable: %@", localException);
            [self setActive:NO];
            cachedIP=nil;
            return;
        NS_ENDHANDLER
        
        if(serverReturn!=nil) {
            int serverCode;
            NSArray *serverOutput;
            NSEnumerator *lineEnumerator;
            NSString *line, *ipAddress=nil;

            serverCode=[[serverReturn objectForKey:ServerCode] intValue];
            if(serverCode!=HTTPSUCCESSCODE) {
                if([self isActive]) {
                    [DUInterface setMustNotifyObservers];
                }
                NSLog(@"Server answers error: %@",serverReturn);
                [self setActive:NO];
                cachedIP=nil;
                return;
            }
            serverOutput=[serverReturn objectForKey:Output];
            lineEnumerator=[serverOutput objectEnumerator];
            while(line=[lineEnumerator nextObject]) {
                NSRange	foundRange;

                foundRange = [line rangeOfString:ADDRESSTESTPREFIX];
                if(foundRange.location != NSNotFound) {
                    NSScanner*		scanner;
                    static 			NSCharacterSet*	ipCharSet = nil;
                    
                    scanner = [NSScanner scannerWithString:line];
                    [scanner setScanLocation:NSMaxRange(foundRange)];
                    if(ipCharSet == nil) {
                        ipCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] retain];
                    }
                    if([scanner scanCharactersFromSet:ipCharSet intoString:&ipAddress]) {
                        break;
                    }
                }
            }
            
            if(!line) {
                if([self isActive]) {
                    [DUInterface setMustNotifyObservers];
                }
                NSLog(@"While getting IP via External test, server answers something weird : %@", serverReturn);
                [self setActive:NO];
                cachedIP=nil;
                return;
            }

            [lastAddress release];
            [lastUpdate release];
            lastAddress=[ipAddress retain];
            lastUpdate=[[NSDate date] retain];
        } else {
            if([self isActive]) {
                [DUInterface setMustNotifyObservers];
            }
            NSLog(@"Error while getting IP via External test");
            [self setActive:NO];
            cachedIP=nil;
            return;
        }
        if(![self isActive]) {
            [DUInterface setMustNotifyObservers];
        }
        [self setActive:YES];
    }
    cachedIP=[lastAddress retain];
}

- description {
    return [testURL description];
}

- (void)dealloc {
    [lastUpdate release];
    [lastAddress release];
    [testURL release];
    
    [super dealloc];
}

@end
