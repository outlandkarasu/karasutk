/**
 *  application context module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.context;

import karasutk.gui.event;
import karasutk.gui.mesh;
import karasutk.gui.shader;
import karasutk.gui.texture;

/// application objects holder.
abstract class AbstractContext {

    this(EventQueue eventQueue,
            MeshFactory meshFactory,
            ShaderFactory shaderFactory,
            TextureFactory textureFactory) @safe @nogc nothrow {
        this.eventQueue_ = eventQueue;
        this.meshFactory_ = meshFactory;
        this.textureFactory_ = textureFactory;
        this.shaderFactory_ = shaderFactory;
    }

    @property @safe pure nothrow @nogc {
        EventQueue eventQueue() {return eventQueue_;}
        MeshFactory meshFactory() {return meshFactory_;}
        TextureFactory textureFactory() {return textureFactory_;}
        ShaderFactory shaderFactory() {return shaderFactory_;}
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
    MeshFactory meshFactory_;
    TextureFactory textureFactory_;
    ShaderFactory shaderFactory_;
}

import karasutk.gui.sdl.context : SdlContext;
alias Context = SdlContext;
