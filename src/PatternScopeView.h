//
//  PatternScopeView.h
//  OSXMP
//
//  Created by Dale Whinham on 24/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Decoder.h"
#import "PatternData.h"
#import "XMPDecoder.h"

#define PATTERNSCOPE_DEFAULT_LINE_SPACING	3
#define PATTERNSCOPE_DEFAULT_FONT_NAME		"AndaleMono"
//#define PATTERNSCOPE_DEFAULT_FONT_NAME		"SourceCodePro-Medium"
//#define PATTERNSCOPE_DEFAULT_FONT_NAME		"Consolas"
#define PATTERNSCOPE_DEFAULT_FONT_SIZE		11

@interface PatternScopeView : NSView
{
	int _lineSpacing;
	int _rowHeight;
	int _rowGap;
	int _columnSpacing;
	int _columnWidth;
	
	CTFontRef _fontRef;
}

@property (nonatomic, weak,   readwrite) id<Decoder> decoder;
@property (nonatomic, assign, readwrite) unsigned int channels;
@property (nonatomic, assign, readwrite) unsigned int currentRow;
@property (nonatomic, assign, readwrite) unsigned int currentPosition;

@property (nonatomic, assign, readwrite) BOOL blankZero;
@property (nonatomic, assign, readwrite) BOOL prospectiveMode;
@property (nonatomic, assign, readwrite) BOOL lowercaseNotes;
@property (nonatomic, assign, readwrite) BOOL lowercaseHex;

@property (nonatomic, copy,   readwrite) NSString* fontName;
@property (nonatomic, assign, readwrite) float fontSize;

@property (nonatomic, assign, readwrite) CGColorRef defaultRowColor;
@property (nonatomic, assign, readwrite) CGColorRef currentRowColor;
@property (nonatomic, assign, readwrite) CGColorRef beat1RowColor;
@property (nonatomic, assign, readwrite) CGColorRef beat2RowColor;
@property (nonatomic, assign, readwrite) CGColorRef prospectiveRowColor;

@end
