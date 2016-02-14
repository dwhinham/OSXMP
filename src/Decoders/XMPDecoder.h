//
//  XMPDecoder.m
//  OSXMP
//
//  Created by Dale Whinham on 25/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "Decoder.h"
#import "xmp.h"

@interface XMPDecoder : NSObject <Decoder, PatternData>
{
	BOOL _play;
	xmp_context _xmpCtx;
	struct xmp_module_info* _xmpModuleInfo;
	struct xmp_frame_info _xmpFrameInfo;
}

@property (nonatomic, assign, readonly) xmp_context xmpContext;

@end
