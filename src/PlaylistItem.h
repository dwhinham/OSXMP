//
//  PlaylistItem.h
//  OSXMP
//
//  Created by Dale Whinham on 20/02/2016.
//  Copyright © 2016 Dale Whinham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaylistItem : NSObject

@property (nonatomic, assign, readwrite) BOOL isPlaying;
@property (nonatomic, strong, readwrite) NSString* name;
@property (nonatomic, strong, readwrite) NSString* fileType;
@property (nonatomic, strong, readwrite) NSURL* url;
@property (nonatomic, assign, readwrite) NSInteger repeatCount;
@property (nonatomic, assign, readwrite) NSTimeInterval length;

+ (PlaylistItem*) playlistItemWithURL:(NSURL*) URL;

@end
