//
//  PlaylistItem.m
//  OSXMP
//
//  Created by Dale Whinham on 20/02/2016.
//  Copyright © 2016 Dale Whinham. All rights reserved.
//

#import "PlaylistItem.h"

@implementation PlaylistItem

@synthesize isPlaying   = _isPlaying;
@synthesize name        = _name;
@synthesize fileType    = _fileType;
@synthesize url         = _url;
@synthesize repeatCount = _repeatCount;
@synthesize length      = _length;

- (id)init
{
    self = [super init];
    if (self)
    {
        _isPlaying = NO;
    }
    return self;
}

+ (PlaylistItem*) playlistItemWithURL:(NSURL*) url
{
    PlaylistItem* item = [[PlaylistItem alloc] init];
    item.url = url;
    item.name = url.lastPathComponent;
    return item;
}

@end
