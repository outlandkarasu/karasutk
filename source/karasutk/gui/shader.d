/**
 *  3D shader module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.shader;

import std.stdio : writefln;
import karasutk.gui.camera : Camera;
import karasutk.gui.context : Context;
import karasutk.gui.texture : GpuTexture2d, Rgb;
import gl3n.linalg : mat4;

/// shader sources
struct ShaderSource {
    string vertexShader;
    string fragmentShader;
}

/// shader parameters
struct ShaderParameters {
    GpuTexture2d!Rgb texture;
    Camera camera;
    mat4 model;
}

/// shader placeholder
interface AbstractShader {

    alias ParametersBinder = void delegate(ShaderParameters);

    /// do process during use program.
    void duringUse(void delegate(ParametersBinder) dg) const;
}

import karasutk.gui.sdl.shader : SdlShader;
alias Shader = SdlShader;

/// helper function.
Shader makeShader(Context context, ShaderSource source) {
    return new Shader(context, source);
}

