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

    this(EventQueue eventQueue) @safe @nogc nothrow {
        this.eventQueue_ = eventQueue;
    }

    @property @safe pure nothrow @nogc {
        EventQueue eventQueue() {return eventQueue_;}
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
}

import karasutk.gui.sdl.context : SdlContext;
alias Context = SdlContext;
