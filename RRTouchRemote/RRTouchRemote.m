//
//  RRTouchRemote.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "RRTouchRemote.h"
#import "RRDMAP.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import "RRTouchRemoteService.h"


@interface RRTouchRemote () <NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSStreamDelegate>

@end


@implementation RRTouchRemote {
    __weak id <RRTouchRemoteDelegate>_delegate;
    
    NSString            *_name;
    NSUInteger          _pairID;
    
    NSNetService        *_netService;
    NSOutputStream      *_netServiceOutputStream;
    NSDictionary        *_netServiceRemoteRequest;
    
    NSMutableData       *_inputStreamData;
    NSMutableData       *_outputStreamData;
    
    NSNetServiceBrowser *_netServiceBrowser;
    NSMutableSet        *_netServiceBrowserServices;
    void (^_lookingForServicesBlock)(NSNetService *service);
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    
    // Stop resolving
    for( NSNetService *service in _netServiceBrowserServices ){
        [service stop];
    }
    
    [_netService stop];
    [_netServiceBrowser stop];
}


#pragma mark -
#pragma mark RRTouchRemote


- (instancetype)initWithName:(NSString *)name pairID:(NSUInteger)pairID {
    if( (self = [super init]) ){
        _name   = name;
        _pairID = pairID;
    }
    return self;
}


- (void)startAdvertising {

    _netService = [[NSNetService alloc] initWithDomain: @"local"
                                                  type: @"_touch-remote._tcp"
                                                  name: _name
                                                  port: 0];
    
    [_netService setTXTRecordData: [NSNetService dataFromTXTRecordDictionary:@{
                                                                               @"txtvers": @"1",
                                                                                  @"DvNm": _name,
                                                                                  @"RemN": @"Remote",
                                                                                  @"Pair": [NSString stringWithFormat:@"%016lX", (unsigned long)_pairID],
                                                                                  @"RemV": @"10000",
                                                                                  @"DvTy": [[UIDevice currentDevice] model]}]];
    [_netService setDelegate:self];
    
    [_netService publishWithOptions:NSNetServiceListenForConnections];
    
}


- (void)stopAdvertising {
    [_netService setDelegate:nil];
    [_netService stop];
    _netService = nil;
}


- (void)startLookingForServicesUsingBlock:(void (^)(NSNetService *service))block {
    _lookingForServicesBlock = block;
    
    _netServiceBrowserServices = [NSMutableSet set];
    
    _netServiceBrowser = [NSNetServiceBrowser new];
    [_netServiceBrowser setDelegate:self];
    [_netServiceBrowser searchForServicesOfType:@"_touch-able._tcp" inDomain:@"local"];
}


- (void)stopLookingForServices {
    [_netServiceBrowser setDelegate:nil];
    [_netServiceBrowser stop];
    
    for( NSNetService *service in _netServiceBrowserServices ){
        [service setDelegate:nil];
        [service stop];
    }
    
    _netServiceBrowserServices  = nil;
    _netServiceBrowser          = nil;
    _lookingForServicesBlock    = nil;
}


- (void)findServiceWithName:(NSString *)serviceName completionHandler:(void (^)(RRTouchRemoteService *service))completionHandler {
    NSAssert(serviceName, @"No serviceName specifyed.");
    
    __weak RRTouchRemote *weakSelf = self;
    [self startLookingForServicesUsingBlock: ^( NSNetService *service ) {
        
        if( [service.name isEqualToString:serviceName] ){
            if( completionHandler ){
                completionHandler( [[RRTouchRemoteService alloc] initWithNetService:service pairID:_pairID] );
            }
            
            [weakSelf stopLookingForServices];
        }
        
    }];
    
}


