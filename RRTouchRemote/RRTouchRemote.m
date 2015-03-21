//
//  RRTouchRemote.m
//  BonjourWeb
//
//  Created by Rolandas Razma on 19/03/2015.
//
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
    NSUInteger          _netServiceOutputSendByteIndex;
    NSDictionary        *_netServiceRemoteRequest;
    NSData              *_netServiceHandshakeData;
    
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
                                                                                  @"Pair": [NSString stringWithFormat:@"%016lX", (unsigned long)_pairID]
                                                                               }]];
    [_netService setDelegate:self];
    
    [_netService publishWithOptions:NSNetServiceListenForConnections];
    
}


- (void)stopAdvertising {
    [_netService setDelegate:nil];
    [_netService stop];
    _netService = nil;
}


- (NSData *)netServiceHandshakeData {
    
    if( !_netServiceHandshakeData ){
        NSData *daapData = [RRDMAP dataFromDictionary: @{ @"cmpa": @{
                                                                  @"cmpg": @(_pairID),
                                                                  @"cmnm": _name}}];
        
        NSMutableData *httpData = [NSMutableData data];
        [httpData appendData: [@"HTTP/1.1 200 OK\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [httpData appendData: [[NSString stringWithFormat:@"Content-Length: %zu\r\n\r\n", daapData.length] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpData appendData: daapData];
        
        _netServiceHandshakeData = [httpData copy];
    }
    
    return _netServiceHandshakeData;
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


#pragma mark -
#pragma marl NSNetServiceDelegate


- (void)netService:(NSNetService *)service didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {

    _netServiceOutputSendByteIndex  = 0;
    _netServiceRemoteRequest        = nil;
    
    [inputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    [inputStream open];
    
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

            NSData *netServiceHandshakeData = self.netServiceHandshakeData;
            
            NSUInteger data_len = [netServiceHandshakeData length];
            uint8_t *readBytes = (uint8_t *)[netServiceHandshakeData bytes];
            
            readBytes += _netServiceOutputSendByteIndex;
            
            NSInteger len = ((data_len -_netServiceOutputSendByteIndex >= 1024) ? 1024 : (data_len -_netServiceOutputSendByteIndex));
            
            uint8_t buf[len];
            memcpy(buf, readBytes, len);
            
            len = [(NSOutputStream *)aStream write:(const uint8_t *)buf maxLength:len];
            
            _netServiceOutputSendByteIndex += len;
            
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            
            uint8_t buf[1024];
            NSInteger len = [(NSInputStream *)aStream read:buf maxLength:1024];
            
            if( len ) {
                NSData *data = [NSData dataWithBytes:buf length:len];

                // Parse out request URL
                NSScanner *scanner = [NSScanner scannerWithString: [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                [scanner scanUpToString:@"/pair" intoString:NULL];
                
                NSString *uri;
                [scanner scanUpToString:@" " intoString:&uri];

                NSURLComponents *components = [NSURLComponents componentsWithString:uri];
                NSMutableDictionary *remoteRequest = [NSMutableDictionary dictionary];
                for( NSURLQueryItem *queryItem in components.queryItems ){
                    [remoteRequest setObject:queryItem.value forKey:queryItem.name];
                }
                
                _netServiceRemoteRequest = [remoteRequest copy];
            }
            
            break;
        }
        case NSStreamEventEndEncountered: {
            
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            if( [aStream isKindOfClass:[NSOutputStream class]] ){
                _netServiceHandshakeData = nil;
                
                if( !_netServiceRemoteRequest[@"servicename"] ){
                    NSLog(@"hoi");
                    return;
                }
                if( [_delegate respondsToSelector:@selector(touchRemote:didPairedWithServiceNamed:)] ){
                    [_delegate touchRemote:self didPairedWithServiceNamed: _netServiceRemoteRequest[@"servicename"]];
                }
            }
            
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
