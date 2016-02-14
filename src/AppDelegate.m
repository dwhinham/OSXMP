//
//  AppDelegate.m
//  OSXMP
//
//  Created by Dale Whinham on 14/12/2013.
//

#import "AppDelegate.h"

#import <dispatch/dispatch.h>

static NSURL* file;

static BOOL play = NO;

static AudioDriver* audioDriver = nil;
static id<Decoder> decoder = nil;

static NSTimer* levelMeterTimer = nil;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	statusBox.layer.cornerRadius = 5.0f;
}

- (IBAction)openFile:(id)sender
{
    // Instantiate a file dialog
    NSOpenPanel* openDialog = [NSOpenPanel openPanel];
    
    // Set filters and options
    [openDialog setCanChooseFiles:YES];
    [openDialog setCanChooseDirectories:NO];
    [openDialog setAllowsMultipleSelection:NO];
    
    [openDialog beginWithCompletionHandler:^(NSInteger returnCode)
	 {
		 if (returnCode == NSOKButton)
		 {
			 // File path
			 file = [openDialog URL];
			 
			 if (!audioDriver)
			 {
				 audioDriver = [[AudioDriver alloc] init];
				 if (!audioDriver)
				 {
					 NSAlert* errorMessage = [[NSAlert alloc] init];
					 [errorMessage setMessageText:@"Couldn't open sound driver."];
					 [errorMessage setAlertStyle:NSCriticalAlertStyle];
					 [errorMessage beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
					 return;
				 }
			 }
			 else
			 {
				 [audioDriver flush];
			 }
			 
			 if (decoder)
			 {
				 [decoder stop];
			 }
			 
			 // Is it a DigiBooster module?
			 if ([file.pathExtension isEqualTo:@"dbm"])
			 {
				 decoder = [[DigiBoosterDecoder alloc] initWithDelegate:self andAudioDriver:audioDriver andFilePath:[file path]];
			 }
			 
			 // Is it a Hively/AHX module?
			 else if ([file.pathExtension isEqualTo:@"hvl"] || [file.pathExtension isEqualTo:@"ahx"])
			 {
				 decoder = [[HivelyTrackerDecoder alloc] initWithDelegate:self andAudioDriver:audioDriver andFilePath:[file path]];
			 }
			 
			 // Use XMP to load
			 else
			 {
				 decoder = [[XMPDecoder alloc] initWithDelegate:self andAudioDriver:audioDriver andFilePath:[file path]];
			 }
		 }
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
	if (decoder)
	{
		switch ([sender selectedSegment])
		{
			case 0:
				// Previous button hit
				[decoder backwards];
				break;
			case 1:
				// Play/Pause button hit
				if (!play)
				{
					play = YES;
					[sender setLabel:@"" forSegment:1];
					[decoder play];
				}
				else
				{
					play = NO;
					[sender setLabel:@"" forSegment:1];
					[decoder pause];
				}
				
				break;
			case 2:
				[decoder stop];
				play = NO;
				[sender setLabel:@"" forSegment:1];
				decoder = nil;
				break;
			case 3:
				// Next button hit
				[decoder forwards];
				break;
			default:
				break;
		}
	}
}

- (IBAction)togglePlaylist:(id)sender
{
	if ([playlistWindow isVisible])
	{
		[playlistWindow close];
	}
	else
	{
		[playlistWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)openXMPControls:(id)sender
{
	[NSApp beginSheet:xmpControls
	   modalForWindow:mainWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)closeXMPControls:(id)sender
{
	[NSApp endSheet:xmpControls];
	[xmpControls orderOut:sender];
}

- (IBAction)togglePatternScope:(id)sender
{
	if ([patternScopeWindow isVisible])
	{
		[patternScopeWindow close];
	}
	else
	{
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
	//	if (xmpCtx)
	//	{
	//		xmp_set_player(xmpCtx, XMP_PLAYER_MIX, [sender intValue]);
	//	}
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
		[statusBox setStringValue:[file lastPathComponent]];
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
}

- (void)decoderLoadingWasUnsuccessful:(id)sender
{
	NSAlert* errorMessage = [[NSAlert alloc] init];
	[errorMessage setMessageText:@"Couldn't open file."];
	[errorMessage setAlertStyle:NSCriticalAlertStyle];
	[errorMessage beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark - DecoderDelegate

- (void)patternRowNumberDidChange:(id)sender withRowNumber:(int)rowNumber andPatternLength:(int)patternLength
{
	[patternCounter setStringValue:[NSString stringWithFormat:@"%02X", rowNumber]];
	[seekSlider setFloatValue:floor([seekSlider floatValue]) + (float)rowNumber / (float)patternLength];
	[patternScope setCurrentRow:rowNumber];
}

- (void)positionNumberDidChange:(id)sender withPosNumber:(int)posNumber
{
	[positionCounter setStringValue:[NSString stringWithFormat:@"%d/%d", posNumber, [decoder songLength] - 1]];
	//[positionCounter setIntValue:posNumber];
	[seekSlider setIntValue:posNumber];
	[patternScope setCurrentPosition:posNumber];
}

- (IBAction)seekSliderDidChangeValue:(NSSlider *)sender
{
	if (decoder.supportsSeeking)
	{
		int newPosition = round([sender floatValue]);
		[decoder seekPosition: newPosition];
		[patternScope setCurrentRow: newPosition];
	}
}

#pragma mark - PatternScope Options

- (IBAction)blankZeroCheckBoxWasPressed:(NSButton *)sender
{
	patternScope.blankZero = sender.state == NSOnState;
}

- (IBAction)prospectiveCheckBoxWasClicked:(NSButton *)sender
{
	patternScope.prospectiveMode = sender.state == NSOnState;
}

- (IBAction)lowercaseNotesCheckBoxWasPressed:(NSButton *)sender
{
	patternScope.lowercaseNotes = sender.state == NSOnState;
}

- (IBAction)lowercaseHexCheckBoxWasPressed:(NSButton *)sender
{
	patternScope.lowercaseHex = sender.state == NSOnState;
}
@end