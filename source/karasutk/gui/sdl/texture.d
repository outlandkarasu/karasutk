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

import karasutk.gui.gl : checkGlError;

class SdlTextureFactory : AbstractTextureFactory!(
        SdlTexture2d!Rgb, SdlTexture2d!Rgba) {

    RgbTexture2d makeRgbTexture2d(size_t width, size_t height) {
        return new SdlTexture2d!Rgb(width, height);
    }

    RgbaTexture2d makeRgbaTexture2d(size_t width, size_t height) {
        return new SdlTexture2d!Rgba(width, height);
    }
}

class SdlTexture2d(P) : AbstractTexture2d!(P) {

    enum PIXEL_TYPE = GL_UNSIGNED_BYTE;
    static if(is(P == Rgb)) {
        enum PIXEL_FORMAT = GL_RGB;
    } else static if(is(P == Rgba)) {
        enum PIXEL_FORMAT = GL_RGBA;
    }

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
        this.width_ = width;
        this.height_ = height;
        this.pixels_ = cast(Pixel[]) Mallocator.instance.allocate(width * height * Pixel.sizeof);
    }

    ~this() @nogc {
        releaseFromGpu();
        Mallocator.instance.deallocate(pixels_);
    }

override:

    @property const @safe pure nothrow @nogc {
        size_t width() {return width_;}
        size_t height() {return height_;}
        size_t length() {return width_ * height_;}
        Pixel opIndex(size_t x, size_t y) {return pixels_[y * width_ + x];}
        int id() {return textureId_;}
    }

    Pixel opIndexAssign(Pixel p, size_t x, size_t y) @safe @nogc {
        return pixels_[width_ * y + x] = p;
    }

    int opApply(int delegate(ref Pixel) dg) {
        int result = 0;
        foreach(ref p; pixels_) {
            result = dg(p);
            if(result) {
                break;
            }
        }
        return result;
    }

    int opApply(int delegate(size_t x, size_t y, ref Pixel) dg) {
        int result = 0;
        size_t x = 0;
        size_t y = 0;
        foreach(ref p; pixels_) {
            result = dg(x, y, p);
            if(result) {
                break;
            }

            // calculate next position
            ++x;
            if(x == width_) {
                x = 0;
                ++y;
            }
        }
        return result;
    }

    int opApply(int delegate(size_t y, Pixel[]) dg) {
        int result = 0;
        for(size_t y = 0; y < height_; ++y) {
            immutable pos = y * width_;
            result = dg(y, pixels_[pos .. pos + width_]);
            if(result) {
                break;
            }
        }
        return result;
    }

    void fill(Pixel p) @safe pure nothrow @nogc {pixels_[] = p;}

    void select()
    in {
        assert(textureId_ != 0);
    } body {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId_);
    }

    void transferToGpu() {
        // release old data
        releaseFromGpu();
        scope(failure) releaseFromGpu();

        glGenTextures(1, &textureId_);
        checkGlError();

        // transfer pixel data
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId_);
        scope(exit) glBindTexture(GL_TEXTURE_2D, 0);

        glTexImage2D(
                GL_TEXTURE_2D,
                0,
                PIXEL_FORMAT,
                cast(GLsizei) width_,
                cast(GLsizei) height_,
                0,
                PIXEL_FORMAT,
                PIXEL_TYPE,
                cast(const(GLvoid)*) pixels_.ptr);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        checkGlError();
    }

    void releaseFromGpu() nothrow {
        if(textureId_) {
            glDeleteTextures(1, &textureId_);
            textureId_ = 0;
        }
    }

private:

    Pixel[] pixels_;
    size_t width_;
    size_t height_;
    GLuint textureId_;
}

