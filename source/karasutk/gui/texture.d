/**
 *  texture module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.texture;

import karasutk.gui.gpu : GpuAsset;

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
interface AbstractTexture2d(P) : GpuAsset {

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
    int opApply(int delegate(size_t y, Pixel[]) dg);

    /// fill this texture by a color
    void fill(Pixel p);

    void select();
}

/// Texture factory interface
interface AbstractTextureFactory(RGBT, RGBAT) {

    alias RgbTexture2d = RGBT;
    alias RgbaTexture2d = RGBAT;

    /// make a RGB texture
    RgbTexture2d makeRgbTexture2d(size_t width, size_t height);

    /// make a RGBA texture
    RgbaTexture2d makeRgbaTexture2d(size_t width, size_t height);
}

import karasutk.gui.sdl.texture;
alias TextureFactory = SdlTextureFactory;
alias Texture2d = SdlTexture2d;
alias RgbTexture2d = Texture2d!(Rgb);
alias RgbaTexture2d = Texture2d!(Rgba);

