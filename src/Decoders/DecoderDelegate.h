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

- (void)patternRowNumberDidChange: (id)sender withRowNumber: (int)rowNumber andPatternLength: (int)patternLength;
- (void)positionNumberDidChange: (id)sender withPosNumber: (int)posNumber;
@end