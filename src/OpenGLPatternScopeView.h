//
//  PatternScopeView.h
//  OSXMP
//
//  Created by Dale Whinham on 24/05/2014.
//  Copyright (c) 2014 Dale Whinham. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <glm/fwd.hpp>
#import "Decoder.h"
#import "PatternData.h"

#define PATTERNSCOPE_DEFAULT_LINE_SPACING	3
#define PATTERNSCOPE_DEFAULT_FONT_NAME		@"AndaleMono"
#define PATTERNSCOPE_DEFAULT_FONT_SIZE		48

#define GLSL(src) "#version 330 core\n" #src

#ifdef DEBUG
#define GL_CHECK(stmt) do { \
stmt; \
CheckOpenGLError(#stmt, __FILE__, __LINE__); \
} while (0)
#else
#define GL_CHECK(stmt) stmt
#endif

// Error handler for debugging
#ifdef DEBUG
static void CheckOpenGLError(const char* stmt, const char* fname, int line)
{
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("OpenGL error %08x, at %s:%i - for %s\n", err, fname, line, stmt);
        //abort();
    }
}
#endif

// FreeType glyph metrics
typedef struct CharData
{
    GLfloat advanceX;
    GLfloat advanceY;

    GLfloat bitmapWidth;
    GLfloat bitmapHeight;

    GLfloat bitmapLeft;
    GLfloat bitmapTop;

    GLfloat atlasOffsetX;
} CharData;

// Text rendering vertex shader program
static const GLchar* textVertexShaderSrc = GLSL
(
    uniform mat4 matrix;
    in vec4 coords;
    out vec2 texCoord;

    void main(void)
    {
        gl_Position = matrix * vec4(coords.xy, 0, 1);
        texCoord = coords.zw;
    }
);

// Text rendering fragment shader program
static const GLchar* textFragmentShaderSrc = GLSL
(
    uniform sampler2D tex;
    uniform vec4 color;
    in vec2 texCoord;
    out vec4 fragColor;

    void main(void)
    {
        fragColor = vec4(1, 1, 1, texture(tex, texCoord).r) * color;
    }
);

// Rectangle rendering vertex shader program
static const GLchar* rectVertexShaderSrc = GLSL
(
    uniform mat4 matrix;
    in vec2 coords;

    void main(void)
    {
        gl_Position = matrix * vec4(coords.xy, 0, 1);
    }
);

// Rectangle rendering fragment shader program
static const GLchar* rectFragmentShaderSrc = GLSL
(
    uniform vec4 color;
    out vec4 fragColor;

    void main(void)
    {
        fragColor = color;
    }
);

@interface OpenGLPatternScopeView : NSOpenGLView

@property (nonatomic, strong, readwrite) id<Decoder> decoder;
@property (nonatomic, assign, readwrite) unsigned int channels;
@property (nonatomic, assign, readwrite) unsigned int currentRow;
@property (nonatomic, assign, readwrite) int currentPosition;

@property (nonatomic, assign, readwrite) BOOL blankZero;
@property (nonatomic, assign, readwrite) BOOL prospectiveMode;
@property (nonatomic, assign, readwrite) BOOL lowercaseNotes;
@property (nonatomic, assign, readwrite) BOOL lowercaseHex;

@property (nonatomic, copy,   readwrite) NSString* fontName;
@property (nonatomic, assign, readwrite) float fontSize;

@property (nonatomic, assign, readwrite) glm::vec4 backgroundColor;
@property (nonatomic, assign, readwrite) glm::vec4 frameworkColor;
@property (nonatomic, assign, readwrite) glm::vec4 normalRowTextColor;
@property (nonatomic, assign, readwrite) glm::vec4 currentRowTextColor;
@property (nonatomic, assign, readwrite) glm::vec4 beat1RowTextColor;
@property (nonatomic, assign, readwrite) glm::vec4 beat2RowTextColor;
@property (nonatomic, assign, readwrite) glm::vec4 prospectiveRowTextColor;

@end
