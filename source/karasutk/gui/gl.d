/**
 *  OpenGL utility module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */ 
module karasutk.gui.gl;

import std.format : format;
import std.stdio : writefln;

import derelict.opengl3.gl3;

/// OpenGL related exception.
class GlException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// error check for OpenGL
void checkGlError(string file = __FILE__, size_t line = __LINE__) {
    GLenum[] errors;
    for(GLenum error; (error = glGetError()) != GL_NO_ERROR;) {
        errors ~= error;
    }

    if(errors.length > 0) {
        throw new GlException(format("%s", errors), file, line);
    }
}

