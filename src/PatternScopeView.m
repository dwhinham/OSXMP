//
//  PatternScopeView.m
//  OSXMP
//
//  Created by Dale Whinham on 24/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import "PatternScopeView.h"

@implementation PatternScopeView

@synthesize decoder             = _decoder;
@synthesize channels            = _channels;
@synthesize currentRow          = _currentRow;
@synthesize currentPosition     = _currentPosition;

@synthesize blankZero           = _blankZero;
@synthesize prospectiveMode     = _prospectiveMode;
@synthesize lowercaseNotes      = _lowercaseNotes;
@synthesize lowercaseHex        = _lowercaseHex;

@synthesize fontName            = _fontName;
@synthesize fontSize            = _fontSize;

@synthesize defaultRowColor     = _defaultRowColor;
@synthesize currentRowColor     = _currentRowColor;
@synthesize beat1RowColor       = _beat1RowColor;
@synthesize beat2RowColor       = _beat2RowColor;
@synthesize prospectiveRowColor = _prospectiveRowColor;

- (int)nybbleToHex:(int)nybble
{
	if (nybble < 10)
		return nybble + '0';
	
	if (_lowercaseHex)
		return nybble + 'a' - 10;
	
	return nybble + 'A' - 10;
}

- (void)awakeFromNib
{
	_lineSpacing = PATTERNSCOPE_DEFAULT_LINE_SPACING;
	_columnSpacing = 3;
	_channels = 4;
	_currentRow = 0;
	_currentPosition = 0;
	_blankZero = NO;
	_prospectiveMode = NO;
	_lowercaseNotes = NO;
	_lowercaseHex = NO;
	
	_fontName = @PATTERNSCOPE_DEFAULT_FONT_NAME;
	_fontSize = PATTERNSCOPE_DEFAULT_FONT_SIZE;
	
	// Font colors
	_currentRowColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
	_beat1RowColor	 = CGColorCreateGenericRGB(0.377, 0.666, 0.897, 1.0);
	_beat2RowColor	 = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 1.0);
	_defaultRowColor = CGColorCreateGenericRGB(0.7, 0.7, 0.7, 1.0);
	_prospectiveRowColor = CGColorCreateGenericRGB(0.48, 0.48, 0.48, 1.0);
	
	// Prepare font
	_fontRef = CTFontCreateWithName((__bridge CFStringRef)_fontName, PATTERNSCOPE_DEFAULT_FONT_SIZE, NULL);
	
	// Find row height from font
	[self updateRowHeight];
	
	// Find column width from font
	[self updateColumnWidth];
}

- (void)setDecoder:(id<Decoder>)decoder
{
	_decoder = decoder;
	_channels = decoder.channels;
}

- (void)setCurrentRow:(int)currentRow
{
	_currentRow = currentRow;
	[self setNeedsDisplay:YES];
}

- (void)setCurrentPosition:(unsigned int)currentPosition
{
	_currentPosition = currentPosition;
	[self setNeedsDisplay:YES];
}

- (void)setBlankZero:(BOOL)blankZero
{
	_blankZero = blankZero;
	[self setNeedsDisplay:YES];
}

- (void)setProspectiveMode:(BOOL)prospectiveMode
{
	_prospectiveMode = prospectiveMode;
	[self setNeedsDisplay:YES];
}

- (void)setLowercaseNotes:(BOOL)lowercaseNotes
{
	_lowercaseNotes = lowercaseNotes;
	[self setNeedsDisplay:YES];
}

- (void)setLowercaseHex:(BOOL)lowercaseHex
{
	_lowercaseHex = lowercaseHex;
	[self setNeedsDisplay:YES];
}

- (void)setFontName:(NSString *)fontName
{
	_fontName = fontName;
	CFRelease(_fontRef);
	
	_fontRef = CTFontCreateWithName((__bridge CFStringRef)_fontName, _fontSize, NULL);
	
	[self updateColumnWidth];
	[self updateRowHeight];
	[self setNeedsDisplay:YES];
}

