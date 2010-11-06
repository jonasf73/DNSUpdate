//
//  DUMachBootstrapServer.h
//  DNSUpdate2
//
//  Created by Julien Jalon on 16/04/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DUMachBootstrapServer : NSPortNameServer {
    void*   du_reserved;
}

+ (DUMachBootstrapServer *)defaultServer;

@end
