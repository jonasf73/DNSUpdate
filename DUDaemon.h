//
//  DUDaemon.h
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DUDaemon : NSObject {

}

+ (DUDaemon *)sharedInstance;

- (oneway void)launch;
- (oneway void)updateDNS;

-(oneway void)daemonStart;
-(oneway void)pause;

-(BOOL)isPaused;

@end