- (void)setFontSize:(float)fontSize
{
	_fontSize = fontSize;
	
	CFRelease(_fontRef);
	_fontRef = CTFontCreateWithName((__bridge CFStringRef)_fontName, _fontSize, NULL);
	
	[self updateColumnWidth];
	[self updateRowHeight];
	[self setNeedsDisplay:YES];
}

- (void)updateColumnWidth
{
	unichar patternChar =  ' ';
	
	CGGlyph fontGlyphs;
	CGSize fontAdvances;
	double charWidth = 0;
	
	CTFontGetGlyphsForCharacters(_fontRef, &patternChar, &fontGlyphs, 1);
	CTFontGetAdvancesForGlyphs(_fontRef, kCTFontOrientationDefault, &fontGlyphs, &fontAdvances, 1);
	
	charWidth = fontAdvances.width;
	
	//_columnWidth = round(charWidth * 11.0 - charWidth / 2) + _columnSpacing * 2;
	_columnSpacing = round(charWidth / 3);
	_columnWidth = round(charWidth * 11) + _columnSpacing;
}

- (void)updateRowHeight
{
	_rowHeight = round(CTFontGetCapHeight(_fontRef) + CTFontGetDescent(_fontRef));
	_rowGap = round(CTFontGetAscent(_fontRef) - CTFontGetCapHeight(_fontRef));
}

//- (BOOL)isFlipped
//{
//	return YES;
//}

- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Clear the view
	[[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0] setFill];
	//[[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
	
