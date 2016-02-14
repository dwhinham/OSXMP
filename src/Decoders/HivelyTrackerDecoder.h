//
//  HivelyTrackerDecoder.h
//  OSXMP
//
//  Created by Dale Whinham on 12/06/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "Decoder.h"
#import "hvl_replay.h"

@interface HivelyTrackerDecoder : NSObject<Decoder, PatternData>
{
	BOOL _play;
	struct hvl_tune* _hvlModule;

	int _currentRow;
	int _currentPosition;
}

@end
