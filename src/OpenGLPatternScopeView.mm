//
//  PatternScopeView.m
//  OSXMP
//
//  Created by Dale Whinham on 24/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <OpenGL/gl3.h>
#import <ft2build.h>
#import FT_FREETYPE_H
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>
#import <unordered_map>
#import <vector>
#import "OpenGLPatternScopeView.h"

@implementation OpenGLPatternScopeView
{
    unsigned int _width;
    unsigned int _height;
    unsigned int _rowSpacing;
    unsigned int _rowHeight;
    unsigned int _rowGap;
    unsigned int _columnSpacing;
    unsigned int _columnWidth;

    unsigned int _atlasWidth;
    unsigned int _atlasHeight;

    std::unordered_map<char, CharData> _charData;
    std::vector<glm::vec4> _vertices;

    int          _textIndex;

    glm::mat4    _orthoMatrix;

    GLuint       _textShaderProgram;
    GLuint       _rectShaderProgram;

    GLuint       _textVBO;
    GLuint       _textCoordsAttrib;
    GLuint       _textPosAttrib;
    GLint        _textMatrixUniform;
    GLint        _textColorUniform;
    GLint        _textTexUniform;

    GLuint       _rectVBO;
    GLuint       _rectCoordsAttrib;
    GLuint       _rectPosAttrib;
    GLint        _rectMatrixUniform;
    GLint        _rectColorUniform;
}

@synthesize decoder                 = _decoder;
@synthesize channels                = _channels;
@synthesize currentRow              = _currentRow;
@synthesize currentPosition         = _currentPosition;

@synthesize blankZero               = _blankZero;
@synthesize prospectiveMode         = _prospectiveMode;
@synthesize lowercaseNotes          = _lowercaseNotes;
@synthesize lowercaseHex            = _lowercaseHex;

@synthesize fontName                = _fontName;
@synthesize fontSize                = _fontSize;

@synthesize backgroundColor         = _backgroundColor;
@synthesize frameworkColor          = _frameworkColor;
@synthesize normalRowTextColor      = _normalRowTextColor;
@synthesize currentRowTextColor     = _currentRowTextColor;
@synthesize beat1RowTextColor       = _beat1RowTextColor;
@synthesize beat2RowTextColor       = _beat2RowTextColor;
@synthesize prospectiveRowTextColor = _prospectiveRowTextColor;

- (char)nybbleToHex:(char)nybble
{
    if (nybble < 10)
        return nybble + '0';

    if (_lowercaseHex)
        return nybble + 'a' - 10;

    return nybble + 'A' - 10;
}

- (NSArray*)getAllMonospaceFonts
{
    return [[NSFontManager sharedFontManager] availableFontNamesWithTraits:NSFixedPitchFontMask];
}

- (NSURL*)urlForFontName:(NSString*)name
{
    CTFontDescriptorRef fontDescriptorRef = CTFontDescriptorCreateWithNameAndSize((CFStringRef)name, 0.0);
    return (NSURL*)CFBridgingRelease(CTFontDescriptorCopyAttribute(fontDescriptorRef, kCTFontURLAttribute));
}