//	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:	[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.2 alpha:1.0], 0.0,
//																			[NSColor colorWithCalibratedRed:0.3 green:0.3 blue:0.3 alpha:1.0], 0.5,
//																			[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.2 alpha:1.0], 1.0, nil];
//	
//    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:dirtyRect] angle:270];
	
	// Get rendering context
	CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
	
	// Disable font antialiasing
	//CGContextSetAllowsAntialiasing(cgContext, false);
	//CGContextSetAllowsFontSubpixelPositioning(cgContext, false);
	
	// Use standard view coordinate system
	CGContextSetTextMatrix(cgContext, CGAffineTransformIdentity);
	
	// Use flipped coordinates
	//CGContextSetTextMatrix(cgContext, CGAffineTransformMakeScale(1.0, -1.0));
	
	// Add font and color to dictionary
	CFMutableDictionaryRef attr = CFDictionaryCreateMutable(NULL,
															0,
															&kCFTypeDictionaryKeyCallBacks,
															NULL);
	
	CFDictionaryAddValue(attr, kCTFontAttributeName, _fontRef);
	CFDictionaryAddValue(attr, kCTForegroundColorAttributeName, _defaultRowColor);
	
	CGFloat textDrawXPos,
			textDrawYPos,
			verticalCentre;
	
	verticalCentre = ([self bounds].size.height - _rowHeight) / 2;
	textDrawYPos = verticalCentre + (_rowGap + _lineSpacing) / 2;
	
	if (_decoder && [_decoder conformsToProtocol:@protocol(PatternData)])
	{
		// Recast the decoder as one that supports pattern data
		id<PatternData> ptnDataDecoder = (id<PatternData>)_decoder;
		
		int positionToDraw = _currentPosition;
		int numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];
		
		// Draw column separator framework
		int colDrawXPos = [self getStartingXPos] - _columnSpacing;
		for (int x = 0; x <= _channels && colDrawXPos < [self bounds].size.width; x++)
		{
			NSRect colSeparatorRect = NSMakeRect(colDrawXPos,
												 0,
												 1,
												 [self bounds].size.height);
			
			[[NSColor colorWithCalibratedRed:0.284 green:0.564 blue:0.856 alpha:1.0] setFill];
			NSRectFill(colSeparatorRect);
			colDrawXPos += _columnWidth + _columnSpacing;
		}
		
		// Draw current row highlight bar
		NSRect rowHighlightRect = NSMakeRect([self getStartingXPos] - _columnSpacing,
											 (int)textDrawYPos - _rowGap,
											 MIN((_columnWidth + _columnSpacing) * _channels, [self bounds].size.width),
											 _rowHeight + _rowGap);
		
		//[[NSColor colorWithCalibratedRed:0.3 green:0.5 blue:0.7 alpha:1.0] setFill];
		//[[NSColor redColor] setFill];
		//NSRectFill(rowHighlightRect);
		
		NSGradient* rowHighLightGradient = [[NSGradient alloc] initWithColorsAndLocations:	[NSColor colorWithCalibratedRed:0.284 green:0.564 blue:0.856 alpha:1.000], 0.0,
											[NSColor colorWithCalibratedRed:0.284 green:0.564 blue:0.856 alpha:1.000], 0.0294,
											
											[NSColor colorWithCalibratedRed:0.377 green:0.666 blue:0.897 alpha:1.000], 0.0295,
											[NSColor colorWithCalibratedRed:0.377 green:0.666 blue:0.897 alpha:1.000], 0.0588,
											
											[NSColor colorWithCalibratedRed:0.346 green:0.625 blue:0.868 alpha:1.000], 0.0589,
											[NSColor colorWithCalibratedRed:0.167 green:0.442 blue:0.785 alpha:1.000], 0.9705,
											
											[NSColor colorWithCalibratedRed:0.155 green:0.395 blue:0.711 alpha:1.000], 0.9706,
											[NSColor colorWithCalibratedRed:0.155 green:0.395 blue:0.711 alpha:1.000], 1.0, nil];
		
		[rowHighLightGradient drawInBezierPath:[NSBezierPath bezierPathWithRect:rowHighlightRect] angle:270];
		
		// Draw pattern data rows from vertical centre downwards
		for (int row = _currentRow; textDrawYPos > 0; row++)
		{
			// Columns
			textDrawXPos = [self getStartingXPos];
			
			if (!(row < numRows))
			{
				if (_prospectiveMode && positionToDraw + 1 < [_decoder songLength])
				{
					positionToDraw++;
					numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];
					row = 0;
				}
				else break;
			}
			
			// Set row color
			if (positionToDraw != _currentPosition)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _prospectiveRowColor);
			else if (row == _currentRow)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _currentRowColor);
			else if (row % 4 == 0)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _beat1RowColor);
			else if (row % 2 == 0)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _beat2RowColor);
			else
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _defaultRowColor);
			
			// Draw each track
			for (int track = 0; track < _channels && _columnWidth + textDrawXPos < [self bounds].size.width; track++)
			{
				PatternEvent event = [ptnDataDecoder getPatternEventWithPosition:positionToDraw andTrack:track andRow:row];
				[self drawPatternEvent:&event atXCoordinate:textDrawXPos andYCoordinate:textDrawYPos withAttributes:attr onContext:cgContext];
				textDrawXPos += _columnWidth + _columnSpacing;
			}
			
			textDrawYPos -= _rowHeight + _lineSpacing;
		}
		
		// Reset position to draw
		positionToDraw = _currentPosition;
		numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];
		
		// Reset Y position to centre
		textDrawYPos = verticalCentre + (_rowGap + _lineSpacing) / 2;
		textDrawYPos += _rowHeight + _lineSpacing;
		
		// Draw pattern data from vertical centre upwards
		for (int row = _currentRow - 1; textDrawYPos < [self bounds].size.height - _rowHeight; row--)
		{
			// Columns
			textDrawXPos = [self getStartingXPos];
			
			if (row < 0)
			{
				if (_prospectiveMode && positionToDraw - 1 >= 0)
				{
					positionToDraw--;
					numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];
					row = numRows - 1;
				}
				else break;
			}
			
			// Set row color
			if (positionToDraw != _currentPosition)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _prospectiveRowColor);
			else if (row == _currentRow)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _currentRowColor);
			else if (row % 4 == 0)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _beat1RowColor);
			else if (row % 2 == 0)
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _beat2RowColor);
			else
				CFDictionaryReplaceValue(attr, kCTForegroundColorAttributeName, _defaultRowColor);
			
			// Draw each track
			for (int track = 0; track < _channels && _columnWidth + textDrawXPos < [self bounds].size.width; track++)
			{
				PatternEvent event = [ptnDataDecoder getPatternEventWithPosition:positionToDraw andTrack:track andRow:row];
				[self drawPatternEvent:&event atXCoordinate:textDrawXPos andYCoordinate:textDrawYPos withAttributes:attr onContext:cgContext];
				textDrawXPos += _columnWidth + _columnSpacing;
			}
			
			textDrawYPos += _rowHeight + _lineSpacing;
		}
		
		// Clean up
		CFRelease(attr);
	}
		
    [super drawRect:dirtyRect];
}

