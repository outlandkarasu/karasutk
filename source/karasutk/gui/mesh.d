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
class Buffer(E, F) {

    alias Element = E;
    alias Field = F;

    /// default constructor.
    this() {}

    /// initialize with capacity.
    this(size_t cap) {array_.reserve(cap);}

    @property pure nothrow @safe @nogc const {
        size_t length() {return array_.length;}
        size_t fieldCount() {
            return array_.length * FIELDS_PER_ELEMENT;
        }
    }

    /// reserve memory buffer.
    void reserve(size_t n) {array_.reserve(n);}

    /// return arrayslice
    const(Element)[] opSlice() const {
        return (&array_[0])[0 .. array_.length];
    }

    /// return field slice
    const(Field)[] fieldSlice() const {
        return (cast(const(Field)*)&array_[0])[0 .. fieldCount];
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
    enum FIELDS_PER_ELEMENT = Element.sizeof / Field.sizeof;
    Array!Element array_;
}

/// vertices array
alias Vertices(V) = Buffer!(V, V);

/// face topology types
enum FaceTopology {
    POINTS,
    LINES,
    TRIANGLES,
}

/// generic index buffer
class IndexBuffer(T, F) : Buffer!(T, F) {

    this(FaceTopology topology) {
        this.topology_ = topology;
    }

    this(FaceTopology topology, size_t cap) {
        super(cap);
        this.topology_ = topology;
    }

    @property FaceTopology topology() const @safe pure nothrow {
        return topology_;
    }

private:
    FaceTopology topology_;
}

/// point indices buffer 
class Points(T) : IndexBuffer!(T, T) {
    enum TOPOLOGY = FaceTopology.POINTS;
    this() {super(TOPOLOGY);}
    this(size_t cap) {super(TOPOLOGY, cap);}
}

/// line index
struct Line(T) {
    static assert(isIntegral!T);
align(1):
    T p1;
    T p2;
}

/// line indices array
class Lines(T) : IndexBuffer!(Line!T, T) {
    enum TOPOLOGY = FaceTopology.LINES;
    this() {super(TOPOLOGY);}
    this(size_t cap) {super(TOPOLOGY, cap);}
}

/// triangle index
struct Triangle(T) {
    static assert(isIntegral!T);
align(1):
    T p1;
    T p2;
    T p3;
}

/// triangle indices array
class Triangles(T) : IndexBuffer!(Triangle!T, T) {
    enum TOPOLOGY = FaceTopology.TRIANGLES;
    this() {super(TOPOLOGY);}
    this(size_t cap) {super(TOPOLOGY, cap);}
}

/// Mesh interface
interface AbstractMesh {

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
Mesh!(V, I) makeMesh(V, I)(
        Vertices!V vertices, IndexBuffer!I indices) {
    return new Mesh!(V, I)(vertices, indices);
}

