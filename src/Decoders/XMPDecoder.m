//
//  XMPDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 25/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "XMPDecoder.h"

@implementation XMPDecoder : NSObject

@synthesize type		= _type;
@synthesize audioDriver = _audioDriver;
@synthesize delegate	= _delegate;
// TODO: Remove
@synthesize xmpContext = _xmpCtx;

- (id)init
{
	self = [super init];
	if (self)
		_type = DECODER_XMP;
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
	char path[[theFilePath length]];
	strcpy(path, [theFilePath UTF8String]);
	
	// Create a new XMP context
	_xmpCtx = xmp_create_context();
	
	if (xmp_load_module(_xmpCtx, path))
	{
		// Loading failed
		if (_delegate) [_delegate decoderLoadingWasUnsuccessful:self];
		return NO;
	}
	
	// Allocate space for an XMP module info struct
	_xmpModuleInfo = malloc(sizeof(struct xmp_module_info));
	
	// Populate XMP module info structure
	xmp_get_module_info(_xmpCtx, _xmpModuleInfo);
	
	// Success
	if (_delegate)
	{
		[_delegate decoderLoadingWasSuccessful:self];
	}
	return YES;
}

- (void)dealloc
{
	NSLog(@"%@ dealloc", NSStringFromClass([self class]));
	
    // Free the module if there's one loaded
	if (xmp_get_player(_xmpCtx, XMP_PLAYER_STATE) != XMP_STATE_UNLOADED)
	{
		xmp_release_module(_xmpCtx);
	}
	
	// Free the context
	xmp_free_context(_xmpCtx);
	
	// Free XMP info struct
	free(_xmpModuleInfo);
}

- (BOOL)play
{
	if (xmp_get_player(_xmpCtx, XMP_PLAYER_STATE) != XMP_STATE_PLAYING)
	{
		if (xmp_start_player(_xmpCtx, _audioDriver.sampleRate, 0))
		{
			return NO;
		}
	}
	
	__block int currentRow = -1;
	__block int currentPosition = -1;
	
	_play = YES;

	__block dispatch_semaphore_t semaphore = _audioDriver.semaphore;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
				   {
					   while (_play)
					   {
						   // Render a frame of audio
						   xmp_play_frame(_xmpCtx);
						   xmp_get_frame_info(_xmpCtx, &_xmpFrameInfo);
						   
						   //if (_xmpFrameInfo.loop_count > 0)
						   //	break;
						   
						   // Returns false if buffer is full
						   while (!TPCircularBufferProduceBytes(_audioDriver.outputBuffer, _xmpFrameInfo.buffer, _xmpFrameInfo.buffer_size))
						   {
							   // Wait for semaphore (aka. down)
							   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                               if (!_play) return;
						   }
						   
						   // Update UI if position/row changes
						   dispatch_async(dispatch_get_main_queue(), ^(void)
										  {
											  if (currentPosition != _xmpFrameInfo.pos)
											  {
												  currentPosition = _xmpFrameInfo.pos;
												  if (_delegate)
												  {
													  [_delegate positionNumberDidChange:self withPosNumber:currentPosition];
												  }
											  }
											  if (currentRow != _xmpFrameInfo.row)
											  {
												  currentRow = _xmpFrameInfo.row;
												  if (_delegate)
												  {
													  [_delegate patternRowNumberDidChange:self withRowNumber:currentRow andPatternLength:_xmpFrameInfo.num_rows];
												  }
											  }
										  });
					   }
				   });

	[_audioDriver start];
	return YES;
}

- (BOOL)pause
{
	[_audioDriver stop];
	[_audioDriver flush];
    _play = NO;
	
	return YES;
}

- (BOOL)forwards
{
	return xmp_next_position(_xmpCtx);
}

- (BOOL)backwards
{
	return xmp_prev_position(_xmpCtx);
}

- (BOOL)stop
{
    [self pause];
    xmp_end_player(_xmpCtx);

	return YES;
}

- (BOOL)seekPosition: (int)position
{
	if (position == [self songLength])
	{
		return NO;
	}
	return xmp_set_position(_xmpCtx, position);
}

- (BOOL)seekTimeMillis: (int)timeMillis
{
	return xmp_seek_time(_xmpCtx, timeMillis);
}

- (NSString*)fileFormat
{
	return @(_xmpModuleInfo->mod->type);
}

- (NSString*)songTitle
{
	return @(_xmpModuleInfo->mod->name);
}

- (int)songLength
{
	if (_xmpModuleInfo->num_sequences == 1 && _xmpModuleInfo->mod->xxo[_xmpModuleInfo->mod->len - 1] != 0xff)
		return _xmpModuleInfo->mod->len;
	else
	{
		int len = _xmpModuleInfo->seq_data->entry_point;
		while (_xmpModuleInfo->mod->xxo[len] != 0xff)
		{
			if (_xmpModuleInfo->mod->xxo[len] == 0xfe) continue;
			len++;
		}
		return len;
	}
}

- (int)channels
{
	return _xmpModuleInfo->mod->chn;
}

- (PatternEvent)getPatternEventWithPosition: (int)position andTrack: (int)track andRow: (int)row
{
	int patternIndex = _xmpModuleInfo->mod->xxo[position];
	int trackIndex = _xmpModuleInfo->mod->xxp[patternIndex]->index[track];
	struct xmp_event* event = &_xmpModuleInfo->mod->xxt[trackIndex]->event[row];
	
	PatternEvent e = {0};
	
	// Blank notes
	if (event->note == XMP_KEY_OFF)
	{
		e.note = PATTERNDATA_NOTE_OFF;
	}
	// Note-off
	else if (event->note < 13)
	{
		e.note = PATTERNDATA_NOTE_SKIP;
	}
	else
	{
		// Split notes and octaves
		e.note = (event->note - 1) % 12;
		// Octaves can start at zero
		e.octave = (event->note - 1) / 12 - 1;
	}
	e.instrument = event->ins;
	e.volume = event->vol;
	e.fx1Type = event->fxt;
	e.fx1Param = event->fxp;
	e.fx2Type = event->f2t;
	e.fx2Param = event->f2p;
	
	return e;
}

- (int)getNumberOfRowsWithPosition:(int)position
{
	int patternIndex = _xmpModuleInfo->mod->xxo[position];
	return _xmpModuleInfo->mod->xxp[patternIndex]->rows;
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

@end
