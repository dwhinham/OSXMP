//
//  AppDelegate.m
//  OSXMP
//
//  Created by Dale Whinham on 14/12/2013.
//

#import "AppDelegate.h"
#import <dispatch/dispatch.h>

// From the Entypo pictogram set
#define BUTTON_IMAGE_PREV  @"controller-jump-to-start"
#define BUTTON_IMAGE_PLAY  @"controller-play"
#define BUTTON_IMAGE_PAUSE @"controller-paus"
#define BUTTON_IMAGE_STOP  @"controller-stop"
#define BUTTON_IMAGE_NEXT  @"controller-next"

@implementation AppDelegate
{
    PlaylistItem* currentPlaylistItem;

    AudioDriver* audioDriver;
    id<Decoder> decoder;

    NSUInteger previousButtonLastPressed;

    PlayerState playerState;
    Playlist* playlist;
    PlaylistViewController* playlistViewController;
}

+ (NSUInteger)getTickCount
{
    // Static variable guaranteed to be zero-initialised
    static mach_timebase_info_data_t timebaseInfo;

    // Timebase info uninitialised?
    if (timebaseInfo.denom == 0)
        mach_timebase_info(&timebaseInfo);

    // Get the system tick count in nanoseconds
    uint64_t absTime = mach_absolute_time();
    uint64_t absTimeNanos = absTime * timebaseInfo.numer / timebaseInfo.denom;

    // Convert to milliseconds
    return (NSUInteger) (absTimeNanos / 1e6);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    playerState = STOPPED;
    statusBox.layer.cornerRadius = 5.0f;

    playlist = [[Playlist alloc] init];
    playlistViewController = [[PlaylistViewController alloc] initWithWindowNibName:@"Playlist"];
    playlistViewController.playlist = playlist;
}

