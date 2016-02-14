//
//  MilkyTrackerDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 21/06/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "MilkyTrackerDecoder.h"

@implementation MilkyTrackerDecoder

@synthesize type		= _type;
@synthesize audioDriver = _audioDriver;
@synthesize delegate	= _delegate;

- (id)init
{
	self = [super init];
	if (self)
	{
		_type = DECODER_MILKY;
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
	{
		[self loadFile:theFilePath];
	}
	return self;
}

- (BOOL)loadFile: (NSString*)theFilePath
{
	// Copy NSString to a C string
	char path[[theFilePath length]];
	strcpy(path, [theFilePath UTF8String]);
	
	// Create a new MilkyTracker context
	milkyModule = new XModule;
	
	// Create a new MilkyTracker player engine
	milkyPlayer = new PlayerGeneric;
	
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
	if (_delegate) [_delegate decoderLoadingWasSuccessful:self];
	return YES;
}

- (void) dealloc
{
	delete milkyModule;
}

// Transport controls
- (BOOL)play
{
	
}

- (BOOL)pause
{
	
}

- (BOOL)forwards

{
	
}

- (BOOL)backwards
{
	
}

- (BOOL)stop
{
	
}



- (BOOL)seekPosition: (int)position
{
	
}


- (BOOL)seekTimeMillis: (int)timeMillis
{
	
}


// Properties
- (NSString*)fileFormat
{
	
}

- (NSString*)songTitle
{
	
}

- (int)songLength
{
	
}

- (int)channels
{
	
}

// Subsong capabilities
- (BOOL)hasNextSubSong
{
	
}


- (BOOL)hasPreviousSubSong
{
	
}

// General capabilities
- (BOOL)supportsSeeking
{
	
}

- (BOOL)supportsSubSongs
{
	
}

- (BOOL)supportsChannelMuting
{
	
}

@end