- (BOOL)generateGlyphsForFont:(NSString*)fontName withPixelSize:(unsigned int)size
{
    FT_Library ft;
    FT_Face face;
    GLuint texture;
    _atlasWidth = 0;
    _atlasHeight = 0;
    const char* fontPath = [[[self urlForFontName:fontName] path] UTF8String];

    if (FT_Init_FreeType(&ft))
    {
        NSLog(@"Couldn't init FreeType");
        return NO;
    }

    if (FT_New_Face(ft, fontPath, 0, &face))
    {
        NSLog(@"Couldn't load fonts");
        return NO;
    }

    FT_GlyphSlot g = face->glyph;
    FT_Set_Pixel_Sizes(face, 0, size);

    // Iterate over all the ASCII characters and add up the dimensions
    // of each glyph to define the dimensions of our texture atlas
    for (int i = 32; i < 128; i++)
    {
        if (FT_Load_Char(face, (FT_ULong)i, FT_LOAD_RENDER))
        {
            NSLog(@"Error loading character for '%c'", i);
            continue;
        }

        _atlasWidth += g->bitmap.width;
        _atlasHeight = MAX(_atlasHeight, g->bitmap.rows);
    }

    // Now do the same for some special characters
    if (!FT_Load_Char(face, 0x00b7, FT_LOAD_RENDER))
    {
        _atlasWidth += g->bitmap.width;
        _atlasHeight = MAX(_atlasHeight, g->bitmap.rows);
    }

    // Create empty texture atlas
    GL_CHECK(glUseProgram(_textShaderProgram));
    GL_CHECK(glGenTextures (1, &texture));
    GL_CHECK(glBindTexture(GL_TEXTURE_2D, texture));
    GL_CHECK(glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, (GLsizei) _atlasWidth, (GLsizei) _atlasHeight, 0, GL_RED, GL_UNSIGNED_BYTE, NULL));
    GL_CHECK(glUniform1i(_textTexUniform, 0));

    // Render glyphs into the atlas
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    int xOffset = 0;
    for (auto i = 32; i < 128; i++)
    {
        if (FT_Load_Char(face, (FT_ULong)i, FT_LOAD_RENDER))
        {
            NSLog(@"Error loading character for '%c'", i);
            continue;
        }

        GL_CHECK(glTexSubImage2D(GL_TEXTURE_2D, 0, xOffset, 0, (GLsizei) face->glyph->bitmap.width, (GLsizei) face->glyph->bitmap.rows, GL_RED, GL_UNSIGNED_BYTE, face->glyph->bitmap.buffer));

        // Store font metrics
//        _charData[i].advanceX     = g->advance.x >> 6;
//        _charData[i].advanceY     = g->advance.y >> 6;
//        _charData[i].bitmapWidth  = g->bitmap.width;
//        _charData[i].bitmapHeight = g->bitmap.rows;
//        _charData[i].bitmapLeft   = g->bitmap_left;
//        _charData[i].bitmapTop    = g->bitmap_top;
//        _charData[i].atlasOffsetX = (GLfloat) xOffset / _atlasWidth;

        CharData c =
        {
            static_cast<GLfloat>(g->advance.x >> 6),
            static_cast<GLfloat>(g->advance.y >> 6),
            static_cast<GLfloat>(g->bitmap.width),
            static_cast<GLfloat>(g->bitmap.rows),
            static_cast<GLfloat>(g->bitmap_left),
            static_cast<GLfloat>(g->bitmap_top),
            (GLfloat) xOffset / _atlasWidth
        };

        _charData[i] = c;

        xOffset += g->bitmap.width;
    }

    // Centre dot
    if (!FT_Load_Char(face, 0x00b7, FT_LOAD_RENDER))
    {
        GL_CHECK(glTexSubImage2D(GL_TEXTURE_2D, 0, xOffset, 0, (GLsizei) face->glyph->bitmap.width, (GLsizei) face->glyph->bitmap.rows, GL_RED, GL_UNSIGNED_BYTE, face->glyph->bitmap.buffer));

        // Store font metrics
        _charData[1].advanceX     = g->advance.x >> 6;
        _charData[1].advanceY     = g->advance.y >> 6;
        _charData[1].bitmapWidth  = g->bitmap.width;
        _charData[1].bitmapHeight = g->bitmap.rows;
        _charData[1].bitmapLeft   = g->bitmap_left;
        _charData[1].bitmapTop    = g->bitmap_top;
        _charData[1].atlasOffsetX = (GLfloat) xOffset / _atlasWidth;

        xOffset += g->bitmap.width;
    }

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    FT_Done_Face(face);
    FT_Done_FreeType(ft);

    return YES;
}

- (void)drawFilledRectangle:(glm::vec4)rect withColor:(glm::vec4*)color
{
    glm::vec2 vectors[] =
    {
        { rect.x,          rect.y          },
        { rect.x,          rect.y + rect.w },
        { rect.x + rect.z, rect.y          },
        { rect.x + rect.z, rect.y + rect.w }
    };

    GL_CHECK(glUseProgram(_rectShaderProgram));
    GL_CHECK(glUniformMatrix4fv(_rectMatrixUniform, 1, 0, glm::value_ptr(_orthoMatrix)));
    GL_CHECK(glUniform4fv(_rectColorUniform, 1, glm::value_ptr(*color)));

    auto bytes = (GLsizei) (sizeof (glm::vec2) * 4);
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, _rectVBO));
    GL_CHECK(glVertexAttribPointer(_rectCoordsAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0));
    GL_CHECK(glBufferData(GL_ARRAY_BUFFER, bytes, vectors, GL_DYNAMIC_DRAW));
    GL_CHECK(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
}

