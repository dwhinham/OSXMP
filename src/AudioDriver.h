//
//  AudioDriver.h
//  OSXMP
//
//  Created by Dale Whinham on 17/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"

#define DEFAULT_BUFFER_SIZE 5000
#define DEFAULT_SAMPLE_RATE 44100

@interface AudioDriver : NSObject

@property (nonatomic, assign, readonly) TPCircularBuffer* outputBuffer;
@property (nonatomic, assign, readonly) AudioUnit outputUnit;
@property (nonatomic, assign, readwrite) int sampleRate;
@property (nonatomic, assign, readwrite) int bufferSize;
@property (nonatomic, assign, readonly) dispatch_semaphore_t semaphore;

@property (nonatomic, assign, readonly) float leftLevel;
@property (nonatomic, assign, readonly) float rightLevel;

OSStatus outputCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
						 const AudioTimeStamp *inTimeStamp,
						 UInt32 inBusNumber,
						 UInt32 inBufferFrames,
						 AudioBufferList *ioData);

float averageLevel (SInt16* audioData, int numFrames);

- (BOOL)start;
- (BOOL)stop;
- (void)flush;

- (void)setVolume:(float) volume;

+ (BOOL)checkError:(OSStatus) error withName:(NSString*)operation;

@end
