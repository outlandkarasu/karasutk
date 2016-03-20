/**
 *  application module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.application;

import karasutk.gui.mains;
import karasutk.gui.mesh;
import karasutk.gui.shader;
import karasutk.gui.event;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/// application objects holder.
abstract class Application {

    this(EventQueue eventQueue, MeshFactory meshFactory, ShaderFactory shaderFactory) @safe @nogc nothrow {
        this.eventQueue_ = eventQueue;
        this.meshFactory_ = meshFactory;
        this.shaderFactory_ = shaderFactory;
    }

    @property @safe pure nothrow @nogc {
        EventQueue eventQueue() {return eventQueue_;}
        MeshFactory meshFactory() {return meshFactory_;}
        ShaderFactory shaderFactory() {return shaderFactory_;}
    }

    /// draw next frame
    abstract void drawFrame(void delegate() dg);

private:
    EventQueue eventQueue_;
    MeshFactory meshFactory_;
    ShaderFactory shaderFactory_;
}

package:

class SdlApplication : Application {

    this(SDL_Window* window) @safe {
        super(new SdlEventQueue(), new SdlMeshFactory(), new SdlShaderFactory());
        this.window_ = window;
    }

    override void drawFrame(void delegate() dg) {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        scope(exit) {
            glFlush();
            SDL_GL_SwapWindow(window_);
        }

        dg();
    }

private:

    SDL_Window* window_;
}

