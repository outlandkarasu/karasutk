/**
 *  texture module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.texture;

import std.container : Array;

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
        Pixel opIndex(size_t i);
    }

    Pixel opIndexAssign(Pixel p, size_t x, size_t y) @safe @nogc;

    // support foreach statement
    int opApply(int delegate(ref Pixel) dg);
    int opApply(int delegate(ref Pixel, size_t x, size_t y) dg);

    /// fill this texture by a color
    void fill(Pixel p);
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

