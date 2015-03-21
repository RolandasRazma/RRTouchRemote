//
//  RRDatabaseTableViewController.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//

#import "RRDatabaseTableViewController.h"
#import "RRGroupsTableViewController.h"


@implementation RRDatabaseTableViewController {
    RRTouchRemoteService    *_touchRemoteService;
    
    NSArray  *_databases;
}


#pragma mark -
#pragma mark UIViewController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ( [segue.identifier isEqualToString:@"RRDatabaseViewController"] ) {
        UITabBarController *tabBarController = segue.destinationViewController;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        NSDictionary *listingItem = _databases[indexPath.row];
        [tabBarController setTitle: listingItem[@"dmap.itemname"]];
        
        [tabBarController.viewControllers enumerateObjectsUsingBlock:^(id viewController, NSUInteger idx, BOOL *stop) {
            [viewController setTouchRemoteService:_touchRemoteService];
            [viewController setDatabaseID: [listingItem[@"dmap.itemid"] unsignedIntegerValue]];
        }];
        
    }

}


#pragma mark -
#pragma mark RRDatabaseTableViewController


- (void)setTouchRemoteService:(RRTouchRemoteService *)touchRemoteService {
    _touchRemoteService = touchRemoteService;
    
    [_touchRemoteService databasesWithCompletionHandler: ^(id databases, NSError *error) {
        [self setDatabases: databases[@"dmap.listing"][@"dmap.listingitem"]];
    }];
    
}


- (void)setDatabases:(NSArray *)databases {
    _databases = databases;

    [self.tableView reloadData];
}


#pragma mark -
#pragma mark UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _databases.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *listingItem = _databases[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RRDatabaseCell" forIndexPath:indexPath];
    [cell.textLabel setText: listingItem[@"dmap.itemname"]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"containers: %@ items: %@", listingItem[@"dmap.containercount"], listingItem[@"dmap.itemcount"]]];
    
    return cell;
}


@end
