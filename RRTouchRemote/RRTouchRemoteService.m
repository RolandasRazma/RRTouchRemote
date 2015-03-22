//
//  RRTouchRemoteService.m
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

#import "RRTouchRemoteService.h"
#import "RRDMAP.h"


#define URL_ESCAPE( __STRING__ ) (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)__STRING__, NULL, CFSTR("*’;@&=$/?%#[]"), kCFStringEncodingUTF8)


@implementation RRTouchRemoteService {
    NSUInteger      _pairID;
    NSString        *_address;
    NSString        *_name;
    NSDictionary    *_serviceTXTRecordDictionary;
    
    NSString        *_sessionID;
}


#pragma mark -
#pragma mark RRTouchRemoteService


- (instancetype)initWithNetService:(NSNetService *)service pairID:(NSUInteger)pairID {
    if( (self = [super init]) ){

        _pairID  = pairID;
        _address = [NSString stringWithFormat:@"http://%@:%li", [service hostName], (long)[service port]];
        
        // TXTRecordData
        NSMutableDictionary *dictionary = [[NSNetService dictionaryFromTXTRecordData: [service TXTRecordData]] mutableCopy];
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSData *data, BOOL *stop) {
            [dictionary setObject: [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                           forKey: key];
        }];
        
        [self setServiceTXTRecordDictionary: [dictionary copy]];

    }
    return self;
}


- (void)setServiceTXTRecordDictionary:(NSDictionary *)dictionary {
    _serviceTXTRecordDictionary = dictionary;
    
    _name = dictionary[@"CtlN"];
}


- (NSURLRequest *)requestForPath:(NSString *)path queryItems:(NSDictionary *)queryItems {
    
    NSMutableDictionary *mutableQueryItems = queryItems?[queryItems mutableCopy]:[NSMutableDictionary dictionary];

    // add session-id
    if( _sessionID ){
        mutableQueryItems[@"session-id"] = _sessionID;
    }
    
    // construct query
    NSMutableString *mutablePath = [[_address stringByAppendingString:path] mutableCopy];
    [mutablePath appendString:@"?"];
    [mutableQueryItems enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if( [obj isKindOfClass: [NSArray class]] ){
            obj = [(NSArray *)obj componentsJoinedByString:@","];
        }else if( [obj isKindOfClass: [NSNumber class]] ){
            obj = [obj description];
        }
        
        [mutablePath appendFormat:@"%@=%@&", URL_ESCAPE(key), URL_ESCAPE(obj)];
    }];
    [mutablePath deleteCharactersInRange:NSMakeRange(mutablePath.length -1, 1)];

    // Add headers
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: mutablePath]];
    [request setValue:@"1"    forHTTPHeaderField:@"Viewer-Only-Client"];
    [request setValue:@"1.2"  forHTTPHeaderField:@"Client-ATV-Sharing-Version"];
    [request setValue:@"3.10" forHTTPHeaderField:@"Client-iTunes-Sharing-Version"];
    [request setValue:@"3.12" forHTTPHeaderField:@"Client-DAAP-Version"];

    return [request copy];
}


- (void)loginWithCompletionHandler:(void (^)(NSError *error))completionHandler {

    [NSURLConnection sendAsynchronousRequest: [self requestForPath: @"/login" queryItems:@{@"pairing-guid": [NSString stringWithFormat:@"0x%016lX", (unsigned long)_pairID]}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               
                               if ( [dictionary[@"dmap.loginresponse"][@"dmap.status"] intValue] == 200 ) {
                                   _sessionID = dictionary[@"dmap.loginresponse"][@"dmap.sessionid"];
                               }else if( !connectionError ){
                                   // generate error
                                   NSAssert(NO, @"Error");
                               }

                               completionHandler( connectionError );
                               
                           }];
    
}


- (void)serverInfoWithCompletionHandler:(void (^)(id serverInfo, NSError *error))completionHandler {

    [NSURLConnection sendAsynchronousRequest: [self requestForPath: @"/server-info" queryItems:nil]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary[@"dmap.serverinforesponse"], connectionError );
                               
                           }];
    
}


- (void)databasesWithCompletionHandler:(void (^)(id databases, NSError *error))completionHandler {
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: @"/databases" queryItems:nil]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary[@"daap.serverdatabases"], connectionError );
                               
                           }];
    
}


