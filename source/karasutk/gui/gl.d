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
class GLException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// error check for OpenGL
void checkGLError(string file = __FILE__, size_t line = __LINE__) {
    GLenum[] errors;
    for(GLenum error; (error = glGetError()) != GL_NO_ERROR;) {
        errors ~= error;
    }

    if(errors.length > 0) {
        throw new GLException(format("%s", errors), file, line);
    }
}

/**
 *  compile shader.
 *
 *  Params:
 *      vsSource = vertex shader source.
 *      fsSource = fragment shader source.
 *  Returns:
 *      OpenGL error code.
 */
GLuint compileProgram(string vsSource, string fsSource) {
    // compile vertex shader
    immutable vs = glCreateShader(GL_VERTEX_SHADER);
    scope(exit) glDeleteShader(vs);
    compileShader(vs, vsSource);

    // compile fragment shader
    immutable fs = glCreateShader(GL_FRAGMENT_SHADER);
    scope(exit) glDeleteShader(fs);
    compileShader(fs, fsSource);

    // link programs
    immutable program = glCreateProgram();
    glAttachShader(program, vs);
    scope(exit) glDetachShader(program, vs);
    glAttachShader(program, fs);
    scope(exit) glDetachShader(program, fs);
    glLinkProgram(program);
    throwIfLinkError(program);

    return program;
}

/**
 *  compile shader
 *
 *  Params:
 *      id = shader id
 *      source = shader source
 */
void compileShader(GLuint id, string source) {
    const char* sourcePtr = source.ptr;
    glShaderSource(id, 1, &sourcePtr, null);
    glCompileShader(id);
    throwIfCompileError(id);
}

private void throwIfShaderError(alias getter, alias getLog, GLenum TYPE)(GLuint id) {
    GLint result = GL_FALSE;
    getter(id, TYPE, &result);
    if(result != GL_TRUE) {
        GLint logLength = 0;
        getter(id, GL_INFO_LOG_LENGTH, &logLength);
        auto message = new GLchar[logLength];

        GLsizei size;
        getLog(id, logLength, &size, message.ptr);
        throw new GLException(message[0 .. size].idup);
    }
}

private alias throwIfShaderError!(glGetShaderiv, glGetShaderInfoLog, GL_COMPILE_STATUS)
    throwIfCompileError;

private alias throwIfShaderError!(glGetProgramiv, glGetProgramInfoLog, GL_LINK_STATUS)
    throwIfLinkError;

