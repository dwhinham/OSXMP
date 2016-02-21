//
//  PlaylistViewController.m
//  OSXMP
//
//  Created by Dale Whinham on 15/02/2016.
//  Copyright (c) 2016 Dale Whinham. All rights reserved.
//

#import "PlaylistViewController.h"

@implementation PlaylistViewController

@synthesize playlist = _playlist;

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Enable drag and drop for the NSTableView
    [_playlistView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];

    // Refresh the view with
    [_playlistView reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return (NSInteger)_playlist.count;
}

- (id)tableView:(NSTableView*) tableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex
{
    PlaylistItem* playlistItem = [_playlist playlistItemAtIndex:(NSUInteger)rowIndex];
    NSString* identifier = [tableColumn identifier];

    if ([identifier isEqualToString:@"Play"] && playlistItem.isPlaying)
    {
        return [NSImage imageNamed:@"controller-play"];
    }
    else if ([identifier isEqualToString:@"File"])
    {
        return [playlistItem.url lastPathComponent];
    }

    return nil;
}

- (void)reloadData
{
    [_playlistView reloadData];
}

- (void)addItems
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];

    [openPanel beginWithCompletionHandler:^(NSInteger returnCode)
     {
         if (returnCode != NSOKButton)
             return;

         if (!self->_playlist)
             return;

         for (NSURL* url in [openPanel URLs])
             [self->_playlist addPlaylistItem:[PlaylistItem playlistItemWithURL:url]];

         [self->_playlistView reloadData];
     }];
}

- (void)loadPlaylist
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:@[@"osxmplaylist"]];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel beginWithCompletionHandler:^(NSInteger returnCode)
     {
         if (returnCode != NSOKButton)
             return;

         [self->_playlist deserializeFromYAML: [openPanel URL]];
         [self->_playlistView reloadData];
     }];
}

- (void)savePlaylist
{
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"osxmplaylist"]];

    [savePanel beginWithCompletionHandler:^(NSInteger returnCode)
     {
         if (returnCode != NSOKButton)
             return;

         [self->_playlist serializeToYAML: [savePanel URL]];
     }];
}

#pragma mark Playlist control buttons
- (IBAction)playlistButtonsWereClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        // Add
        case 0:
            [self addItems];
            break;

        // Delete
        case 1:
        {
            [self->_playlist removePlaylistItemsAtIndexes:[_playlistView selectedRowIndexes]];
            [_playlistView deselectAll:nil];
            [_playlistView reloadData];
            break;
        }

        // Load
        case 2:
            [self loadPlaylist];
            break;

        // Save
        case 3:
            [self savePlaylist];
            break;
    }
}

#pragma mark Drag and drop operations
- (NSDragOperation)tableView:(NSTableView*) tableView
                validateDrop:(id) info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op
{
    return op == NSTableViewDropAbove;
}

- (BOOL)tableView:(NSTableView*) tableView
       acceptDrop:(id) info
              row:(NSInteger) row
    dropOperation:(NSTableViewDropOperation) dropOperation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];

    for (NSString* path in files)
    {
        PlaylistItem* item = [PlaylistItem playlistItemWithURL:[NSURL fileURLWithPath:path]];
        [_playlist insertPlaylistItem:item atIndex:(NSUInteger)row];
    }

    [_playlistView reloadData];
    return YES;
}

@end
