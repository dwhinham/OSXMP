//
//  MilkyTrackerDecoder.h
//  OSXMP
//
//  Created by Dale Whinham on 21/06/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "Decoder.h"
#import "MilkyPlay.h"

@interface MilkyTrackerDecoder : NSObject<Decoder>
{
	BOOL _play;
	XModule* milkyModule;
	PlayerGeneric* pPlayer;
}
@end
