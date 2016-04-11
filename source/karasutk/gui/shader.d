/**
 *  3D shader module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.shader;

import std.stdio : writefln;

import karasutk.gui.gpu : GpuAsset;
import karasutk.gui.gl : GlException, checkGlError;
import karasutk.gui.texture : Texture2d, Rgb;

import derelict.opengl3.gl3;

/// shader sources
struct ShaderSource {
    string vertexShader;
    string fragmentShader;
}

/// shader placeholder
interface Shader : GpuAsset {

    alias ParameterBinder = void delegate(Texture2d!Rgb);

    /// do process during use program.
    void duringUse(void delegate(ParameterBinder) dg) const;
}

/// shader factory 
interface ShaderFactory {

    /// make from source
    Shader makeShader(const(ShaderSource) source);
}

package:

class SdlShaderFactory : ShaderFactory {

    Shader makeShader(const(ShaderSource) source) {
        return new SdlShader(source);
    }
}

private:

class SdlShader : Shader {

    this(ref const(ShaderSource) source) {
        this.source_ = source;
    }

    ~this() @nogc nothrow {
        releaseFromGpu();
    }

    /// transfer data to GPU.
    void transferToGpu() {
        // release old program
        releaseFromGpu();

        programId_ = compileProgram(source_);
    }

    /// release data from GPU.
    void releaseFromGpu() @nogc nothrow {
        if(programId_) {
            glDeleteProgram(programId_);
            programId_ = 0;
        }
    }

    /// do process during use program.
    void duringUse(void delegate(ParameterBinder) dg) const {
        glUseProgram(programId_);
        scope(exit) glUseProgram(0);
        dg(&bindParameter);
    }

private:

    void bindParameter(Texture2d!Rgb texture) {
        auto texLocation = glGetUniformLocation(programId_, "tex");
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture.id);
        glUniform1i(texLocation, 0);
        checkGlError();
    }

    ShaderSource source_;
    GLuint programId_;
}

/**
 *  compile shader.
 *
 *  Params:
 *      source = shader source.
 *  Returns:
 *      OpenGL shader program ID.
 */
GLuint compileProgram(ref const(ShaderSource) source) {
    // compile vertex shader
    immutable vs = glCreateShader(GL_VERTEX_SHADER);
    scope(exit) glDeleteShader(vs);
    compileShader(vs, source.vertexShader);

    // compile fragment shader
    immutable fs = glCreateShader(GL_FRAGMENT_SHADER);
    scope(exit) glDeleteShader(fs);
    compileShader(fs, source.fragmentShader);

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

void throwIfShaderError(alias getter, alias getLog, GLenum TYPE)(GLuint id) {
    GLint result = GL_FALSE;
    getter(id, TYPE, &result);
    if(result != GL_TRUE) {
        GLint logLength = 0;
        getter(id, GL_INFO_LOG_LENGTH, &logLength);
        auto message = new GLchar[logLength];

        GLsizei size;
        getLog(id, logLength, &size, message.ptr);
        throw new GlException(message[0 .. size].idup);
    }
}

alias throwIfShaderError!(glGetShaderiv, glGetShaderInfoLog, GL_COMPILE_STATUS)
    throwIfCompileError;

alias throwIfShaderError!(glGetProgramiv, glGetProgramInfoLog, GL_LINK_STATUS)
    throwIfLinkError;

