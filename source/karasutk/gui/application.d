/**
 *  application module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.application;

import karasutk.gui.mains;
import karasutk.gui.mesh;
import karasutk.gui.event;

/// application objects holder.
struct Application {

    @property @safe pure nothrow @nogc {
        EventQueue eventQueue() {return eventQueue_;}
        MeshFactory meshFactory() {return meshFactory_;}
    }

private:
    EventQueue eventQueue_;
    MeshFactory meshFactory_;
}

