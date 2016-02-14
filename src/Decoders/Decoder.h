//
//  Decoder.h
//  OSXMP
//
//	Definition of the Decoder protocol.
//
//  Created by Dale Whinham on 25/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DecoderDelegate.h"
#import "PatternData.h"
#import "AudioDriver.h"

// Add player types here for identification
typedef NS_ENUM(NSUInteger, DecoderType)
{
	DECODER_ADPLUG,
	DECODER_BASS,
	DECODER_DB3,
	DECODER_DUMB,
	DECODER_HIVELY,
	DECODER_MILKY,
	DECODER_RESID,
	DECODER_UADE,
	DECODER_XMP
};

@protocol Decoder

// Instance properties
@property (nonatomic, assign, readonly) DecoderType type;
@property (nonatomic, strong, readwrite) AudioDriver* audioDriver;
@property (nonatomic, assign, readwrite) id<DecoderDelegate> delegate;

// Initialisation and loading
- (id)initWithDelegate: (id)theDelegate;
- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver;
- (id)initWithDelegate: (id)theDelegate andAudioDriver: (AudioDriver*)theDriver andFilePath:(NSString*) theFilePath;

- (BOOL)loadFile: (NSString*)theFilePath;

// Transport controls
- (BOOL)play;
- (BOOL)pause;
- (BOOL)forwards;
- (BOOL)backwards;
- (BOOL)stop;

- (BOOL)seekPosition: (int)position;
- (BOOL)seekTimeMillis: (int)timeMillis;

// Properties
- (NSString*)fileFormat;
- (NSString*)songTitle;
- (int)songLength;
- (int)channels;

// Subsong capabilities
- (BOOL)hasNextSubSong;
- (BOOL)hasPreviousSubSong;

// General capabilities
- (BOOL)supportsSeeking;
- (BOOL)supportsSubSongs;
- (BOOL)supportsChannelMuting;

@end