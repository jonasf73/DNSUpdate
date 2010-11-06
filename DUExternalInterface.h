//
//  DUExternalInterface.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUInterface.h"

#define EXTIPTEST_INTERVAL 15.0

@interface DUExternalInterface : DUInterface {
    NSDate *lastUpdate;
    NSString *lastAddress;
    NSURL *testURL;
}

+ (DUInterface *)externalInterfaceWithName:(NSString *)theName andURL:(NSString *)theURL;

- initWithName:(NSString *)theName URL:(NSString *)theURL;

- (void)setURL:(NSString *)theURL;
- (NSURL *)getURL;

@end
