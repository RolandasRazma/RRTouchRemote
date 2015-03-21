//
//  RRGroupsTableViewController.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//

#import "RRGroupsTableViewController.h"


@implementation RRGroupsTableViewController {
    RRTouchRemoteService    *_touchRemoteService;
    NSUInteger  _databaseID;
    NSArray     *_groups;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_touchRemoteService groupsInDatabase: _databaseID
                                     type: RRGroupTypeAlbums
                                     meta: nil
                        completionHandler: ^(id groups, NSError *error) {
                            [self setGroups: groups[@"agal"][@"dmap.listing"][@"dmap.listingitem"]];
                        }];

}


#pragma mark -
#pragma mark RRGroupsTableViewController


- (void)setGroups:(NSArray *)groups {
    _groups = groups;
    
    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _groups.count;
}


#pragma mark -
#pragma mark UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *listingItem = _groups[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RRGroupCell" forIndexPath:indexPath];
    [cell.textLabel setText: listingItem[@"dmap.itemname"]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"items: %@", listingItem[@"dmap.itemcount"]]];

    return cell;
}


@end
