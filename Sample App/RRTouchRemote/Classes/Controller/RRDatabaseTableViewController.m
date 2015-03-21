//
//  RRDatabaseTableViewController.m
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
