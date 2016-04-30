/**
 *  application context module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.context;

import karasutk.gui.event;
import karasutk.gui.mesh;
import karasutk.gui.texture;

/// application objects holder.
abstract class AbstractContext {

    this(EventQueue eventQueue,
            TextureFactory textureFactory) @safe @nogc nothrow {
        this.eventQueue_ = eventQueue;
        this.textureFactory_ = textureFactory;
    }

    @property @safe pure nothrow @nogc {
        EventQueue eventQueue() {return eventQueue_;}
        TextureFactory textureFactory() {return textureFactory_;}
    }

    /// draw next frame
    abstract void drawFrame(void delegate() dg);

    @property const {
        uint windowWidth();
        uint windowHeight();
    }

    void quit();

private:
    EventQueue eventQueue_;
    TextureFactory textureFactory_;
}

import karasutk.gui.sdl.context : SdlContext;
alias Context = SdlContext;
