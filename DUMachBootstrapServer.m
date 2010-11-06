//
//  DUMachBootstrapServer.m
//  DNSUpdate2
//
//  Created by Julien Jalon on 16/04/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DUMachBootstrapServer.h"

#include <mach/mach_port.h>
#include <mach/task.h>
#include <mach/task_special_ports.h>
#include <servers/bootstrap.h>

typedef struct _DUMBSReserved {
    mach_port_t bootstrapPort;
} DUMBSReserved;

#define _bootstrapPort (((DUMBSReserved *)du_reserved)->bootstrapPort)

@implementation DUMachBootstrapServer

+ (DUMachBootstrapServer *)defaultServer
{
    static DUMachBootstrapServer* server = nil;
    if(server == nil) {
        server = [[DUMachBootstrapServer alloc] init];
    }
    return server;
}

- (id)init
{
    self = [super init];
    
    du_reserved = calloc(1, sizeof(DUMBSReserved));
    
    _bootstrapPort = MACH_PORT_NULL;
    
    mach_port_t bPort = MACH_PORT_NULL;
    
    NSLog(@"Getting task bootstrap port");
    if(task_get_bootstrap_port(mach_task_self(), &bPort)) {
        NSLog(@"Can't get bootstrap port");
    } else {
#if 0
        NSLog(@"Getting priviledged bootstrap port");
        if(bootstrap_parent(bPort, &_bootstrapPort)) {
            NSLog(@"Can't get priviledged bootstrap port");
            mach_port_deallocate(mach_task_self(), bPort);
            _bootstrapPort = MACH_PORT_NULL;
        }
#else
        _bootstrapPort = bPort;
#endif
    }
    return self;
}

- (void)dealloc
{
    if(du_reserved) {
        if(_bootstrapPort != MACH_PORT_NULL) {
            mach_port_deallocate(mach_task_self(), _bootstrapPort);
        }
        free(du_reserved);
    }
    [super dealloc];
}

- (NSPort *)portForName:(NSString *)name {
    if(_bootstrapPort != MACH_PORT_NULL) {
        return nil;
    }
    
    char        cString[BOOTSTRAP_MAX_NAME_LEN+1];
    
    if(![name canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        return nil;
    }
    
    if(![name getCString:cString maxLength:BOOTSTRAP_MAX_NAME_LEN encoding:NSUTF8StringEncoding]) {
        return nil;
    }
    
    mach_port_t     resultPort = MACH_PORT_NULL;
    
    if(bootstrap_look_up(_bootstrapPort, cString, &resultPort)) {
        NSLog(@"Can't get port named %@", name);
        return nil;
    }
    
    return [[[NSMachPort alloc] initWithMachPort:resultPort] autorelease];
}

- (NSPort *)portForName:(NSString *)name host:(NSString *)host {
    if((host == nil) || [host isEqual:@""]) {
        return [self portForName:name];
    }

    return nil;
}

- (BOOL)registerPort:(NSPort *)port name:(NSString *)name {
    NSLog(@"Registering port with name %@", name);

    if(_bootstrapPort == MACH_PORT_NULL) {
        return NO;
    }
    
    char        cString[BOOTSTRAP_MAX_NAME_LEN+1];
    
    if(![name canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        return NO;
    }
    
    if(![name getCString:cString maxLength:BOOTSTRAP_MAX_NAME_LEN encoding:NSUTF8StringEncoding]) {
        return NO;
    }
    
    
    if(bootstrap_register(_bootstrapPort, cString, [(NSMachPort *)port machPort])) {
        NSLog(@"Can't register port named %@", name);
        return NO;
    }
    
    return YES;
}

- (BOOL)removePortForName:(NSString *)name {
    NSLog(@"Removing port with name %@", name);
    return NO;
}

@end
