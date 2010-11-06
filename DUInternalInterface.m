//
//  DUInternalInterface.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUInternalInterface.h"

#include <SystemConfiguration/SystemConfiguration.h>


@implementation DUInternalInterface

+ (DUInterface *)internalInterfaceWithName:(NSString *)theName interface:(NSString *)theInterface {
    return [[[self alloc] initWithName:theName interface:theInterface] autorelease];
}

- (DUInterface *)initWithName:(NSString *)theName interface:(NSString *)theInterface {
    interface=[theInterface copy];
    
    [super initWithName:theName];

    return self;
}

- (NSString *)description {
    return interface;
}

- (void)cacheAddress {
    NSString *ipAddress=nil;
    SCDynamicStoreRef dynRef=SCDynamicStoreCreate(NULL, (CFStringRef)@"DNSUpdate daemon", NULL, NULL);
    NSDictionary *objects;
    NSArray *addresses;
    
    if(!dynRef) {
        if([self isActive]) {
            NSLog(@"\"%@\": can't contact system configuration",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;

        cachedIP=nil;
        return;
    }

    objects=(NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)[NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4",interface]);

    if(!objects) {
        if([self isActive]) {
            NSLog(@"\"%@\": No such interface",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }
    
    addresses=[objects objectForKey:@"Addresses"];
    if(!addresses) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't get addresses",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        [objects release];
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }
    
    ipAddress=[[[addresses objectAtIndex:0] copy] autorelease];
    if(!ipAddress) {
        if([self isActive]) {
            NSLog(@"\"%@\": Can't get address",self);
            [DUInterface setMustNotifyObservers];
        }

        [self setActive:NO];

        interfaceError=DUIPCheckError;
        [objects release];
        CFRelease(dynRef);
        cachedIP=nil;
        return;
    }

    if(![self isActive]) {
        NSLog(@"Activate interface %@",[self getName]);
        [DUInterface setMustNotifyObservers];
    }
    
    [self setActive:YES];
    
    [objects release];
    CFRelease(dynRef);
    cachedIP=[ipAddress retain];
}

- (void)dealloc {
    [interface release];
    [super dealloc];
}

@end

/* Old one
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/route.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <strings.h>

@implementation DUInternalInterface

+ (DUInterface *)internalInterfaceWithName:(NSString *)theName interface:(NSString *)theInterface {
    return [[[DUInternalInterface alloc] initWithName:theName interface:theInterface] autorelease];
}

- (DUInterface *)initWithName:(NSString *)theName interface:(NSString *)theInterface {
    interface=[theInterface copy];
    
    [super initWithName:theName];

    return self;
}

- (NSString *)description {
    return interface;
}

- (NSString *)getAddress {
    int s;
    struct ifreq interf;
    struct sockaddr_in *sin;
    NSString *ipAddress=nil;
    
    if((s=socket(AF_INET,SOCK_DGRAM,0))<0) {
        interfaceError=DUIPCheckError;

        if([self isActive])
            NSLog(@"Can't form socket to test interface \"%@\"",[self getName]);
        
        [self setActive:NO];
        return nil;
    }
    
    strcpy(interf.ifr_name,[[self description] lossyCString]);
    interf.ifr_addr.sa_family=AF_INET;
    
    if(ioctl(s,SIOCGIFADDR,&interf)<0) {
        close(s);
        
        if([self isActive])
            NSLog(@"\"%@\": no such interface",self);

        [self setActive:NO];

        interfaceError=DUIPCheckError;

        return nil;
    }

    sin=(struct sockaddr_in *)&(interf.ifr_addr);

    close(s);
    ipAddress=[NSString stringWithCString:inet_ntoa(sin->sin_addr)];
    
    if(![self isActive]) {
        NSLog(@"Activate interface %@",[self getName]);
    }
    
    [self setActive:YES];
    
    return ipAddress;
}

- (void)dealloc {
    [interface release];
    [super dealloc];
}

@end
*/