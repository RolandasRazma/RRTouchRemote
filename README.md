# RRTouchRemote
iTunes and AppleTV remote controll using DMAP protocol

```objc
RRTouchRemote *touchRemote = [[RRTouchRemote alloc] initWithName:@"RRTouchRemote" pairID:1111];
```

If you never did pairing
```objc
[touchRemote setDelegate:self];
[touchRemote startAdvertising];

- (void)touchRemote:(RRTouchRemote *)touchRemote didPairedWithServiceNamed:(NSString *)serviceName {

    NSLog(@"touchRemote:didPairedWithServiceNamed: %@", serviceName);
    
    [touchRemote findServiceWithName: serviceName
                   completionHandler: ^(RRTouchRemoteService *service) {
                       // ...
                   }];
    
}
```
Go to AppleTV or iTunes and add remote with any password (not checked)


If you did pairing and already have serviceName
```objc
[touchRemote findServiceWithName: @"service name"
	           completionHandler: ^(RRTouchRemoteService *service) {
			       // ...
               }];
```

Get all shared items
```objc
RRTouchRemoteService *service = ...
[touchRemoteService itemsInDatabase: _databaseID
                               meta: nil
                  completionHandler: ^(id items, NSError *error) {
				      // ...
                  }];
```