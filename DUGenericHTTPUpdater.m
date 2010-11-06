//
//  DUGenericHTTPUpdater.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Tue Feb 12 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUGenericHTTPUpdater.h"
#import "HTTPLoader.h"
#import "DUHost.h"
#import "DUUser.h"
#import "DUInterface.h"

@interface DUGenericHTTPUpdater (Private)

- (NSString *)_formKeyForHost:(DUHost *)host;
- (void)_updateHostGroupedForUser:(DUUser *)theUser;
- (void)_updateHostsNotGroupedForUser:(DUUser *)theUser;

@end


@implementation DUGenericHTTPUpdater

- (void)updateUser:(DUUser *)theUser {
    if([self canGroupHosts]) {
        [self _updateHostGroupedForUser:theUser];
    } else {
        [self _updateHostsNotGroupedForUser:theUser];
    }
}

- (void)updateHosts:(NSArray *)hosts user:(DUUser *)theUser withKey:(NSString *)key {
    // XXX must be implemented by subclass
}

- (BOOL)isValidOption:(NSString *)theOption {
    return YES;
}

- (BOOL)canGroupHosts {
    return NO;
}

- (NSString *)ipOption {
    return @"ip";
}

@end

@implementation DUGenericHTTPUpdater (Private)

- (NSString *)_formKeyForHost:(DUHost *)host {
    NSString *key=[NSString stringWithFormat:@"%@=%@",[self ipOption],[[host interface] getAddress]];

    /* Old DynDNS code
    if([host hostPropertyForKey:@"system"]) {
    */

    NSArray *hostKeys=[host propertiesKeys];
    NSEnumerator *keyEnumerator=[hostKeys objectEnumerator];
    id hostKey;
    id object;

    while(hostKey=[keyEnumerator nextObject]) {
        if([self isValidOption:hostKey]) {
            object=[host hostPropertyForKey:hostKey];
            key=[key stringByAppendingFormat:@"&%@=%@",hostKey,object];
        }
    }

    /* Old DynDNS code
    } else {
        key=[key stringByAppendingFormat:@"&system=dyndns"];
    }
    */

    return key;
}

- (void)_updateHostGroupedForUser:(DUUser *)theUser {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSArray *hosts=[theUser hosts];
    NSEnumerator *hostEnumerator=[hosts objectEnumerator];
    DUHost *host;
    NSMutableDictionary *toUpdate=[[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
    BOOL updateShow=NO;

    // test hosts to update
    while(host=[hostEnumerator nextObject]) {
        if([self needUpdate:host]) {
            NSString *key=[self _formKeyForHost:host];
            NSMutableArray *hostsForKey;

            hostsForKey=[toUpdate objectForKey:key];

            if(!updateShow) {
                NSLog(@"Updating user %@",theUser);
                updateShow=YES;
            }
            NSLog(@"%@ will be updated [key=%@]",host,key);
            if(!hostsForKey) {
                hostsForKey=[[[NSMutableArray alloc] initWithCapacity:1] autorelease];
                [toUpdate setObject:hostsForKey forKey:key];
            }
            [hostsForKey addObject:host];
        }
    }

    // Now update hosts
    {
        NSEnumerator *keyEnumerator=[toUpdate keyEnumerator];
        NSString *key;

        while(key=[keyEnumerator nextObject]) {
            hosts=[toUpdate objectForKey:key];
            [self updateHosts:hosts user:theUser withKey:key];
        }
    }

    [super updateUser:theUser];
    [pool release];
}

- (void)_updateHostsNotGroupedForUser:(DUUser *)theUser {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL updateShow=NO;
    NSArray *hosts=[theUser hosts];
    NSEnumerator *hostEnumerator=[hosts objectEnumerator];
    DUHost *host;

    while(host=[hostEnumerator nextObject]) {
        if([self needUpdate:host]) {
            NSString *key=[self _formKeyForHost:host];

            if(!updateShow) {
                updateShow=YES;
                NSLog(@"Updating user %@",theUser);                
            }
            
            NSLog(@"%@ will be updated [key=%@]",host,key);
            [self updateHosts:[NSArray arrayWithObject:host] user:theUser withKey:key];
        }
    }
    
    [pool release];
}

@end
