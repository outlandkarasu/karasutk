/**
 *  3D shader for SDL module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.shader;

import std.traits :
    Fields,
    FieldNameTuple,
    isStaticArray,
    isArray;
import karasutk.gui.shader;
import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.gl : GlException, checkGlError;
import karasutk.gui.sdl.texture : SdlGpuTexture2d;
import gl3n.linalg : mat4;

import derelict.opengl3.gl3;

class SdlShader(P) : AbstractShader!P {

    this(SdlContext context, ShaderSource source) {
        this.source_ = source;
        programId_ = compileProgram(source_);

        foreach(i, name; PARAMETER_NAMES) {
            locations_[i] = glGetUniformLocation(programId_, name);
        }
    }

    ~this() @nogc nothrow {
        glDeleteProgram(programId_);
    }

    /// do process during use program.
    void duringUse(void delegate(ParametersBinder) dg) const {
        glUseProgram(programId_);
        scope(exit) glUseProgram(0);
        dg(&bindParameters);
    }

private:

    alias PARAMETER_NAMES = FieldNameTuple!P;
    alias PARAMETER_TYPES = Fields!P;

    void bindParameters(ref const(ShaderParameters) params) const {
        foreach(i, name; PARAMETER_NAMES) {
            auto loc = locations_[i];
            alias FieldType = PARAMETER_TYPES[i];

            enum valueName = "params." ~ name;
            GLenum texIndex = 0;

            static if(is(FieldType : mat4)) {
                bindMatrix(loc, mixin(valueName));
            } else static if(is(FieldType P : SdlGpuTexture2d!P)) {
                bindTexture(loc, texIndex, mixin(valueName));
                ++texIndex;
            } else {
                static assert(0, valueName ~ " unsupported type: " ~ FieldType.stringof);
            }
            checkGlError();
        }
    }

    const @nogc nothrow {
        void bindMatrix(GLint loc, ref const(mat4) m) {
            glUniformMatrix4fv(loc, 1, GL_TRUE, m.value_ptr);
        }
        void bindTexture(P)(
                GLint loc,
                GLenum texIndex,
                const(SdlGpuTexture2d!P) texture) {
            if(!texture) {
                return;
            }
    
            glActiveTexture(GL_TEXTURE0 + texIndex);
            glBindTexture(GL_TEXTURE_2D, texture.id);
            glUniform1i(loc, texIndex);
        }
    }

    ShaderSource source_;
    GLuint programId_;
    GLint[FieldNameTuple!(P).length] locations_;
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

