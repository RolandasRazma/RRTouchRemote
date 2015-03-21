//
//  RRMainViewController.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//

#import "RRMainViewController.h"
#import "RRTouchRemote.h"
#import "RRTouchRemoteService.h"
#import "RRDatabaseTableViewController.h"


@interface RRMainViewController () <RRTouchRemoteDelegate>

@end


@implementation RRMainViewController {
    RRTouchRemote           *_touchRemote;
    RRTouchRemoteService    *_touchRemoteService;
}


#pragma mark -
#pragma mark NSObject


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if( (self = [super initWithCoder:aDecoder]) ){
        // RRTouchRemote
        _touchRemote = [[RRTouchRemote alloc] initWithName:@"RRTouchRemote" pairID:1111];
        [_touchRemote setDelegate:self];
    }
    return self;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_touchRemote startAdvertising];

    // If you already have paired service you can connect to it directly
//    [_touchRemote findServiceWithName: @"97B2006B3FAC808A"
//                    completionHandler: ^(RRTouchRemoteService *service) {
//                        [self setTouchRemoteService: service];
//                    }];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_touchRemote stopAdvertising];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if( [segue.identifier isEqualToString:@"RRDatabaseTableViewController"] ){
        RRDatabaseTableViewController *databaseTableViewController = segue.destinationViewController;
        [databaseTableViewController setTouchRemoteService:_touchRemoteService];
    }
    
}


#pragma mark -
#pragma mark RRMainViewController


- (void)setTouchRemoteService:(RRTouchRemoteService *)service {
    _touchRemoteService = service;
    
    [self setTitle: service.name];
    
    [service loginWithCompletionHandler: ^(NSError *error){
        if( error ){
            NSLog(@"%@", error);
            return;
        }
        
        [self performSegueWithIdentifier:@"RRDatabaseTableViewController" sender:self];
    }];
}


#pragma mark -
#pragma mark RRTouchRemoteDelegate


- (void)touchRemote:(RRTouchRemote *)touchRemote didPairedWithServiceNamed:(NSString *)serviceName {

    NSLog(@"touchRemote:didPairedWithServiceNamed: %@", serviceName);
    
    [touchRemote findServiceWithName: serviceName
                   completionHandler: ^(RRTouchRemoteService *service) {
                       [self setTouchRemoteService: service];
                   }];
    
}


@end
