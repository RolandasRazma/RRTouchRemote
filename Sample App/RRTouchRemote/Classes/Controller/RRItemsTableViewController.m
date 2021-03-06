//
//  RRItemsTableViewController.m
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

#import "RRItemsTableViewController.h"


@implementation RRItemsTableViewController {
    RRTouchRemoteService    *_touchRemoteService;
    NSUInteger  _databaseID;
    NSUInteger  _containerID;
    NSArray     *_items;
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if( _containerID ){
        [_touchRemoteService itemsInDatabase: _databaseID
                                 containerID: _containerID
                                        meta: @[@"dmap.itemname", @"dmap.itemid", @"daap.songalbum", @"daap.songalbumartist", @"com.apple.itunes.extended-media-kind"]
                                       query: @"('com.apple.itunes.extended-media-kind:1','com.apple.itunes.extended-media-kind:64')"
                           completionHandler: ^(id items, NSError *error) {
                               [self setItems: items[@"dmap.listing"][@"dmap.listingitem"]];
                           }];
    }else{
        [_touchRemoteService itemsInDatabase: _databaseID
                                        meta: @[@"dmap.itemname", @"dmap.itemid", @"daap.songalbum", @"daap.songalbumartist", @"com.apple.itunes.extended-media-kind"]
                                       query: @"'com.apple.itunes.extended-media-kind:1'"
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


#pragma mark -
#pragma mark UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *listingItem = _items[indexPath.row];
    
    // If its video
    if( [listingItem[@"com.apple.itunes.extended-media-kind"] intValue] == 64 ){
        [_touchRemoteService playSpecItemID: [listingItem[@"dmap.itemid"] unsignedIntegerValue]
                                 databaseID: _databaseID
                                containerID: _containerID
                          completionHandler: ^(NSError *error) {
                              
                          }];
    }else{
        [_touchRemoteService playItemID: [listingItem[@"dmap.itemid"] unsignedIntegerValue]
                             databaseID: _databaseID
                      completionHandler: ^(NSError *error) {
                          
                      }];
    }
    
}


@end