- (void)groupsInDatabase:(NSUInteger)databaseID type:(RRGroupType)type meta:(NSArray *)meta query:(NSString *)query completionHandler:(void (^)(id groups, NSError *error))completionHandler {

    NSString *groupType;
    switch ( type ) {
        case RRGroupTypeArtists: {
            groupType = @"artists";
            break;
        }
        case RRGroupTypeAlbums: {
            groupType = @"albums";
            break;
        }
    }
    
    meta = meta?:@[@"all"];
    query= query?:@"";

    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/groups", (unsigned long)databaseID]
                                                        queryItems: @{@"group-type":groupType, @"meta":meta, @"query": query}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary, connectionError );
                               
                           }];
    
}


- (void)containersInDatabase:(NSUInteger)databaseID meta:(NSArray *)meta completionHandler:(void (^)(id containers, NSError *error))completionHandler {

    meta = meta?:@[@"all"];

    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/containers", (unsigned long)databaseID]
                                                        queryItems: @{@"meta":meta}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary[@"daap.databaseplaylists"], connectionError );
                               
                           }];
}


- (void)itemsInDatabase:(NSUInteger)databaseID meta:(NSArray *)meta query:(NSString *)query completionHandler:(void (^)(id items, NSError *error))completionHandler {

    meta = meta?:@[@"all"];
    query= query?:@"";
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/items", (unsigned long)databaseID]
                                                        queryItems: @{@"meta":meta, @"query":query}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary[@"daap.databasesongs"], connectionError );
                               
                           }];
    
}


- (void)itemsInDatabase:(NSUInteger)databaseID containerID:(NSUInteger)containerID meta:(NSArray *)meta query:(NSString *)query completionHandler:(void (^)(id items, NSError *error))completionHandler {
    
    meta = meta?:@[@"all"];
    query= query?:@"";
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/containers/%lu/items", (unsigned long)databaseID, (unsigned long)containerID]
                                                        queryItems: @{@"meta":meta, @"query":query}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSDictionary *dictionary = [RRDMAP dictionaryFromData:data];
                               completionHandler( dictionary[@"daap.playlistsongs"], connectionError );
                               
                           }];
    
}


- (void)artworkForItemID:(NSUInteger)itemID inDatabaseID:(NSUInteger)databaseID completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler {
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/items/%lu/extra_data/artwork", (unsigned long)databaseID, (unsigned long)itemID]
                                                        queryItems: @{@"mw": @100, @"mh": @100}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               completionHandler( [UIImage imageWithData:data], connectionError );
                           }];
    
}


- (void)artworkForGroupID:(NSUInteger)groupID inDatabaseID:(NSUInteger)databaseID type:(RRGroupType)type completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler {
    
    NSString *groupType;
    switch ( type ) {
        case RRGroupTypeArtists: {
            groupType = @"artists";
            break;
        }
        case RRGroupTypeAlbums: {
            groupType = @"albums";
            break;
        }
    }
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/databases/%lu/groups/%lu/extra_data/artwork", (unsigned long)databaseID, (unsigned long)groupID]
                                                        queryItems: @{@"mw": @100, @"mh": @100, @"group-type": groupType}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               completionHandler( [UIImage imageWithData:data], connectionError );
                           }];
    
}


- (void)playItemID:(NSUInteger)itemID databaseID:(NSUInteger)databaseID completionHandler:(void (^)(NSError *error))completionHandler {
    
    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/ctrl-int/%lu/playqueue-edit", (unsigned long)databaseID]
                                                        queryItems: @{@"command": @"add", @"mode": @1, @"query": [NSString stringWithFormat:@"'dmap.itemid:%lu'", itemID]}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               completionHandler( connectionError );
                           }];
    
}


- (void)playSpecItemID:(NSUInteger)itemID databaseID:(NSUInteger)databaseID containerID:(NSUInteger)containerID completionHandler:(void (^)(NSError *error))completionHandler {

    [NSURLConnection sendAsynchronousRequest: [self requestForPath: [NSString stringWithFormat:@"/ctrl-int/%lu/playspec", (unsigned long)databaseID]
                                                        queryItems: @{
                                                                       @"database-spec": [NSString stringWithFormat:@"'dmap.persistentid:0x%016lX'", databaseID],
                                                                      @"container-spec": [NSString stringWithFormat:@"'dmap.persistentid:0x%016lX'", containerID],
                                                                           @"item-spec": [NSString stringWithFormat:@"'dmap.itemid:0x%016lX'", itemID]}]
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               completionHandler( connectionError );
                           }];
    
}


@end
