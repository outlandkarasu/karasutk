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
import karasutk.gui.sdl.gl : checkGlError, MappedBufferData;

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

class AbstractSdlGpuTexture2d(P) {

    enum PIXEL_TYPE = GL_UNSIGNED_BYTE;
    static if(is(P == Rgb)) {
        enum PIXEL_FORMAT = GL_RGB;
    } else static if(is(P == Rgba)) {
        enum PIXEL_FORMAT = GL_RGBA;
    }

    this(size_t width, size_t height)
    out {
        assert(textureId_ != 0);
    } body {
        glGenTextures(1, &textureId_);
        checkGlError();

        this.width_ = width;
        this.height_ = height;
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

    @property const @safe @nogc nothrow pure {
        size_t width() {return width_;}
        size_t height() {return height_;}
        GLuint id() {return textureId_;}
    }

private:
    size_t width_;
    size_t height_;
    GLuint textureId_;
}

class SdlGpuTexture2d(P) : AbstractSdlGpuTexture2d!(P) {

    this(SdlContext context, SdlTexture2d!P t) {
        super(t.width, t.height);

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
        checkGlError();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        checkGlError();
    }
}

class SdlMappedGpuTexture2d(P) : AbstractSdlGpuTexture2d!(P) {

    this(SdlContext context, size_t width, size_t height) {
        super(width, height);
        buffer_ = new Buffer();
        buffer_.allocate(width * height);

        // buffer bind to texture
        glBindBuffer(GL_PIXEL_UNPACK_BUFFER, buffer_.id);
        checkGlError();
        scope(exit) glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0); 

        bind();
        scope(exit) unbind();

        glTexImage2D(
                GL_TEXTURE_2D,
                0,
                PIXEL_FORMAT,
                cast(GLsizei) width,
                cast(GLsizei) height,
                0,
                PIXEL_FORMAT,
                PIXEL_TYPE,
                null);
        checkGlError();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        checkGlError();
    }

    ~this() {
        destroy(buffer_);
    }

    int opApply(scope int delegate(size_t, size_t, ref P) dg) {
        return opApplyByPixel(dg);
    }

    int opApply(scope int delegate(ref P) dg) {
        return opApplyByPixel(dg);
    }

    int opApply(scope int delegate(size_t, P[]) dg) {
        return opApplyByLine(dg);
    }

    int opApply(scope int delegate(P[]) dg) {
        return opApplyByLine(dg);
    }

private:
    int opApplyByPixel(F)(F dg) {
        int result = 0;
        buffer_.duringMap((pixels) {
            result = ByPixel!P().opApply(dg);
        });
        return result;
    }

    int opApplyByLine(F)(F dg) {
        int result = 0;
        buffer_.duringMap((pixels) {
            result = ByLine!P().opApply(dg);
        });
        return result;
    }

    alias Buffer = MappedBufferData!(GL_PIXEL_PACK_BUFFER, P);
    Buffer buffer_;
}

