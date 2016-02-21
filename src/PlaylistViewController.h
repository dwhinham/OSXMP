//
//  PlaylistTableViewController.h
//  OSXMP
//
//  Created by Dale Whinham on 14/07/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Playlist.h"
#import "PlaylistItem.h"

@interface PlaylistViewController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView* _playlistView;
}

@property (nonatomic, readwrite, strong) Playlist* playlist;

- (void)reloadData;

@end
