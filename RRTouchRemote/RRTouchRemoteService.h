//
//  RRTouchRemoteService.h
//  BonjourWeb
//
//  Created by Rolandas Razma on 20/03/2015.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, RRGroupType) {
    RRGroupTypeArtists,
    RRGroupTypeAlbums,
};


@interface RRTouchRemoteService : NSObject

@property (nonatomic, readonly) NSString *name;

- (instancetype)initWithNetService:(NSNetService *)service pairID:(NSUInteger)pairID;

- (void)loginWithCompletionHandler:(void (^)(NSError *error))completionHandler;
- (void)serverInfoWithCompletionHandler:(void (^)(id serverInfo, NSError *error))completionHandler;
- (void)databasesWithCompletionHandler:(void (^)(id databases, NSError *error))completionHandler;
- (void)groupsInDatabase:(NSUInteger)databaseID type:(RRGroupType)type meta:(NSArray *)meta completionHandler:(void (^)(id groups, NSError *error))completionHandler;
- (void)containersInDatabase:(NSUInteger)databaseID meta:(NSArray *)meta completionHandler:(void (^)(id containers, NSError *error))completionHandler;
- (void)itemsInDatabase:(NSUInteger)databaseID meta:(NSArray *)meta completionHandler:(void (^)(id items, NSError *error))completionHandler;
- (void)itemsInDatabase:(NSUInteger)databaseID containerID:(NSUInteger)containerID meta:(NSArray *)meta completionHandler:(void (^)(id items, NSError *error))completionHandler;
- (void)artworkForItemID:(NSUInteger)itemID inDatabaseID:(NSUInteger)databaseID completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler;

@end
