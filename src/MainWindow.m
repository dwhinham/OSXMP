//
//  MainWindow.m
//  OSXMP
//
//  Created by Dale Whinham on 18/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "MainWindow.h"

@implementation MainWindow

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (void)flagsChanged:(NSEvent *)event
{
    if ([event modifierFlags] & NSAlternateKeyMask)
    {
        [transportControls setImage:[NSImage imageNamed:@"controller-fast-backward"] forSegment:0];
        [transportControls setImage:[NSImage imageNamed:@"controller-fast-forward"]  forSegment:3];
        
        [transportControls setToolTip:@"Previous Position" forSegment:0];
        [transportControls setToolTip:@"Next Position"     forSegment:3];
    }
    else
    {
        [transportControls setImage:[NSImage imageNamed:@"controller-jump-to-start"] forSegment:0];
        [transportControls setImage:[NSImage imageNamed:@"controller-next"]          forSegment:3];

        [transportControls setToolTip:@"Previous" forSegment:0];
        [transportControls setToolTip:@"Next"     forSegment:3];
    }
}

@end
