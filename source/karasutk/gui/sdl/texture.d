/**
 *  SDL texture module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.texture;

import karasutk.gui.texture;

import std.experimental.allocator.mallocator : Mallocator;

import derelict.opengl3.gl3;

import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.gl : checkGlError;

class SdlTexture2d(P) : AbstractTexture2d!(P) {

    this(size_t width, size_t height) @nogc
    in {
        assert(width == height);
        switch(width) {
        case 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024:
            break;
        default:
            assert(0);
        }
    } body {
        super(width, height);
    }
}

class SdlGpuTexture2d(P) {

    this(SdlContext context, SdlTexture2d!P t)
    out {
        assert(textureId_ != 0);
    } body {
        glGenTextures(1, &textureId_);
        checkGlError();

        // transfer pixel data
        bind();
        scope(exit) unbind();

        glTexImage2D(
                GL_TEXTURE_2D,
                0,
                PIXEL_FORMAT,
                cast(GLsizei) t.width,
                cast(GLsizei) t.height,
                0,
                PIXEL_FORMAT,
                PIXEL_TYPE,
                cast(const(GLvoid)*) t.ptr);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        checkGlError();
    }

    ~this() @nogc nothrow {
        glDeleteTextures(1, &textureId_);
    }

    void bind()
    in {
        assert(textureId_ != 0);
    } body {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId_);
        checkGlError();
    }

    void unbind() @nogc nothrow
    in {
        assert(textureId_ != 0);
    } body {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    @property GLuint id() const @safe @nogc nothrow pure {
        return textureId_;
    }

private:
    enum PIXEL_TYPE = GL_UNSIGNED_BYTE;
    static if(is(P == Rgb)) {
        enum PIXEL_FORMAT = GL_RGB;
    } else static if(is(P == Rgba)) {
        enum PIXEL_FORMAT = GL_RGBA;
    }

    GLuint textureId_;
}

