//
//  RRTouchRemote.h
//  BonjourWeb
//
//  Created by Rolandas Razma on 19/03/2015.
//
//

#import <Foundation/Foundation.h>

@class RRTouchRemoteService;
@protocol RRTouchRemoteDelegate;


@interface RRTouchRemote : NSObject

@property(nonatomic, weak) id <RRTouchRemoteDelegate>delegate;

- (instancetype)initWithName:(NSString *)name pairID:(NSUInteger)pairID;

- (void)startAdvertising;
- (void)stopAdvertising;

- (void)findServiceWithName:(NSString *)serviceName completionHandler:(void (^)(RRTouchRemoteService *service))completionHandler;

@end


@protocol RRTouchRemoteDelegate <NSObject>
@optional

- (void)touchRemote:(RRTouchRemote *)touchRemote didPairedWithServiceNamed:(NSString *)serviceName;

@end