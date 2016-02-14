//
//  DigiBoosterDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 25/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "DigiBoosterDecoder.h"

@implementation DigiBoosterDecoder : NSObject

@synthesize type		= _type,
			audioDriver = _audioDriver,
			delegate	= _delegate;

// C callback for DigiBooster update events
static void db3Callback(void* udata, struct UpdateEvent* uevent)
{
	DigiBoosterDecoder* decoder = (__bridge DigiBoosterDecoder*)udata;
	
	if (uevent->ue_Order == -1)
		return;
	
	if (decoder->_delegate)
	{
		dispatch_async(dispatch_get_main_queue(), ^(void)
					   {
						   // Inform delegate of current row
						   int patternLength = decoder->_db3Module->Patterns[uevent->ue_Pattern]->NumRows;
						   [decoder->_delegate patternRowNumberDidChange:decoder withRowNumber:uevent->ue_Row andPatternLength:patternLength];

						   // If the position has changed, let the delegate know
						   if (decoder->_currentPosition != uevent->ue_Order)
							   [decoder->_delegate positionNumberDidChange:decoder withPosNumber:uevent->ue_Order];
					   });
	}
	
	// Update position counter
	decoder->_currentPosition = uevent->ue_Order;
}

- (id)init
{
	self = [super init];
	if (self)
		_type = DECODER_DB3;

	return self;
}

- (id)initWithDelegate: (id)theDelegate
{
	self = [self init];
	if (self)
        _delegate = theDelegate;

	return self;
}

- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver
{
	self = [self initWithDelegate:theDelegate];
	if (self)
		_audioDriver = theDriver;

	return self;
}

- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver andFilePath:(NSString*) theFilePath
{
	self = [self initWithDelegate:theDelegate andAudioDriver:theDriver];
	if (self)
		[self loadFile:theFilePath];

	return self;
}

- (BOOL)loadFile:(NSString*) theFilePath
{
	// Copy NSString to a C string
	char path[theFilePath.length + 1];
	strcpy(path, [theFilePath UTF8String]);
	
	// Error code
	int err = 0;
	
	// Workaround for bug: https://github.com/grzegorz-kraszewski/libdigibooster3/issues/1
	errno = 0;
	
	_db3Module = DB3_Load(path, &err);
	if (!_db3Module)
	{
		NSLog(@"Failed to open '%@' as a DigiBooster3 module (error code %d)", [theFilePath lastPathComponent], err);
		if (_delegate) [_delegate decoderLoadingWasUnsuccessful:self];
		return NO;
	}
	
	_db3Engine = DB3_NewEngine(_db3Module, DEFAULT_SAMPLE_RATE, DEFAULT_SAMPLE_RATE);
	if (!_db3Engine)
	{
		NSLog(@"Failed to create DigiBooster3 module renderer");
		if (_delegate) [_delegate decoderLoadingWasUnsuccessful:self];
		return NO;
	}

	DB3_SetCallback(_db3Engine, &db3Callback, (__bridge void *)self);
	
	// FIXME: Make me an option
	DB3_SetVolume(_db3Engine, 16);
	
	// Success
	if (_delegate) [_delegate decoderLoadingWasSuccessful:self];
	return YES;
}

- (void)dealloc
{
	NSLog(@"%@ dealloc", NSStringFromClass([self class]));
	
	// Free the DigiBooster context
	if (_db3Engine)
	{
		DB3_DisposeEngine(_db3Engine);
		DB3_Unload(_db3Module);
		NSLog(@"DigiBooster context freed.");
	}
}

- (BOOL)play
{
	//_currentPosition = -1;
	_play = YES;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
				   {
					   while (_play)
					   {
						   int16_t buffer[32];
						   if (!DB3_Mix(_db3Engine, 16, buffer)) break;
						   
						   while (!TPCircularBufferProduceBytes(_audioDriver.outputBuffer, buffer, sizeof(buffer)))
							   // FIXME: Semaphores?
							   usleep(30000);
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
	// Validate position
	if (![self validatePosition:_currentPosition + 1])
	{
		return NO;
	}
	DB3_SetPos(_db3Engine, 0, _currentPosition + 1, 0);
	return YES;
}

- (BOOL)backwards
{
	// Validate position
	if (![self validatePosition:_currentPosition - 1])
	{
		return NO;
	}
	DB3_SetPos(_db3Engine, 0, _currentPosition - 1, 0);
	return YES;
}

- (BOOL)stop
{
	[self pause];
	return YES;
}

- (BOOL)seekPosition: (int)position
{
	// Validate position
	if (![self validatePosition: position])
	{
		return NO;
	}
	DB3_SetPos(_db3Engine, 0, position, 0);
	return YES;
}

- (BOOL)seekTimeMillis: (int)timeMillis
{
	return NO;
}

- (NSString*)fileFormat
{
	return [NSString stringWithFormat:@"DigiBooster v%d.%d", _db3Module->CreatorVer, _db3Module->CreatorRev];
}

- (NSString*)songTitle
{
	return @(_db3Module->Name);
}

- (int)songLength
{
	return _db3Module->Songs[0]->NumOrders;
}

- (int)channels
{
	return _db3Module->NumTracks;
}

- (PatternEvent)getPatternEventWithPosition: (int)position andTrack: (int)track andRow: (int)row
{
	int patternIndex = _db3Module->Songs[0]->PlayList[position];
	struct DB3ModEntry* event = &_db3Module->Patterns[patternIndex]->Pattern[row*_db3Module->NumTracks + track];
	
	PatternEvent e = {0};
	
	if (!event->Octave)
		e.note = PATTERNDATA_NOTE_SKIP;
	else if (event->Note == 0xf)
		e.note = PATTERNDATA_NOTE_OFF;
	else
	{
		e.note = event->Note;
		e.octave = event->Octave;
	}
	e.instrument = event->Instr;
	e.volume = 0;
	e.fx1Type = event->Cmd1;
	e.fx1Param = event->Param1;
	e.fx2Type = event->Cmd2;
	e.fx2Param = event->Param2;
	
	return e;
}

- (int)getNumberOfRowsWithPosition:(int)position
{
	int patternIndex = _db3Module->Songs[0]->PlayList[position];
	return _db3Module->Patterns[patternIndex]->NumRows;
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

- (BOOL)supportsPatternData
{
	return YES;
}

- (BOOL)supportsChannelMuting
{
	return NO;
}

- (BOOL)validatePosition: (int)position
{
	if (position < 0 || position >= _db3Module->Songs[0]->NumOrders)
	{
		return NO;
	}
	return YES;
}

@end