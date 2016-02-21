//
//  StatusBoxView.m
//  OSXMP
//
//  Created by Dale Whinham on 18/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "StatusBoxView.h"

@implementation StatusBoxView

- (void)awakeFromNib
{
    [(NSTextField*) [self cell] setBezelStyle: NSTextFieldRoundedBezel];
}

- (id)initWithFrame:(NSRect)frame
{
    return [super initWithFrame:frame];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect gradientRectangle = NSMakeRect(0.0, 0.0, [self bounds].size.width, [self bounds].size.height-1.0);

    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.7]
														 endingColor:[NSColor colorWithCalibratedRed:0.3 green:0.3 blue:0.3 alpha:0.5]];
	
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:gradientRectangle xRadius:5 yRadius:5] angle:90];
	
	gradientRectangle = NSMakeRect(0.0, 0.0, [self bounds].size.width, [self bounds].size.height * 0.5);
	gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.7]
											 endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
	[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:gradientRectangle xRadius:5 yRadius:5] angle:90];
	
	[super drawRect:dirtyRect];
}


@end
