//
//  HTTPLoader.m
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "HTTPLoader.h"

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
#include <SystemConfiguration/SystemConfiguration.h>

NSString *GetURLRunLoopMode = @"GetURLRunLoopMode";
NSString *ServerCode=@"ServerCode";
NSString *Output=@"Output";

typedef struct {
    BOOL	opened;
    BOOL	shouldContinue;
    NSMutableData*		responseBody;
} httpLoaderInfo;

// function to encode char *intext in base64
static char table64[]=
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
void base64Encode(char *intext, char *output) {
    unsigned char ibuf[3];
    unsigned char obuf[4];
    int i;
    int inputparts;
    
    while(*intext) {
        for (i = inputparts = 0; i < 3; i++) { 
            if(*intext) {
                inputparts++;
                ibuf[i] = *intext;
                intext++;
            }
            else
                ibuf[i] = 0;
        }
    
        obuf [0] = (ibuf [0] & 0xFC) >> 2;
        obuf [1] = ((ibuf [0] & 0x03) << 4) | ((ibuf [1] & 0xF0) >> 4);
        obuf [2] = ((ibuf [1] & 0x0F) << 2) | ((ibuf [2] & 0xC0) >> 6);
        obuf [3] = ibuf [2] & 0x3F;

        switch(inputparts) {
            case 1: /* only one byte read */
                sprintf(output, "%c%c==", 
                    table64[obuf[0]],
                    table64[obuf[1]]);
                break;
            case 2: /* two bytes read */
                sprintf(output, "%c%c%c=", 
                    table64[obuf[0]],
                    table64[obuf[1]],
                    table64[obuf[2]]);
                break;
            default:
                sprintf(output, "%c%c%c%cX", 
                    table64[obuf[0]],
                    table64[obuf[1]],
                    table64[obuf[2]],
                    table64[obuf[3]] );
                break;
        }
        output += 4;
    }
    *output=0;
}

void requestReadStreamCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
    httpLoaderInfo*		httpInfo = clientCallBackInfo;
    
    switch(type) {
        case kCFStreamEventOpenCompleted:
            httpInfo->opened = YES;
            return;
        case kCFStreamEventHasBytesAvailable: {
            CFIndex numBytesRead = 0;
            UInt8 *buffer;
            buffer = malloc(1024 * sizeof(UInt8));
            numBytesRead = CFReadStreamRead(stream, buffer, 1024);
            if(numBytesRead < 0) {
                NSLog(@"Error in reading of http stream");
                free(buffer);
                break;
            }
            if(numBytesRead > 0) {
                [httpInfo->responseBody appendBytes:buffer length:numBytesRead];
            }
            free(buffer);
            buffer = nil;
            return;
        }
        case kCFStreamEventEndEncountered:
            httpInfo->shouldContinue=NO;
            return;
        case kCFStreamEventErrorOccurred:
            httpInfo->shouldContinue=NO;
            return;
        default:
            NSLog(@"??? http stream event unexpected %d", type);
    }
            
}