- (void)beginDrawText
{
    // TODO: vector sizing.
    _textIndex = -1;
}

- (void)endDrawText
{
    //_vertices.resize(_vertices.size());
}

- (void)drawText:(const char*)string withColor:(glm::vec4*)color atX:(GLfloat)x andY:(GLfloat)y toVector:(std::vector<glm::vec4>*)vector
{
    for (auto c = string; *c; c++)
    {
        auto cd = &_charData[*c];
        auto x2 = x + cd->bitmapLeft;
        auto y2 = y + cd->bitmapTop;
        auto w  = cd->bitmapWidth;
        auto h  = cd->bitmapHeight;
        auto ao = cd->atlasOffsetX;

        // Advance the cursor to the start of the next character
        x += cd->advanceX;
        y += cd->advanceY;

        // Skip glyphs that have no pixels
        if(w == 0.0f || h == 0.0f)
            continue;

//        if (_textIndex >= vector->size() - 7)
//        {
//            vector->resize(vector->size() * 2 + 6);
//        }

//        (*vector)[++_textIndex] = glm::vec4( x2,     y2,     ao,                   0                );
//        (*vector)[++_textIndex] = glm::vec4( x2,     y2 - h, ao,                   h / _atlasHeight );
//        (*vector)[++_textIndex] = glm::vec4( x2 + w, y2,     ao + w / _atlasWidth, 0                );
//        (*vector)[++_textIndex] = glm::vec4( x2 + w, y2,     ao + w / _atlasWidth, 0                );
//        (*vector)[++_textIndex] = glm::vec4( x2,     y2 - h, ao,                   h / _atlasHeight );
//        (*vector)[++_textIndex] = glm::vec4( x2 + w, y2 - h, ao + w / _atlasWidth, h / _atlasHeight );

        vector->emplace_back(x2,     y2,     ao,                   0               );  //  (1)--(3)
        vector->emplace_back(x2,     y2 - h, ao,                   h / _atlasHeight);  //   |   /|
        vector->emplace_back(x2 + w, y2,     ao + w / _atlasWidth, 0               );  //   |  / |  Front-facing;
        vector->emplace_back(x2 + w, y2,     ao + w / _atlasWidth, 0               );  //   | /  |  counter-clockwise winding order
        vector->emplace_back(x2,     y2 - h, ao,                   h / _atlasHeight);  //   |/   |
        vector->emplace_back(x2 + w, y2 - h, ao + w / _atlasWidth, h / _atlasHeight);  //  (2)--(4)
    }
}

- (void)awakeFromNib
{
    for (NSString* name in [self getAllMonospaceFonts])
    {
        NSLog(@"%@ -> %@", name, [[self urlForFontName:name] path]);
    }

    _rowSpacing      = PATTERNSCOPE_DEFAULT_LINE_SPACING;
    _columnSpacing   = 12;
    _channels        = 4;
    _currentRow      = 0;
    _currentPosition = 0;
    _blankZero       = NO;
    _prospectiveMode = NO;
    _lowercaseNotes  = NO;
    _lowercaseHex    = NO;

    _fontName = PATTERNSCOPE_DEFAULT_FONT_NAME;
    _fontSize = PATTERNSCOPE_DEFAULT_FONT_SIZE;

    // Font colors
    _frameworkColor          = glm::vec4(0.284, 0.564, 0.856, 1.0);
    _backgroundColor         = glm::vec4(0.1,   0.1,   0.1,   1.0);
    _currentRowTextColor     = glm::vec4(1.0,   1.0,   1.0,   1.0);
    _beat1RowTextColor       = glm::vec4(0.377, 0.666, 0.897, 1.0);
    _beat2RowTextColor       = glm::vec4(0.7,   0.7,   0.7,   1.0);
    _normalRowTextColor      = glm::vec4(0.7,   0.7,   0.7,   1.0);
    _prospectiveRowTextColor = glm::vec4(0.48,  0.48,  0.48,  1.0);

    auto bounds = [self convertRectToBacking:[self frame]];
    _width  = (unsigned int) bounds.size.width;
    _height = (unsigned int) bounds.size.height;
    _orthoMatrix = glm::ortho(0.0f, (float) _width, 0.0f, (float) _height);

    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        // Prevents GPU switching on dual-GPU machines
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFADepthSize, 24,
        // Switch to OpenGL 3.2
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    if (!pixelFormat)
        NSLog(@"Failed to create OpenGL pixel format!");

    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

    // Crash on legacy OpenGL function calls; assists with debugging
    CGLEnable((CGLContextObj) [context CGLContextObj], kCGLCECrashOnRemovedFunctions);

    // Enable Retina awareness
    [self setWantsBestResolutionOpenGLSurface:YES];

    // Apply pixel format and context
    [self setPixelFormat:pixelFormat];
    [self setOpenGLContext:context];
}