- (void) drawPatternEvent:(PatternEvent *)event atXCoordinate:(int)xCoord andYCoordinate:(int)yCoord withAttributes:(CFDictionaryRef)attr onContext:(CGContextRef)cgContext
{
	// Empty line (MacRoman encoded bullet points)
	char tmpString[] = {'\xe1', '\xe1', '\xe1', ' ', '\xe1', '\xe1', ' ', '\xe1',	'\xe1',	'\xe1',	'\xe1', '\0'};
	
	// Note column
	if (event->note == PATTERNDATA_NOTE_OFF)
	{
		tmpString[0] = '=';
		tmpString[1] = '=';
		tmpString[2] = '=';
	}
	else if (event->note != PATTERNDATA_NOTE_SKIP)
	{
		memcpy(&tmpString[0], _lowercaseNotes ? lowercaseNotes[event->note] : notes[event->note], 2);
		tmpString[2] = [self nybbleToHex: event->octave];
	}
	
	// Instrument column
	if (!event->instrument && !_blankZero)
	{
		memcpy(&tmpString[4], "00", 2);
	}
	else if (event->instrument)
	{
		tmpString[4] = [self nybbleToHex: event->instrument >> 4];
		tmpString[5] = [self nybbleToHex: event->instrument & 0xf];
	}
	
	// Effects column
	if (!event->fx1Type && !event->fx1Param && !_blankZero)
	{
		memcpy(&tmpString[7], "0000", 4);
	}
	else if (event->fx1Type || event->fx1Param)
	{
		tmpString[7] = [self nybbleToHex: event->fx1Type >> 4];
		tmpString[8] = [self nybbleToHex: event->fx1Type & 0xf];
		tmpString[9] = [self nybbleToHex: event->fx1Param >> 4];
		tmpString[10] = [self nybbleToHex: event->fx1Param & 0xf];
	}
	
	// Create an attributed string
	CFStringRef cString = CFStringCreateWithCStringNoCopy(NULL, tmpString, kCFStringEncodingMacRoman, kCFAllocatorNull);
	CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, cString, attr);
	CTLineRef line = CTLineCreateWithAttributedString(attrString);
	
	// Update column width
	//_columnWidth = round(CTLineGetTypographicBounds(line, &_rowHeight, &_rowGap, NULL)) + _columnSpacing;
	
	// Draw the string
	CGContextSetTextPosition(cgContext, xCoord, yCoord);
	CTLineDraw(line, cgContext);
	
	// Clean up
	CFRelease(line);
	CFRelease(attrString);
	CFRelease(cString);
}

- (int) getStartingXPos
{
	return MAX(_columnSpacing, [self bounds].size.width / 2 - ((_columnWidth + _columnSpacing) * _channels) / 2);
}

- (void) dealloc
{
	CFRelease(_fontRef);
	CFRelease(_currentRowColor);
	CFRelease(_defaultRowColor);
	CFRelease(_beat1RowColor);
	CFRelease(_beat2RowColor);
}

@end