NSDictionary *getURL(NSURL *theURL, NSString *user, NSString *password) {
    NSArray *lines;
    id toReturn;
    CFHTTPMessageRef	requestMessage;
    CFReadStreamRef		httpStream;
    CFStreamClientContext clientContext;
    httpLoaderInfo			requestInfo;
    BOOL					timedOut;

    if(!isNetworkReachable()) {
        [NSException raise:@"Network unreachable" format:@"Can't reach network, according to SysConf"];
    }
    
    // XXX this method should use NSURLHandle but NSURLHandle does not support Authentication

    requestMessage = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (CFURLRef)theURL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(requestMessage, CFSTR("User-Agent"), (CFStringRef)UserAgent);
    CFHTTPMessageSetHeaderFieldValue(requestMessage, CFSTR("Connection"), CFSTR("Close"));

    if(user&&password) {
        // get URL with authentification
        char auth[512],theUser[256];

        strcpy(theUser,[[NSString stringWithFormat:@"%@:%@", user, password] lossyCString]);
        base64Encode(theUser,auth);

        CFHTTPMessageSetHeaderFieldValue(requestMessage, CFSTR("Authorization"), (CFStringRef)[NSString stringWithFormat:@"Basic %s", auth]);
    }

    
    httpStream = CFReadStreamCreateForHTTPRequest(NULL, requestMessage);

    clientContext.version = 1;
    clientContext.info = &requestInfo;
    clientContext.retain = NULL;
    clientContext.release = NULL;
    clientContext.copyDescription = NULL;
    requestInfo.opened = NO;
    requestInfo.shouldContinue = YES;
    requestInfo.responseBody = [[NSMutableData alloc] init];
    
    CFReadStreamSetClient(httpStream, kCFStreamEventOpenCompleted | kCFStreamEventErrorOccurred | kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered, requestReadStreamCallBack, &clientContext);

    CFReadStreamScheduleWithRunLoop(httpStream, CFRunLoopGetCurrent(), (CFStringRef)GetURLRunLoopMode);

    if(!CFReadStreamOpen(httpStream)) {
    }
    
    timedOut = NO;
    while(requestInfo.shouldContinue) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if(CFRunLoopRunInMode((CFStringRef)GetURLRunLoopMode, TIMEOUT, YES) != kCFRunLoopRunHandledSource) {
            // it's a time out
            requestInfo.shouldContinue = NO;
            timedOut = YES;
        }
        [pool release];
    }

    CFReadStreamUnscheduleFromRunLoop(httpStream, CFRunLoopGetCurrent(), (CFStringRef)GetURLRunLoopMode);

    CFStreamStatus streamStatus = CFReadStreamGetStatus(httpStream);

    CFReadStreamClose(httpStream);
    CFRelease(requestMessage);

    if(timedOut) {
        CFRelease(httpStream);
        [NSException raise:@"Host unreachable" format:@"Time out before connection"];
    }
    
    CFHTTPMessageRef responseMessage;
    int				statusCode;
    NSString*		statusLine;
    NSDictionary*	headers;
    unsigned		lastpos;
    NSData*			responseData;
    NSString*		responseString;

    if(streamStatus == kCFStreamStatusError) {
//        NSLog(@"Can't connect to web server");
        CFRelease(httpStream);
        [NSException raise:@"Network unreachable" format:@"Can't connect to web server"];
    }
    
    responseMessage = (CFHTTPMessageRef)CFReadStreamCopyProperty(httpStream, kCFStreamPropertyHTTPResponseHeader);;
    CFRelease(httpStream);

    statusCode=CFHTTPMessageGetResponseStatusCode(responseMessage);
    statusLine=(NSString *)CFHTTPMessageCopyResponseStatusLine(responseMessage);
    headers=(NSDictionary *)CFHTTPMessageCopyAllHeaderFields(responseMessage);
    responseData=requestInfo.responseBody;
    responseString=[[NSString alloc] initWithData:responseData encoding:NSISOLatin1StringEncoding];
    //NSLog(@"%i - <<%@>>",statusCode,statusLine);
    //NSLog(@"%@",headers);
    //NSLog(@"---\n%@",responseString);
    CFRelease(responseMessage);
    [statusLine release];
    [headers release];
    [responseData release];

    lines=[responseString componentsSeparatedByString:@"\n"];
    [responseString release];
    lastpos=[lines count]-1;
    if(lastpos>=0) {
        if([[lines objectAtIndex:lastpos] isEqualToString:@""]) {
            //NSLog(@"removing last line");
            lines=[lines subarrayWithRange:NSMakeRange(0,lastpos)];
        }
    } else {
        NSLog(@"Strange output of server for request %@:\n---\n%@\n---",theURL,responseString);
        return nil;
    }

    toReturn=[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:statusCode], ServerCode,
        lines, Output, nil];

    return toReturn;
}

BOOL isNetworkReachable() {
    SCNetworkConnectionFlags result;
    
    if(!SCNetworkCheckReachabilityByName("www.apple.com", &result)) {
        /* ??? */
        return NO;
    }
    if(result&&kSCNetworkFlagsReachable) {
        return YES;
    }
    return NO;
}