- (void)openPlaylistItem:(PlaylistItem*)playlistItem
{
    if (currentPlaylistItem)
        currentPlaylistItem.isPlaying = NO;

    currentPlaylistItem = playlistItem;
    NSURL* url = playlistItem.url;

    if (!self->audioDriver)
    {
        self->audioDriver = [[AudioDriver alloc] init];
        if (!self->audioDriver)
        {
            NSAlert* errorMessage = [[NSAlert alloc] init];
            [errorMessage setMessageText:@"Couldn't open sound driver."];
            [errorMessage setAlertStyle:NSCriticalAlertStyle];
            [errorMessage beginSheetModalForWindow:self->mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
            return;
        }
    }

    if (self->decoder)
    {
        [self->decoder stop];
        self->decoder = nil;
    }

    // Is it a DigiBooster module?
    if ([url.pathExtension isEqualTo:@"dbm"])
    {
        self->decoder = [[DigiBoosterDecoder alloc] initWithDelegate:self andAudioDriver:self->audioDriver andFilePath:[url path]];
    }

    // Is it a Hively/AHX module?
    else if ([url.pathExtension isEqualTo:@"hvl"] || [url.pathExtension isEqualTo:@"ahx"])
    {
        self->decoder = [[HivelyTrackerDecoder alloc] initWithDelegate:self andAudioDriver:self->audioDriver andFilePath:[url path]];
    }

    // Use XMP to load
    else
    {
        self->decoder = [[XMPDecoder alloc] initWithDelegate:self andAudioDriver:self->audioDriver andFilePath:[url path]];
    }
}

- (void)openFile:(NSURL*)url
{
    // File path
    if (currentPlaylistItem)
        currentPlaylistItem.isPlaying = NO;

    [self openPlaylistItem: [PlaylistItem playlistItemWithURL:url]];
}

- (IBAction)openFileWithDialog:(id)sender
{
    // Instantiate a file dialog
    NSOpenPanel* openDialog = [NSOpenPanel openPanel];

    // Set filters and options
    [openDialog setCanChooseFiles:YES];
    [openDialog setCanChooseDirectories:NO];
    [openDialog setAllowsMultipleSelection:NO];

    [openDialog beginWithCompletionHandler:^(NSInteger returnCode)
     {
         // TODO: Turn this into a proper load handler
         if (returnCode != NSOKButton)
             return;

         [self openFile:[openDialog URL]];

    }];
}

- (IBAction)changeVolume:(id)sender
{
    if (audioDriver)
    {
        [audioDriver setVolume:[sender floatValue]];
    }
}

- (IBAction)transportControlsWereClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        case 0:
            // Alt + button: previous position
            if ([NSEvent modifierFlags] & NSAlternateKeyMask)
                [decoder backwards];

            else if (previousButtonLastPressed && [AppDelegate getTickCount] - previousButtonLastPressed < 2000 && [playlist previous])
            {
                [self openPlaylistItem:[playlist currentPlaylistItem]];
                [playlistViewController reloadData];
            }
            else if (decoder)
            {
                [decoder seekPosition:0];
            }

            previousButtonLastPressed = [AppDelegate getTickCount];

            break;

        case 1:
            // Play/Pause button hit
            if (!decoder && playlist.count)
            {
                playerState = PLAYING;
                [self openPlaylistItem:[playlist currentPlaylistItem]];
                [playlistViewController reloadData];
            }
            else if (playerState != PLAYING)
            {
                playerState = PLAYING;
                [sender setImage:[NSImage imageNamed:BUTTON_IMAGE_PAUSE] forSegment:1];
                [decoder play];
                currentPlaylistItem.isPlaying = YES;
                [playlistViewController reloadData];
            }
            else
            {
                playerState = PAUSED;
                [sender setImage:[NSImage imageNamed:BUTTON_IMAGE_PLAY] forSegment:1];
                [decoder pause];
                currentPlaylistItem.isPlaying = NO;
                [playlistViewController reloadData];
            }

            break;

        case 2:
            // Stop button hit
            playerState = STOPPED;

            // Stop the decoder and release our reference to it
            [decoder stop];
            decoder = nil;

            // Set playlist item playing flag
            currentPlaylistItem.isPlaying = NO;

            // Reset the PatternScope
            [patternScope setDecoder:nil];
            [patternScope setNeedsDisplay:YES];

            // Reset the position and row counter
            [patternCounter setStringValue:@"00"];
            [positionCounter setStringValue:@"0/0"];

            // Reset the file format indicator
            [formatIndicator setStringValue:@""];

            // Reset the seek slider
            [seekSlider setEnabled:NO];
            [seekSlider setIntValue:0];
            [seekSlider setMaxValue:0];
            [seekSlider setNumberOfTickMarks:2];

            // Reset the status box
            [statusBox setStringValue:@"{ No song loaded }"];

            [sender setImage:[NSImage imageNamed:BUTTON_IMAGE_PLAY] forSegment:1];
            break;

        case 3:
            // Next button hit
            if ([NSEvent modifierFlags] & NSAlternateKeyMask)
                [decoder forwards];
            else if ([playlist next])
            {
                [self openPlaylistItem:[playlist currentPlaylistItem]];
                [playlistViewController reloadData];
            }
            break;

        default:
            break;
    }
}

- (IBAction)togglePlaylist:(id)sender
{
    NSButton* button = (NSButton*) sender;
    if ([[playlistViewController window] isVisible])
    {
        [button setState:NSOffState];
        [playlistViewController close];
    }
    else
    {
        [button setState:NSOnState];
        [playlistViewController showWindow: self];
    }
}

- (IBAction)togglePatternScope:(id)sender
{
    NSButton* button = (NSButton*) sender;
    if ([patternScopeWindow isVisible])
    {
        [button setState:NSOffState];
        [patternScopeWindow close];
    }
    else
    {
        [button setState:NSOnState];
        [patternScopeWindow makeKeyAndOrderFront:self];
    }
}

- (IBAction)patternScopeSetFontName:(NSPopUpButton *)sender
{
    [patternScope setFontName:[sender titleOfSelectedItem]];
}

- (IBAction)patternScopeSetFontSize:(NSSlider *)sender
{
    [patternScope setFontSize:[sender floatValue]];
}

- (IBAction)xmpSetSeparation:(id)sender
{
    //  if (xmpCtx)
    //  {
    //      xmp_set_player(xmpCtx, XMP_PLAYER_MIX, [sender intValue]);
    //  }
}

