/**
 *  3D shader for SDL module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.shader;

import karasutk.gui.shader;
import karasutk.gui.gl : GlException, checkGlError;

import derelict.opengl3.gl3;

class SdlShaderFactory : AbstractShaderFactory!SdlShader {

    Shader makeShader(const(ShaderSource) source) {
        return new SdlShader(source);
    }
}

class SdlShader : AbstractShader {

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
        texLocation_ = glGetUniformLocation(programId_, "tex");
        modelLocation_ = glGetUniformLocation(programId_, "M");
        viewLocation_ = glGetUniformLocation(programId_, "V");
        projectionLocation_ = glGetUniformLocation(programId_, "P");
        mvpLocation_ = glGetUniformLocation(programId_, "MVP");
    }

    /// release data from GPU.
    void releaseFromGpu() @nogc nothrow {
        if(programId_) {
            glDeleteProgram(programId_);
            programId_ = 0;
            texLocation_ = -1;
            modelLocation_ = -1;
            viewLocation_ = -1;
            projectionLocation_ = -1;
            mvpLocation_ = -1;
        }
    }

    /// do process during use program.
    void duringUse(void delegate(ParametersBinder) dg) const {
        glUseProgram(programId_);
        scope(exit) glUseProgram(0);
        dg(&bindParameters);
    }

private:

    void bindParameters(ShaderParameters params) const {
        bindTexture(params.texture);
        bindCamera(params.model, params.camera);
    }

    void bindTexture(Texture2d!Rgb texture) const {
        if(!texture) {
            return;
        }

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture.id);
        glUniform1i(texLocation_, 0);
        checkGlError();
    }

    void bindCamera(ref const mat4 model, ref const Camera camera) const {
        glUniformMatrix4fv(modelLocation_, 1, GL_TRUE, model.value_ptr);
        glUniformMatrix4fv(viewLocation_, 1, GL_TRUE, camera.view.value_ptr);
        glUniformMatrix4fv(projectionLocation_, 1, GL_TRUE, camera.projection.value_ptr);

        immutable mvp = camera.projection * camera.view * model;
        glUniformMatrix4fv(mvpLocation_, 1, GL_TRUE, mvp.value_ptr);
    }

    ShaderSource source_;
    GLuint programId_;
    GLint texLocation_ = -1;
    GLint modelLocation_ = -1;
    GLint viewLocation_ = -1;
    GLint projectionLocation_ = -1;
    GLint mvpLocation_ = -1;
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

