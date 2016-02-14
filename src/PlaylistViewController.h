//
//  PlaylistTableViewController.h
//  OSXMP
//
//  Created by Dale Whinham on 14/07/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlaylistViewController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource> {
@private
    // An array of dictionaries that contain the contents to display
    NSMutableArray *_playlistContents;
    IBOutlet NSTableView *_playlistView;
}

@end
