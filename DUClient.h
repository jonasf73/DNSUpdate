//
//  DUClient.h
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 08 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUProtocols.h"

@interface DUClient : NSObject {

}

+ (id <DUProxy>)connectAndGetDaemonFor:delegate;

@end