- (GLuint)compileShaderWithVertexSource:(const GLchar*)vertexSrc andFragmentSource:(const GLchar*)fragmentSrc
{
    GLuint vertexShaderName;
    GLuint fragmentShaderName;
    GLuint program;

    // Compile vertex shader
    vertexShaderName = glCreateShader(GL_VERTEX_SHADER);
    GL_CHECK(glShaderSource(vertexShaderName, 1, &vertexSrc, NULL));
    GL_CHECK(glCompileShader(vertexShaderName));

    // Compile fragment shader
    fragmentShaderName = glCreateShader(GL_FRAGMENT_SHADER);
    GL_CHECK(glShaderSource(fragmentShaderName, 1, &fragmentSrc, NULL));
    GL_CHECK(glCompileShader(fragmentShaderName));

    // Attach shaders to program and link
    program = glCreateProgram();
    GL_CHECK(glAttachShader(program, vertexShaderName));
    GL_CHECK(glAttachShader(program, fragmentShaderName));
    GL_CHECK(glLinkProgram(program));

    // We have a valid program; shaders no longer needed
    GL_CHECK(glDeleteShader(vertexShaderName));
    GL_CHECK(glDeleteShader(fragmentShaderName));

    return program;
}

- (void)prepareOpenGL
{
    // Compile shaders
    _textShaderProgram = [self compileShaderWithVertexSource:textVertexShaderSrc andFragmentSource:textFragmentShaderSrc];
    _rectShaderProgram = [self compileShaderWithVertexSource:rectVertexShaderSrc andFragmentSource:rectFragmentShaderSrc];

    // Get attribute names
    _textCoordsAttrib  = glGetAttribLocation(_textShaderProgram, "coords");
    _textMatrixUniform = glGetUniformLocation(_textShaderProgram, "matrix");
    _textColorUniform  = glGetUniformLocation(_textShaderProgram, "color");
    _textTexUniform    = glGetUniformLocation(_textShaderProgram, "tex");

    _rectCoordsAttrib  = glGetAttribLocation(_rectShaderProgram, "coords");
    _rectMatrixUniform = glGetUniformLocation(_rectShaderProgram, "matrix");
    _rectColorUniform  = glGetUniformLocation(_rectShaderProgram, "color");

    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    GL_CHECK(glEnable(GL_BLEND));
    GL_CHECK(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
    GL_CHECK(glActiveTexture(GL_TEXTURE0));

    GL_CHECK(glGenBuffers(1, &_textVBO));
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, _textVBO));
    GL_CHECK(glEnableVertexAttribArray(_textCoordsAttrib));

    GL_CHECK(glGenBuffers(1, &_rectVBO));
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, _rectVBO));
    GL_CHECK(glEnableVertexAttribArray(_rectCoordsAttrib));

    [self generateGlyphsForFont:@"FiraMonoForPowerline-Regular" withPixelSize:22];

    // Find row height from font
    [self updateRowHeight];

    // Find column width from font
    [self updateColumnWidth];

    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));

    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
    GL_CHECK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
}

- (void)setDecoder:(id<Decoder>)decoder
{
    _decoder = decoder;
    _channels = decoder.channels;
}

- (void)setCurrentRow:(unsigned int)currentRow
{
    _currentRow = currentRow;
    [self setNeedsDisplay:YES];
}

- (void)setCurrentPosition:(int)currentPosition
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

    [self updateColumnWidth];
    [self updateRowHeight];
    [self setNeedsDisplay:YES];
}

- (void)setFontSize:(float)fontSize
{
    _fontSize = fontSize;

    [self updateColumnWidth];
    [self updateRowHeight];
    [self setNeedsDisplay:YES];
}

- (void)updateColumnWidth
{
    auto charWidth = (unsigned int) _charData['0'].bitmapWidth;
    _columnSpacing = charWidth;
    _columnWidth = charWidth * 11 + _columnSpacing;
}

