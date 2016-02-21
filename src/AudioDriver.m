//
//  AudioDriver.m
//  OSXMP
//
//  Created by Dale Whinham on 17/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "AudioDriver.h"

@implementation AudioDriver

@synthesize sampleRate = _sampleRate;
@synthesize bufferSize = _bufferSize;
@synthesize outputBuffer = _outputBuffer;
@synthesize outputUnit = _outputUnit;
@synthesize semaphore = _semaphore;
@synthesize leftLevel = _leftLevel;
@synthesize rightLevel = _rightLevel;

OSStatus outputCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
						const AudioTimeStamp *inTimeStamp,
						UInt32 inBusNumber,
						UInt32 inBufferFrames,
						AudioBufferList *ioData)
{
	// Callback routine courtesy of 'A Tasty Pixel':
	// http://atastypixel.com/blog/a-simple-fast-circular-buffer-implementation-for-audio-processing/
	
	// Pointer to the AudioDriver object so that we can access members
	AudioDriver* audioDriver = (__bridge AudioDriver *)inRefCon;
	
	// Pointer to buffer
	TPCircularBuffer* outputBuffer = audioDriver->_outputBuffer;
	
	// Number of bytes audio device expects
	UInt32 bytesToCopy = ioData->mBuffers[0].mDataByteSize;
	
	// Pointer to destination buffer
    SInt16 *destBuffer = (SInt16*)ioData->mBuffers[0].mData;
	
	// Get pointer to start of circular buffer and number of bytes available in circular buffer
    UInt32 availableBytes;
    SInt16 *sourceBuffer = TPCircularBufferTail(outputBuffer, (int32_t*)&availableBytes);
	
	// Copy the audio data
    memcpy(destBuffer, sourceBuffer, MIN(bytesToCopy, availableBytes));
	
	// Consume bytes in circular buffer
    TPCircularBufferConsume(outputBuffer, MIN((int32_t)bytesToCopy, (int32_t)availableBytes));
	
	// Notify consumed
	dispatch_semaphore_signal(audioDriver->_semaphore);
	
	// Calculate L/R levels
	//audioDriver->_leftLevel = averageLevel(sourceBuffer, bytesToCopy / 8);
	//audioDriver->_rightLevel = averageLevel(sourceBuffer + 1, bytesToCopy / 8);
	return noErr;
}

float averageLevel (SInt16* audioData, int numBytes)
{
	if (!audioData) return 0;
	
	int total = 0;
	
	for (int i = 0; i < numBytes; i+=2)
	{
		total += abs((int)audioData[i]);
	}
	
	int average = total / numBytes;
	
	float logAvg = log10f((float)average);
	logAvg = logAvg / log10f(32768);
	
	return logAvg;
}

- (AudioDriver* )init
{
	_sampleRate = DEFAULT_SAMPLE_RATE;
	_bufferSize = DEFAULT_BUFFER_SIZE;
	
	// Allocations for circular buffer and AudioUnit
	_outputBuffer = malloc(sizeof(TPCircularBuffer));
	_outputUnit = malloc(sizeof(AudioUnit));
	
	TPCircularBufferInit(_outputBuffer, _bufferSize);
	
	// Init semaphore
	_semaphore = dispatch_semaphore_create(_bufferSize);
	
	// Component description for default output device
    AudioComponentDescription componentDesc;
	componentDesc.componentType = kAudioUnitType_Output;
	componentDesc.componentSubType = kAudioUnitSubType_DefaultOutput;
	componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
	
	AudioComponent component = AudioComponentFindNext(NULL, &componentDesc);
	if (component == NULL)
	{
		NSLog(@"CoreAudio: Can't get output unit");
		return nil;
	}
	
	if ([AudioDriver checkError: AudioComponentInstanceNew(component, &_outputUnit) withName:@"Couldn't open component for outputUnit"])
		return nil;
	
	// Set our input format description
    AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = _sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamFormat.mBytesPerPacket = 4;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 4;
	streamFormat.mChannelsPerFrame = 2;
	streamFormat.mBitsPerChannel = 16;
    streamFormat.mReserved = 0;
	
	if ([AudioDriver checkError:	AudioUnitSetProperty(_outputUnit,
									kAudioUnitProperty_StreamFormat,
									kAudioUnitScope_Input,
									0,
									&streamFormat,
									sizeof(streamFormat))
					   withName:	@"Couldn't set stream format"])
		return nil;
	
	// Register the render callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = &outputCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	
	[AudioDriver checkError:	AudioUnitSetProperty(_outputUnit,
								kAudioUnitProperty_SetRenderCallback,
								kAudioUnitScope_Input,
								0,
								&callbackStruct,
								sizeof(callbackStruct))
				   withName:	@"AudioUnitSetProperty failed"];
	
	// Initialize the unit
	if ([AudioDriver checkError: AudioUnitInitialize(_outputUnit) withName:@"Couldn't initialize output unit"])
		return nil;
	
	return self;
}

- (void)dealloc
{
	TPCircularBufferCleanup(_outputBuffer);
	free(_outputBuffer);
	free(_outputUnit);
}

+ (BOOL)checkError:(OSStatus) error withName:(NSString*) operation
{
	if (error == noErr) return false;
	char errorString[20];
	// See if it appears to be a 4-char-code
	*(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
	if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4]))
	{
		errorString[0] = errorString[5] = '\'';
		errorString[6] = '\0';
	}
	else
	{
		// No, format it as an integer
		sprintf(errorString, "%d", (int)error);
	}
	NSLog(@"CoreAudio error: %@ (%s)\n", operation, errorString);
	return true;
}

- (BOOL)start
{
	// Start playing
	if ([AudioDriver checkError: AudioOutputUnitStart(_outputUnit) withName:@"Couldn't start output unit"])
		return false;
	return true;
}

- (BOOL)stop
{
	// Stop playing
	if ([AudioDriver checkError: AudioOutputUnitStop(_outputUnit) withName:@"Couldn't stop output unit"])
		return false;
	return true;
}

- (void)flush
{
	NSLog(@"Audio buffer flushed");
	TPCircularBufferClear(_outputBuffer);
}

- (void)setVolume:(float) volume
{
	AudioUnitSetParameter(_outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Output, 0, volume, 0);
}

@end
