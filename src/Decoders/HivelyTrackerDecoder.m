//
//  HivelyTrackerDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 12/06/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "HivelyTrackerDecoder.h"

@implementation HivelyTrackerDecoder

@synthesize type		= _type;
@synthesize audioDriver = _audioDriver;
@synthesize delegate	= _delegate;

- (id)init
{
	self = [super init];
	if (self)
	{
		_type = DECODER_HIVELY;
	}
	return self;
}

- (id)initWithDelegate: (id)theDelegate
{
	self = [self init];
	if (self)
	{
        _delegate = theDelegate;
	}
	return self;
}

- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver
{
	self = [self initWithDelegate:theDelegate];
	if (self)
	{
		_audioDriver = theDriver;
	}
	return self;
}

- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver andFilePath:(NSString*) theFilePath
{
	self = [self initWithDelegate:theDelegate andAudioDriver:theDriver];
	if (self)
		[self loadFile:theFilePath];
	return self;
}

- (BOOL)loadFile: (NSString*)theFilePath
{
	// Copy NSString to a C string
	char path[[theFilePath length]];
	strcpy(path, [theFilePath UTF8String]);
	
	// Initialize the replayer
	hvl_InitReplayer();
	
	// Attempt to create context
	// TODO: Option-ize defstereo
	_hvlModule = hvl_LoadTune(path, DEFAULT_SAMPLE_RATE, 2);
	
	if (!_hvlModule)
	{
		NSLog(@"Failed to open '%@' as a HivelyTracker module", [theFilePath lastPathComponent]);
		if (_delegate) [_delegate decoderLoadingWasUnsuccessful:self];
		return NO;
	}
	
	// Success
	if (_delegate) [_delegate decoderLoadingWasSuccessful:self];
	return YES;
}

- (void)dealloc
{
	NSLog(@"%@ dealloc", NSStringFromClass([self class]));
	
	// Free the HVL context
	if (_hvlModule)
	{
		hvl_FreeTune(_hvlModule);
		NSLog(@"HivelyTracker context freed.");
	}
}

- (BOOL)play
{
	_play = YES;
	
	_currentRow = -1;
	_currentPosition = -1;
	
	__block dispatch_semaphore_t semaphore = _audioDriver.semaphore;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
				   {
					   while (_play)
					   {
						   char buffer[DEFAULT_SAMPLE_RATE * 2 * 2 / 50];
						   memset(&buffer, 0, sizeof(buffer));
						   
						   hvl_DecodeFrame(_hvlModule, &buffer[0], &buffer[2], 4);
						   
						   while (!TPCircularBufferProduceBytes(_audioDriver.outputBuffer, buffer, sizeof(buffer)))
						   {
							   // Wait for semaphore
							   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
							   //usleep(15000);
						   }
						   
						   // Update UI if position/row changes
						   dispatch_async(dispatch_get_main_queue(), ^(void)
										  {
											  if (_delegate && _currentPosition != _hvlModule->ht_PosNr)
											  {
												  [_delegate positionNumberDidChange:self
																	   withPosNumber:_hvlModule->ht_PosNr];
											  }
											  _currentPosition = _hvlModule->ht_PosNr;
											  
											  if (_delegate && _currentRow != _hvlModule->ht_NoteNr)
											  {
												  [_delegate patternRowNumberDidChange:self
																		 withRowNumber:_hvlModule->ht_NoteNr
																	  andPatternLength:_hvlModule->ht_TrackLength];
											  }
											  _currentRow = _hvlModule->ht_NoteNr;
										  });
					   }
				   });
	[_audioDriver start];
	return YES;
}

- (BOOL)pause
{
	_play = NO;
	[_audioDriver stop];
	[_audioDriver flush];
	return YES;
}

- (BOOL)forwards
{
	// Don't allow the position to be increased past the length of the song
	if (_hvlModule->ht_PosNr + 1 >= _hvlModule->ht_PositionNr)
	{
		return NO;
	}
	
	// Insert a position jump command
	_hvlModule->ht_PosJump = _hvlModule->ht_PosNr + 1;
	
	// Signal a pattern break
	_hvlModule->ht_PatternBreak = 1;
	return YES;
}

- (BOOL)backwards
{
	// Don't allow the position to go negative
	_hvlModule->ht_PosJump = _hvlModule->ht_PosNr - 1 < 0 ? 0 : _hvlModule->ht_PosNr - 1;
	
	// Signal a pattern break
	_hvlModule->ht_PatternBreak = 1;
	return YES;
}

- (BOOL)stop
{
	[self pause];
	return YES;
}

- (BOOL)seekPosition: (int)position
{
	// Validate the position
	if (![self validatePosition:position])
	{
		return NO;
	}
	
	_hvlModule->ht_PosJump = position;
	
	// Signal a pattern break
	_hvlModule->ht_PatternBreak = 1;
	
	return YES;
}

- (BOOL)seekTimeMillis: (int)timeMillis
{
	return NO;
}

- (NSString*)fileFormat
{
	return @"AHX/HivelyTracker";
}

- (NSString*)songTitle
{
	return [NSString stringWithUTF8String: _hvlModule->ht_Name];
}

- (int)songLength
{
	return _hvlModule->ht_PositionNr;
}

- (int)channels
{
	return _hvlModule->ht_Channels;
}

- (PatternEvent)getPatternEventWithPosition: (int)position andTrack: (int)track andRow: (int)row
{
	int htTrack = _hvlModule->ht_Positions[position].pos_Track[track];
	int htTranspose = _hvlModule->ht_Positions[position].pos_Transpose[track];
	struct hvl_step *htStep = &_hvlModule->ht_Tracks[htTrack][row];
	
	// Blank notes
	PatternEvent e = {0};
	if (!htStep->stp_Note)
		e.note = PATTERNDATA_NOTE_SKIP;
	else
	{
		// Split notes and octaves
		e.note = (htStep->stp_Note + htTranspose - 1) % 12;
		e.octave = (htStep->stp_Note + htTranspose) / 12 + 1;
	}
	e.instrument = htStep->stp_Instrument;
	e.fx1Type = htStep->stp_FX;
	e.fx1Param = htStep->stp_FXParam;
	e.fx2Type = htStep->stp_FXb;
	e.fx2Param = htStep->stp_FXbParam;
	return e;
}

- (int)getNumberOfRowsWithPosition: (int)position
{
	return _hvlModule->ht_TrackLength;
}

- (BOOL)hasNextSubSong
{
	return NO;
}

- (BOOL)hasPreviousSubSong
{
	return NO;
}

- (BOOL)supportsSeeking
{
	return YES;
}

- (BOOL)supportsSubSongs
{
	return YES;
}

- (BOOL)supportsChannelMuting
{
	return NO;
}

- (BOOL)validatePosition: (int)position
{
	if (position < 0 || position >= _hvlModule->ht_PositionNr)
	{
		return NO;
	}
	return YES;
}

@end