- (void)updateRowHeight
{
    _rowHeight = (unsigned int) _charData['0'].bitmapHeight;
    _rowGap = 3;
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    _vertices.clear();

    [self beginDrawText];

    // TODO: Move this to a bounds changed callback
    auto bounds = [self convertRectToBacking:[self bounds]];
    _width  = (unsigned int) bounds.size.width;
    _height = (unsigned int) bounds.size.height;
    _orthoMatrix = glm::ortho(0.0f, (float) _width, 0.0f, (float) _height);

    // Adjust viewport
    GL_CHECK(glViewport(0, 0, (GLsizei) _width, (GLsizei) _height));

    // Clear the background
    GL_CHECK(glClearColor(_backgroundColor.r, _backgroundColor.g, _backgroundColor.b, _backgroundColor.a));
    GL_CHECK(glClear(GL_COLOR_BUFFER_BIT));

    auto verticalCentre = _height / 2;
    int textDrawXPos;
    int textDrawYPos = (signed) (verticalCentre + (_rowGap + _rowSpacing) / 2);

    // TODO: Do we need this? Maybe PatternScope shouldn't be passed non-conforming decoders
    if (_decoder && [_decoder conformsToProtocol:@protocol(PatternData)])
    {
        // Recast the decoder as one that supports pattern data
        auto ptnDataDecoder = (id<PatternData>)_decoder;

        auto positionToDraw = _currentPosition;
        auto numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];

        auto colDrawXPos = [self getStartingXPos];// - _columnSpacing;

        // Draw current row highlight bar
        glm::vec4 bar = glm::vec4(colDrawXPos - _columnSpacing / 2, textDrawYPos - 2, MIN((_columnWidth + _columnSpacing) * _channels, _width), _rowHeight + _rowGap);
        [self drawFilledRectangle:bar withColor:&_frameworkColor];

        // Draw column separator framework
        for (auto x = 0; x <= _channels && colDrawXPos < _width; x++)
        {
            glm::vec4 box = glm::vec4(colDrawXPos - _columnSpacing / 2, 0, 2, _height);
            [self drawFilledRectangle:box withColor:&_frameworkColor];
            colDrawXPos += _columnWidth + _columnSpacing;
        }

        // Draw pattern data rows from vertical centre downwards
        for (auto row = _currentRow; textDrawYPos > 0; row++)
        {
            // Columns
            textDrawXPos = (signed) [self getStartingXPos];

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
            glm::vec4* textColor;
            if (positionToDraw != _currentPosition)
                textColor = &_prospectiveRowTextColor;
            else if (row == _currentRow)
                textColor = &_currentRowTextColor;
            else if (row % 4 == 0)
                textColor = &_beat1RowTextColor;
            else if (row % 2 == 0)
                textColor = &_beat2RowTextColor;
            else
                textColor = &_normalRowTextColor;

            // Draw each track
            for (auto track = 0; track < _channels && textDrawXPos + _columnWidth < _width + _columnWidth; track++)
            {
                PatternEvent event = [ptnDataDecoder getPatternEventWithPosition:positionToDraw andTrack:track andRow:row];
                [self drawPatternEvent:&event atX:textDrawXPos andY:textDrawYPos withColor:textColor toVector:&_vertices];
                textDrawXPos += _columnWidth + _columnSpacing;
            }

            textDrawYPos -= _rowHeight + _rowSpacing;
        }

        // Reset position to draw
        positionToDraw = _currentPosition;
        numRows = [ptnDataDecoder getNumberOfRowsWithPosition:positionToDraw];

        // Reset Y position to centre
        textDrawYPos = verticalCentre + (_rowGap + _rowSpacing) / 2;
        textDrawYPos += _rowHeight + _rowSpacing;

        // Draw pattern data from vertical centre upwards
        for (int row = _currentRow - 1; textDrawYPos < _height - _rowHeight; row--)
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
            glm::vec4* textColor;
            if (positionToDraw != _currentPosition)
                textColor = &_prospectiveRowTextColor;
            else if (row == _currentRow)
                textColor = &_currentRowTextColor;
            else if (row % 4 == 0)
                textColor = &_beat1RowTextColor;
            else if (row % 2 == 0)
                textColor = &_beat2RowTextColor;
            else
                textColor = &_normalRowTextColor;

            // Draw each track
            for (int track = 0; track < _channels && _columnWidth + textDrawXPos < _width + _columnWidth; track++)
            {
                PatternEvent event = [ptnDataDecoder getPatternEventWithPosition:positionToDraw andTrack:track andRow:row];
                [self drawPatternEvent:&event atX:textDrawXPos andY:textDrawYPos withColor:textColor toVector:&_vertices];
                textDrawXPos += _columnWidth + _columnSpacing;
            }

            textDrawYPos += _rowHeight + _rowSpacing;
        }

    }

    // Draw the vertices
    [self endDrawText];

    auto bytes = (GLsizei) (sizeof (glm::vec4) * _vertices.size());
    GL_CHECK(glUseProgram(_textShaderProgram));
    GL_CHECK(glUniformMatrix4fv(_textMatrixUniform, 1, 0, glm::value_ptr(_orthoMatrix)));
    GL_CHECK(glUniform4f(_textColorUniform, _normalRowTextColor.r, _normalRowTextColor.g, _normalRowTextColor.b, _normalRowTextColor.a));
    GL_CHECK(glBindBuffer(GL_ARRAY_BUFFER, _textVBO));
    GL_CHECK(glVertexAttribPointer(_textCoordsAttrib, 4, GL_FLOAT, GL_FALSE, 0, 0));
    GL_CHECK(glBufferData(GL_ARRAY_BUFFER, bytes, nullptr, GL_DYNAMIC_DRAW));
    GL_CHECK(glBufferSubData(GL_ARRAY_BUFFER, 0, bytes, _vertices.data()));
    GL_CHECK(glDrawArrays(GL_TRIANGLES, 0, (GLsizei) _vertices.size()));

    // Flip buffers
    [[self openGLContext] flushBuffer];
}

