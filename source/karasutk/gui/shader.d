/**
 *  3D shader module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.shader;

import std.stdio : writefln;

import karasutk.gui.camera: Camera;
import karasutk.gui.gpu : GpuAsset;
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
interface AbstractShader : GpuAsset {

    alias ParametersBinder = void delegate(ShaderParameters);

    /// do process during use program.
    void duringUse(void delegate(ParametersBinder) dg) const;
}

/// shader factory 
interface AbstractShaderFactory(S) {

    alias Shader = S;

    /// make from source
    Shader makeShader(const(ShaderSource) source);
}

import karasutk.gui.sdl.shader : SdlShader;
alias Shader = SdlShader;

