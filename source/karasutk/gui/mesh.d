/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import std.traits : isIntegral, isUnsigned;
import karasutk.gui.buffer : Buffer;
import karasutk.gui.context : Context;

/// vertices array
alias Vertices(V) = Buffer!V;

/// indices array
alias Indices(I) = Buffer!I;

/// is index type?
enum isIndex(T) = isIntegral!T && isUnsigned!T;

/// point indices buffer 
alias Points(T) = Indices!T;

/// line index
struct Line(T) {
    static assert(isIndex!T);
align(1):
    T p1;
    T p2;
}

/// line indices array
alias Lines(T) = Indices!(Line!T);

/// triangle index
struct Triangle(T) {
    static assert(isIndex!T);
align(1):
    T p1;
    T p2;
    T p3;
}

/// triangle indices array
alias Triangles(T) = Indices!(Triangle!T);

/// index types
alias IndexType(I : Line!(I)) = I;
alias IndexType(I : Triangle!(I)) = I;
alias IndexType(F) = F;

/// Mesh interface
interface AbstractMesh(F) {

    alias Face = F;
    alias Index = IndexType!F;

    /// face topology types
    enum Topology {
        POINTS,
        LINES,
        TRIANGLES,
    }

    static if(is(F I : Line!I)) {
        enum TOPOLOGY = Topology.LINES;
    } else static if(is(F I : Triangle!I)) {
        enum TOPOLOGY = Topology.TRIANGLES;
    } else static if(isIntegral!F) {
        enum TOPOLOGY = Topology.POINTS;
    } else {
        static assert(false);
    }

    /// draw to display
    void draw();
}

struct VertexAttributes {
    float[3] position;
    float[3] color;
    float[2] uv;
}

import karasutk.gui.sdl.mesh : SdlMesh;
alias Mesh = SdlMesh;

/// make mesh object
Mesh!(V, F) makeMesh(V, F)(
        Context context, const(Buffer!V) vertices, const(Buffer!F) indices) {
    return new Mesh!(V, F)(context, vertices, indices);
}

