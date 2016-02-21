//
//  PatternData.h
//  OSXMP
//
//	Definition of the PatternData protocol.
//
//  Created by Dale Whinham on 11/06/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Foundation/Foundation.h>

// Constant value for note-off event
#define PATTERNDATA_NOTE_SKIP	12
#define PATTERNDATA_NOTE_OFF	13

// Pattern event struct for decoders supporting pattern data
typedef struct
{
	int note;	// 0-11 = C through B, 12 = skip, 13 = note-off
	int octave;
	int instrument;
	int volume;
	int fx1Type;
	int fx1Param;
	int fx2Type;
	int fx2Param;
} PatternEvent;

// Note tables
static const char* notes[]			= {"C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"};
static const char* lowercaseNotes[] = {"c-", "c#", "c-", "d#", "e-", "f-", "f#", "g-", "g#", "a-", "b#", "c-"};

@protocol PatternData
- (PatternEvent)getPatternEventWithPosition: (int)position andTrack: (int)track andRow: (int)row;
- (int)getNumberOfRowsWithPosition: (int)position;
@end
