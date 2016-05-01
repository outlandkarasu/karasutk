/**
 *  texture module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.texture;

import std.experimental.allocator.mallocator : Mallocator;
import karasutk.gui.context;

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

/// abstract 2D texture class
abstract class AbstractTexture2d(P) {

    /// pixel type
    alias Pixel = P;

    this(size_t width, size_t height) @nogc {
        this.width_ = width;
        this.height_ = height;
        this.pixels_ = cast(Pixel[]) Mallocator.instance.allocate(width * height * Pixel.sizeof);
    }

    ~this() @nogc {
        Mallocator.instance.deallocate(pixels_);
    }

    // properties
    @property @safe pure nothrow @nogc {
        size_t width() const {return width_;}
        size_t height() const {return height_;}
        size_t length() const {return width_ * height_;}
        inout(Pixel)* ptr() inout {return pixels_.ptr;}
        ref inout(Pixel) opIndex(size_t x, size_t y) inout {
            return pixels_[y * width_ + x];
        }
    }

    void opIndexAssign(Pixel p, size_t x, size_t y) @safe @nogc {
        pixels_[width_ * y + x] = p;
    }

    // support foreach statement
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

    /// apply per pixel with position
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

    /// apply per line with rows
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

private:
    Pixel[] pixels_;
    size_t width_;
    size_t height_;
}

import karasutk.gui.sdl.texture : SdlTexture2d, SdlGpuTexture2d;
alias Texture2d = SdlTexture2d;
alias GpuTexture2d = SdlGpuTexture2d;

/// helper function.
GpuTexture2d!P makeGpuTexture(P)(Context context, Texture2d!(P) texture) {
    return new GpuTexture2d!P(context, texture);
}

