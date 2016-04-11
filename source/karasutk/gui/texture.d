/**
 *  texture module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.texture;

import std.experimental.allocator.mallocator : Mallocator;

import derelict.opengl3.gl3;

import karasutk.gui.gpu : GpuAsset;
import karasutk.gui.gl : checkGlError;

/// RGB color structure
struct Rgb {
align(1):
    ubyte r;
    ubyte g;
    ubyte b;
}

/// RGBA color structure
struct Rgba {
align(1):
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}

/// 2D texture interface
interface Texture2d(P) : GpuAsset {

    /// pixel type
    alias Pixel = P;

    // properties
    @property const @safe pure nothrow @nogc {
        size_t width();
        size_t height();
        size_t length();
        Pixel opIndex(size_t x, size_t y);
        int id();
    }

    Pixel opIndexAssign(Pixel p, size_t x, size_t y) @safe @nogc;

    // support foreach statement
    int opApply(int delegate(ref Pixel) dg);
    int opApply(int delegate(size_t x, size_t y, ref Pixel) dg);

    /// fill this texture by a color
    void fill(Pixel p);

    void select();
}

alias RgbTexture2d = Texture2d!(Rgb);
alias RgbaTexture2d = Texture2d!(Rgba);

/// Texture factory interface
interface TextureFactory {

    /// make a RGB texture
    RgbTexture2d makeRgbTexture2d(size_t width, size_t height);

    /// make a RGBA texture
    RgbaTexture2d makeRgbaTexture2d(size_t width, size_t height);
}

package:

class SdlTextureFactory : TextureFactory {

    RgbTexture2d makeRgbTexture2d(size_t width, size_t height) {
        return new SdlTexture2d!Rgb(width, height);
    }

    RgbaTexture2d makeRgbaTexture2d(size_t width, size_t height) {
        return new SdlTexture2d!Rgba(width, height);
    }
}

class SdlTexture2d(P) : Texture2d!(P) {

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
        foreach(p; pixels_) {
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
        foreach(p; pixels_) {
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

