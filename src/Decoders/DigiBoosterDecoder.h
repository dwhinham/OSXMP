//
//  DigiBoosterDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 25/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "Decoder.h"
#import "libdigibooster3.h"

@interface DigiBoosterDecoder : NSObject <Decoder, PatternData>
{
	BOOL _play;
	struct DB3Module* _db3Module;
	void* _db3Engine;
	
	int _currentPosition;
}

- (BOOL) validatePosition:(int)position;

@end