- (void)readFromStream:(NSInputStream *)stream {
    
    if( !_inputStreamData ) {
        _inputStreamData = [NSMutableData data];
    }
    
    uint8_t buf[1024];
    NSInteger bufLength = [stream read:buf maxLength:1024];
    
    if( bufLength ) {
        [_inputStreamData appendBytes:buf length:bufLength];
        
        if ( bufLength > 4 && (memcmp(&buf[bufLength -4], "\r\n\r\n", 4) == 0) ) {
            
            // Parse out request URL
            NSScanner *scanner = [NSScanner scannerWithString: [[NSString alloc] initWithData:_inputStreamData encoding:NSUTF8StringEncoding]];
            [scanner scanUpToString:@"/pair" intoString:NULL];
            
            NSString *uri;
            [scanner scanUpToString:@" " intoString:&uri];
            
            NSURLComponents *components = [NSURLComponents componentsWithString:uri];
            NSMutableDictionary *remoteRequest = [NSMutableDictionary dictionary];
            for( NSURLQueryItem *queryItem in components.queryItems ){
                [remoteRequest setObject:queryItem.value forKey:queryItem.name];
            }
            
            _netServiceRemoteRequest = [remoteRequest copy];
            
            // Generate response
            NSData *daapData = [RRDMAP dataFromDictionary: @{ @"cmpa": @{
                                                                      @"cmpg": @(_pairID),
                                                                      @"cmnm": _name,
                                                                      @"cmty": [[UIDevice currentDevice] model]
                                                                      }}];

            _outputStreamData = [NSMutableData data];
            [_outputStreamData appendData: [[NSString stringWithFormat:@"HTTP/1.1 200 OK\r\nContent-Length: %zu\r\n\r\n", daapData.length] dataUsingEncoding:NSUTF8StringEncoding]];
            [_outputStreamData appendData: daapData];
        }
        
    }
    
}


- (void)writeToStream:(NSOutputStream *)stream {
    
    NSInteger bufferLength = MIN([_outputStreamData length], 1024);
    
    // do we have what to write?
    if( !bufferLength ){
        [self closeStream:stream];
        return;
    }

    uint8_t *readBytes = (uint8_t *)[_outputStreamData bytes];
    
    uint8_t buffer[bufferLength];
    memcpy(buffer, readBytes, bufferLength);
    
    bufferLength = [stream write:(const uint8_t *)buffer maxLength:bufferLength];
    
    [_outputStreamData replaceBytesInRange:NSMakeRange(0, bufferLength) withBytes:NULL length:0];
    
}


- (void)closeStream:(NSStream *)stream {
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if( [stream isKindOfClass:[NSOutputStream class]] ){
        if( [_delegate respondsToSelector:@selector(touchRemote:didPairedWithServiceNamed:)] ){
            [_delegate touchRemote:self didPairedWithServiceNamed: _netServiceRemoteRequest[@"servicename"]];
        }
        
        _netServiceRemoteRequest        = nil;
        _netServiceOutputStream         = nil;
        _outputStreamData               = nil;
    }else{
        _inputStreamData = nil;
    }
}


#pragma mark -
#pragma marl NSNetServiceDelegate


- (void)netService:(NSNetService *)service didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
    
    // NSInputStream
    [inputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    [inputStream open];
    
    // NSOutputStream
    [outputStream setDelegate:self];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    [outputStream open];
    
}


- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    if ( [_netServiceBrowserServices containsObject:service] ) {
        _lookingForServicesBlock( service );
        
        [_netServiceBrowserServices removeObject:service];
    }
    
}


#pragma mark -
#pragma mark NSStreamDelegate


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    switch( eventCode ) {
        case NSStreamEventHasSpaceAvailable: {
            if( _outputStreamData ){
                [self writeToStream:(NSOutputStream *)aStream];
            }else{
                _netServiceOutputStream = (NSOutputStream *)aStream;
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            [self readFromStream:(NSInputStream *)aStream];
            
            if( _outputStreamData && [_netServiceOutputStream hasSpaceAvailable] ){
                [self writeToStream: _netServiceOutputStream];
            }
            
            break;
        }
        case NSStreamEventEndEncountered: {
            [self closeStream:aStream];
            break;
        }
        case NSStreamEventErrorOccurred: {
            NSLog(@"NSStreamEventErrorOccurred %@", [aStream streamError]);
            break;
        }
        default: {
            break;
        }
    }
    
}


#pragma mark -
#pragma mark NSNetServiceBrowserDelegate


- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [_netServiceBrowserServices addObject:service];
    
    [service setDelegate:self];
    [service resolveWithTimeout:10.0f];
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [_netServiceBrowserServices removeObject:service];
    [service stop];
}


@end
