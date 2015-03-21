//
//  RRPlaylistsTableViewController.m
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
                                         meta: @[@"dmap.itemname", @"dmap.itemid", @"dmap.itemcount"]
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
