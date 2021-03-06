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

@protocol DecoderDelegate
- (void)decoderLoadingWasSuccessful: (id)sender;
- (void)decoderLoadingWasUnsuccessful: (id)sender;

- (void)patternRowNumberDidChange: (id)sender withRowNumber: (unsigned int)rowNumber andPatternLength: (unsigned int)patternLength;
- (void)positionNumberDidChange: (id)sender withPosNumber: (unsigned int)posNumber;

- (void)playbackDidFinish: (id)sender;
@end
