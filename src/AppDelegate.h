//
//  AppDelegate.h
//  OSXMP
//
//  Created by Dale Whinham on 14/12/2013.
//  Copyright (c) 2013 Dale Whinham. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

#import "libdigibooster3.h"

#import "AudioDriver.h"
#import "DigiBoosterDecoder.h"
#import "HivelyTrackerDecoder.h"
#import "XMPDecoder.h"

#import "PatternScopeView.h"
#import "Playlist.h"
#import "PlaylistViewController.h"

typedef NS_ENUM(NSUInteger, PlayerState)
{
	PLAYING,
	PAUSED,
	STOPPED
};

@interface AppDelegate : NSObject <NSApplicationDelegate, DecoderDelegate>
{
	IBOutlet NSWindow* mainWindow;
	IBOutlet NSWindow* patternScopeWindow;
	
	IBOutlet PatternScopeView* patternScope;
	
	IBOutlet NSTextField* statusBox;
	IBOutlet NSTextField* positionCounter;
	IBOutlet NSTextField* patternCounter;
	IBOutlet NSTextField* formatIndicator;

	IBOutlet NSSlider* seekSlider;
	IBOutlet NSSlider* volumeSlider;
}

- (IBAction)openFileWithDialog:(id)sender;
- (IBAction)changeVolume:(id)sender;
- (void)openPlaylistItem:(PlaylistItem*)playlistItem;

- (void)decoderLoadingWasSuccessful:(id)sender;
- (void)decoderLoadingWasUnsuccessful:(id)sender;
- (void)patternRowNumberDidChange:(id)sender withRowNumber:(int)rowNumber andPatternLength:(int)patternLength;
- (void)positionNumberDidChange:(id)sender withPosNumber:(int)posNumber;

- (IBAction)seekSliderDidChangeValue:(NSSlider *)sender;
@end
