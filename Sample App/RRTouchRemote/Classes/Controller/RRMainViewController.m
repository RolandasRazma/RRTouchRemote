//
//  RRMainViewController.m
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
//    [_touchRemote findServiceWithName: @"7096C619659D3F7B"
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
