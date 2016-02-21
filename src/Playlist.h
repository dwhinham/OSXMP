//
//  Playlist.h
//  OSXMP
//
//  Created by Dale Whinham on 20/02/2016.
//  Copyright © 2016 Dale Whinham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlaylistItem.h"

@interface Playlist : NSObject <NSFastEnumeration>

@property (nonatomic, readwrite) NSString* name;
@property (nonatomic, readwrite) BOOL shuffle;
@property (nonatomic, readwrite) BOOL repeat;

- (void)addPlaylistItem:(PlaylistItem*)playlistItem;
- (void)insertPlaylistItem:(PlaylistItem*)playlistItem atIndex:(NSUInteger)index;
- (void)removeLastPlaylistItem;
- (void)removePlaylistItemAtIndex:(NSUInteger)index;
- (void)removePlaylistItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replacePlaylistItemAtIndex:(NSUInteger)index withPlaylistItem:(PlaylistItem*)playlistItem;

@property (readonly) NSUInteger count;
- (PlaylistItem*)playlistItemAtIndex:(NSUInteger)index;

- (PlaylistItem*)currentPlaylistItem;
- (BOOL)goToIndex:(NSUInteger)index;
- (BOOL)next;
- (BOOL)previous;

- (BOOL)deserializeFromYAML:(NSURL*)path;
- (BOOL)serializeToYAML:(NSURL*)path;

@end
