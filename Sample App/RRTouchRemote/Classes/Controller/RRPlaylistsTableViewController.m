//
//  RRPlaylistsTableViewController.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//

#import "RRPlaylistsTableViewController.h"
#import "RRItemsTableViewController.h"


@implementation RRPlaylistsTableViewController {
    RRTouchRemoteService    *_touchRemoteService;
    NSUInteger  _databaseID;
    NSArray     *_playlists;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_touchRemoteService containersInDatabase: _databaseID
                                         meta: nil
                            completionHandler: ^(id containers , NSError *error) {
                                [self setPlaylists: containers[@"dmap.listing"][@"dmap.listingitem"]];
                            }];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if( [segue.identifier isEqualToString:@"RRItemsTableViewController"] ){
        RRItemsTableViewController *itemsTableViewController = segue.destinationViewController;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary *listingItem = _playlists[indexPath.row];
        
        [itemsTableViewController setTitle: listingItem[@"dmap.itemname"]];
        [itemsTableViewController setTouchRemoteService: _touchRemoteService];
        [itemsTableViewController setDatabaseID:_databaseID];
        [itemsTableViewController setContainerID: [listingItem[@"dmap.itemid"] unsignedIntegerValue]];
    }
    
}


#pragma mark -
#pragma mark RRPlaylistsTableViewController


- (void)setPlaylists:(NSArray *)playlists {
    _playlists = playlists;
    
    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _playlists.count;
}


#pragma mark -
#pragma mark UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *listingItem = _playlists[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RRPlaylistCell" forIndexPath:indexPath];
    [cell.textLabel setText: listingItem[@"dmap.itemname"]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"items: %@", listingItem[@"dmap.itemcount"]]];
    
    return cell;
}


@end
