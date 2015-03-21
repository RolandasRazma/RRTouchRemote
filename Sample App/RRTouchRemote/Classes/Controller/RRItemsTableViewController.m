//
//  RRItemsTableViewController.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//

#import "RRItemsTableViewController.h"


@implementation RRItemsTableViewController {
    RRTouchRemoteService    *_touchRemoteService;
    NSUInteger  _databaseID;
    NSArray     *_items;
    NSUInteger  _containerID;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if( _containerID ){
        [_touchRemoteService itemsInDatabase: _databaseID
                                 containerID: _containerID
                                        meta: nil
                           completionHandler: ^(id items, NSError *error) {
                               [self setItems: items[@"dmap.listing"][@"dmap.listingitem"]];
                           }];
    }else{
        [_touchRemoteService itemsInDatabase: _databaseID
                                        meta: nil
                           completionHandler: ^(id items, NSError *error) {
                               [self setItems: items[@"dmap.listing"][@"dmap.listingitem"]];
                           }];
    }
    
}


#pragma mark -
#pragma mark RRItemsTableViewController


- (void)setItems:(NSArray *)items {
    _items = items;
    
    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}


#pragma mark -
#pragma mark UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *listingItem = _items[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RRItemCell" forIndexPath:indexPath];
    [cell.textLabel setText: listingItem[@"dmap.itemname"]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"album: %@ artist: %@", listingItem[@"daap.songalbum"], listingItem[@"daap.songalbumartist"]]];
    [cell.imageView setImage:[UIImage imageNamed:@"RRImagePlaceholder"]];

    [_touchRemoteService artworkForItemID: [listingItem[@"dmap.itemid"] unsignedIntegerValue]
                             inDatabaseID: _databaseID
                        completionHandler: ^(UIImage *image, NSError *error) {
                            [cell.imageView setImage:image];
                        }];
    
    return cell;
}


@end
