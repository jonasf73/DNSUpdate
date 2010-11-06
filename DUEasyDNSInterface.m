//
//  DUEasyDNSInterface.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Tue Jul 21 2002.
//  Copyright (c) 2002 Julien Jalon. All rights reserved.
//

#import "DUEasyDNSInterface.h"


@implementation DUEasyDNSInterface

- (NSString *)getServiceName {
    return @"EasyDNS.com";
}

- (IBAction)goToEasyDNS:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.easydns.com/"]];
}

@end
