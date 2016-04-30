/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import karasutk.gui.gpu : GpuAsset;

import std.container : Array;
import std.traits : isIntegral;

/// generic buffer.
class Buffer(E) {

    alias Element = E;

    /// default constructor.
    this() {}

    /// initialize with capacity.
    this(size_t cap) {array_.reserve(cap);}

    @property pure nothrow @safe @nogc const {
        size_t length() {return array_.length;}
    }

    /// reserve memory buffer.
    void reserve(size_t n) {array_.reserve(n);}

    /// return arrayslice
    const(Element)[] opSlice() const {
        return (&array_[0])[0 .. array_.length];
    }

    /// append new stuff.
    void opOpAssign(string op, Stuff)(Stuff e) if (op == "~") {
        array_ ~= e;
    }

    /// clear vertices.
    void clear() {array_.clear();}

protected:

    /// append new elements.
    void add(E)(E e) {array_ ~= e;}

private:
    Array!Element array_;
}

/// vertices array
alias Vertices(V) = Buffer!V;

/// indices array
alias Indices(I) = Buffer!I;

/// point indices buffer 
alias Points(T) = Indices!T;

/// line index
struct Line(T) {
    static assert(isIntegral!T);
align(1):
    T p1;
    T p2;
}

/// line indices array
alias Lines(T) = Indices!(Line!T);

/// triangle index
struct Triangle(T) {
    static assert(isIntegral!T);
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
Mesh!(V, F) makeMesh(V, F)(Vertices!V vertices, Indices!F indices) {
    return new Mesh!(V, F)(vertices, indices);
}