- (void)drawPatternEvent:(PatternEvent *)event atX:(unsigned int)x andY:(unsigned int)y withColor:(glm::vec4*)color toVector:(std::vector<glm::vec4>*)vector
{
    // Empty line (centre dots)
    //char tmpString[] = { '-', '-', '-', ' ', '-', '-', ' ', '-', '-', '-', '-', '\0' };
    char tmpString[] = { 1, 1, 1, ' ', 1, 1, ' ', 1, 1, 1, 1, '\0' };

    // Note column
    if (event->note == PATTERNDATA_NOTE_OFF)
    {
        tmpString[0] = '=';
        tmpString[1] = '=';
        tmpString[2] = '=';
    }
    else if (event->note != PATTERNDATA_NOTE_SKIP)
    {
        tmpString[0] = _lowercaseNotes ? lowercaseNotes[event->note][0] : notes[event->note][0];
        tmpString[1] = _lowercaseNotes ? lowercaseNotes[event->note][1] : notes[event->note][1];
        tmpString[2] = [self nybbleToHex: (char) event->octave];
    }

    // Instrument column
    if (!event->instrument && !_blankZero)
    {
        tmpString[4] = '0';
        tmpString[5] = '0';
    }
    else if (event->instrument)
    {
        tmpString[4] = [self nybbleToHex: event->instrument >> 4 & 0xf];
        tmpString[5] = [self nybbleToHex: event->instrument & 0xf];
    }

    // Effects column
    if (!event->fx1Type && !event->fx1Param && !_blankZero)
    {
        tmpString[7]  = '0';
        tmpString[8]  = '0';
        tmpString[9]  = '0';
        tmpString[10] = '0';
    }
    else if (event->fx1Type || event->fx1Param)
    {
        tmpString[7]  = [self nybbleToHex: event->fx1Type >> 4 & 0xf];
        tmpString[8]  = [self nybbleToHex: event->fx1Type & 0xf];
        tmpString[9]  = [self nybbleToHex: event->fx1Param >> 4 & 0xf];
        tmpString[10] = [self nybbleToHex: event->fx1Param & 0xf];
    }

    // Update column width
    _columnWidth = (unsigned int) _charData['0'].bitmapWidth * 12 + _columnSpacing;

    // Draw the string
    [self drawText:tmpString withColor:color atX:x andY:y toVector:vector];
}

- (unsigned int) getStartingXPos
{
    int leftEdge = (signed) _columnSpacing;
    int centeredPatterns = (signed) _width / 2 - (((signed) _columnWidth + (signed) _columnSpacing) * (signed) _channels) / 2;
    return (unsigned) MAX(leftEdge, centeredPatterns);
}

@end
