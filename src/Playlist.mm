//
//  Playlist.m
//  OSXMP
//
//  Created by Dale Whinham on 20/02/2016.
//  Copyright © 2016 Dale Whinham. All rights reserved.
//
#import "Playlist.h"
#import <yaml-cpp/yaml.h>

@implementation Playlist
{
    NSMutableArray* _playlistItems;
    NSUInteger _currentPlaylistIndex;
}

@synthesize name = _name;
@synthesize shuffle = _shuffle;
@synthesize repeat = _repeat;

- (id)init
{
    self = [super init];
    if (self)
    {
        _currentPlaylistIndex = 0;
        _playlistItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState: (NSFastEnumerationState *) enumerationState
                                  objects: (id __unsafe_unretained []) buffer
                                    count: (NSUInteger) len
{
    return [_playlistItems countByEnumeratingWithState: enumerationState
                                               objects: buffer
                                                 count: len];
}

- (PlaylistItem*)currentPlaylistItem
{
    return [_playlistItems objectAtIndex:_currentPlaylistIndex];
}

- (BOOL)goToIndex:(NSUInteger)index
{
    if (index > _playlistItems.count)
        return NO;

    _currentPlaylistIndex = index;
    return YES;
}

- (BOOL)next
{
    if (_currentPlaylistIndex + 1 >= _playlistItems.count)
        return NO;

    _currentPlaylistIndex++;
    return YES;
}

- (BOOL)previous
{
    if (_currentPlaylistIndex == 0)
        return NO;

    _currentPlaylistIndex--;
    return YES;
}

- (BOOL)deserializeFromYAML:(NSURL*)url
{
    NSError* error;
    NSString* yamlString = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

    if (!yamlString)
    {
        NSLog(@"Couldn't open file at %@ for reading: %@", url, [error localizedFailureReason]);
        return NO;
    }

    try
    {
        YAML::Node document = YAML::Load([yamlString UTF8String]);
        YAML::Node playlist = document["playlist"];
        if (playlist && playlist.IsMap())
        {
            YAML::Node playlistName = playlist["name"];
            YAML::Node playlistItems = playlist["items"];

            for (YAML::const_iterator it = playlistItems.begin(); it != playlistItems.end(); it++)
            {
                if (it->Type() != YAML::NodeType::Map)
                    continue;

                YAML::Node pathNode   = (*it)["path"];
                YAML::Node nameNode   = (*it)["name"];
                YAML::Node repeatNode = (*it)["repeat"];

                if (!pathNode)
                    continue;

                std::string path = pathNode.as<std::string>();
                NSURL* itemURL = [NSURL fileURLWithPath:[NSString stringWithCString:path.c_str() encoding:NSUTF8StringEncoding]];
                PlaylistItem* item = [PlaylistItem playlistItemWithURL:itemURL];

                if (nameNode)
                    item.name = [NSString stringWithCString:nameNode.as<std::string>().c_str() encoding:NSUTF8StringEncoding];

                if (repeatNode)
                    item.repeatCount = repeatNode.as<int>();

                [_playlistItems addObject:item];
            }
        }
    }
    catch (YAML::Exception e)
    {
        NSLog(@"Error parsing playlist %@: %s", url.path, e.what());
        return NO;
    }

    return YES;
}

- (BOOL)serializeToYAML:(NSURL*)url
{
    NSError* error;
    NSString* yamlString;
    YAML::Emitter out;

    out << YAML::Comment("OSXMP Playlist");
    out << YAML::Newline;
    out << YAML::Comment("vim: ft=yaml");
    out << YAML::BeginDoc;
    out << YAML::BeginMap;
    out << YAML::Key << "playlist";
    out << YAML::Value;
    out << YAML::BeginMap;

    if (_name)
    {
        out << YAML::Key << "name";
        out << YAML::Value << [_name UTF8String];
    }

    out << YAML::Key << "items";
    out << YAML::Value;
    out << YAML::BeginSeq;

    for (PlaylistItem* item in _playlistItems)
    {
        out << YAML::BeginMap;
        out << YAML::Key << "path";
        out << YAML::Value << [[item.url path] UTF8String];
        if (item.name)
        {
            out << YAML::Key << "name";
            out << YAML::Value << [item.name UTF8String];
        }
        out << YAML::Key << "repeat";
        out << YAML::Value << item.repeatCount;
        out << YAML::EndMap;
    }

    out << YAML::EndSeq;
    out << YAML::EndMap;
    out << YAML::EndMap;
    out << YAML::EndDoc;

    yamlString = [NSString stringWithCString:out.c_str() encoding:NSUTF8StringEncoding];

    if (![yamlString writeToFile:[url path] atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"Couldn't save playlist to %@: %@", url, [error localizedFailureReason]);
        return NO;
    }

    return YES;
}

- (NSUInteger)count
{
    return _playlistItems.count;
}

- (PlaylistItem*)playlistItemAtIndex:(NSUInteger)index
{
    return (PlaylistItem*)[_playlistItems objectAtIndex:index];
}

- (void)addPlaylistItem:(PlaylistItem*)playlistItem
{
    [_playlistItems addObject:playlistItem];
}

- (void)insertPlaylistItem:(PlaylistItem*)playlistItem atIndex:(NSUInteger)index
{
    [_playlistItems insertObject:playlistItem atIndex:index];
}

- (void)removeLastPlaylistItem
{
    [_playlistItems removeLastObject];
}

- (void)removePlaylistItemAtIndex:(NSUInteger)index
{
    [_playlistItems removeObjectAtIndex:index];
    if (_currentPlaylistIndex >= _playlistItems.count)
        _currentPlaylistIndex = _playlistItems.count - 1;
}

- (void)removePlaylistItemsAtIndexes:(NSIndexSet *)indexes
{
    [_playlistItems removeObjectsAtIndexes:indexes];
    if (_currentPlaylistIndex >= _playlistItems.count)
        _currentPlaylistIndex = _playlistItems.count - 1;
}

- (void)replacePlaylistItemAtIndex:(NSUInteger)index withPlaylistItem:(PlaylistItem*)playlistItem;
{
    [_playlistItems replaceObjectAtIndex:index withObject:playlistItem];
}

@end