- (IBAction)xmpSetLerp:(id)sender
{
    if (decoder && [decoder type] == DECODER_XMP)
    {
        switch ([sender indexOfSelectedItem])
        {
            case 0:
                xmp_set_player(((XMPDecoder *)decoder).xmpContext, XMP_PLAYER_INTERP, XMP_INTERP_NEAREST);
                break;

            case 1:
                xmp_set_player(((XMPDecoder *)decoder).xmpContext, XMP_PLAYER_INTERP, XMP_INTERP_LINEAR);
                break;

            case 2:
                xmp_set_player(((XMPDecoder *)decoder).xmpContext, XMP_PLAYER_INTERP, XMP_INTERP_SPLINE);
                break;

            default:
                break;
        }
    }
}

- (void)decoderLoadingWasSuccessful:(id)sender
{
    NSString* songTitle = [[sender songTitle] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([songTitle length] == 0)
    {
        [statusBox setStringValue:[currentPlaylistItem.url lastPathComponent]];
    }
    else
    {
        [statusBox setStringValue: songTitle];
    }
    //[formatIndicator setStringValue:[NSString stringWithFormat:@"%@ (%d Ch.)", [sender fileFormat], [sender channels]]];
    [formatIndicator setStringValue:[sender fileFormat]];

    if ([sender supportsSeeking])
    {
        [patternCounter setStringValue:[NSString stringWithFormat:@"%02X", 0]];
        [positionCounter setStringValue:[NSString stringWithFormat:@"%d/%d", 0, [sender songLength] - 1]];

        [seekSlider setEnabled:YES];
        [seekSlider setIntValue:0];
        [seekSlider setMaxValue:[sender songLength]];
        [seekSlider setNumberOfTickMarks:[sender songLength] + 1];

        [patternScope setCurrentPosition:0];
        [patternScope setCurrentRow:0];
    }

    if ([sender conformsToProtocol:@protocol(PatternData)])
    {
        [patternScope setDecoder:sender];
        [patternScope setNeedsDisplay:YES];
    }

    if (playerState == PLAYING)
    {
        decoder = sender;
        [decoder play];
        currentPlaylistItem.isPlaying = YES;
    }
}

- (void)decoderLoadingWasUnsuccessful:(id)sender
{
    NSAlert* errorMessage = [[NSAlert alloc] init];
    [errorMessage setMessageText:@"Couldn't open file."];
    [errorMessage setAlertStyle:NSCriticalAlertStyle];
    [errorMessage beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark - DecoderDelegate

- (void)patternRowNumberDidChange:(id)sender withRowNumber:(unsigned int)rowNumber andPatternLength:(unsigned int)patternLength
{
    [patternCounter setStringValue:[NSString stringWithFormat:@"%02X", rowNumber]];
    [seekSlider setFloatValue:floorf([seekSlider floatValue]) + (float)rowNumber / (float)patternLength];
    [patternScope setCurrentRow:rowNumber];
}

- (void)positionNumberDidChange:(id)sender withPosNumber:(unsigned int)posNumber
{
    [positionCounter setStringValue:[NSString stringWithFormat:@"%d/%d", posNumber, [decoder songLength] - 1]];
    //[positionCounter setIntValue:posNumber];
    [seekSlider setIntValue:(signed)posNumber];
    [patternScope setCurrentPosition:posNumber];
}

- (void)playbackDidFinish:(id)sender
{
    NSLog(@"Playback finished");
    if (sender == decoder && [playlist next])
    {
        [self openPlaylistItem:[playlist currentPlaylistItem]];
        [playlistViewController reloadData];
    }
}

- (IBAction)seekSliderDidChangeValue:(NSSlider *)sender
{
    if (decoder.supportsSeeking)
    {
        unsigned int newPosition = (unsigned int) round([sender floatValue]);
        [decoder seekPosition: newPosition];
        [patternScope setCurrentRow: 0];
        [patternScope setCurrentPosition: newPosition];
    }
}

#pragma mark - PatternScope Options

- (IBAction)blankZeroCheckBoxWasClicked:(NSButton *)sender
{
    patternScope.blankZero = sender.state == NSOnState;
}

- (IBAction)prospectiveCheckBoxWasClicked:(NSButton *)sender
{
    patternScope.prospectiveMode = sender.state == NSOnState;
}

- (IBAction)lowercaseNotesCheckBoxWasClicked:(NSButton *)sender
{
    patternScope.lowercaseNotes = sender.state == NSOnState;
}

- (IBAction)lowercaseHexCheckBoxWasClicked:(NSButton *)sender
{
    patternScope.lowercaseHex = sender.state == NSOnState;
}
@end

