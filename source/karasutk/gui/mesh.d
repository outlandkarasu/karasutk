/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import std.container : Array;
import std.stdio : writefln;

import derelict.opengl3.gl3;

import karasutk.gui.gpu :
    GpuAsset,
    GpuReleasableAsset;
import karasutk.gui.gl :
    checkGlError,
    VertexAttribute,
    VertexElementArrayBuffer,
    VertexArrayObject;

/// number for mesh coordinate
alias Number = float;

/// Mesh interface
interface Mesh : GpuAsset {

    /// face topology types
    enum FaceTopology {
        POINTS,
        LINES,
        TRIANGLES,
    }

    /// draw to display
    void draw();
}

/// Mesh factory interface.
interface MeshFactory {

    /// vertices appender function.
    alias uint delegate(Number, Number, Number) VertexAppender;

    /// point appender function.
    alias void delegate(uint) PointAppender;

    /// line appender function.
    alias void delegate(uint, uint) LineAppender;

    /// triangle appender function.
    alias void delegate(uint, uint, uint) TriangleAppender;

    /// color appender function.
    alias void delegate(Number, Number, Number) ColorAppender;

    /// add points by user delegate.
    Mesh makePoints(void delegate(VertexAppender, PointAppender, ColorAppender) dg);

    /// add lines by user delegate.
    Mesh makeLines(void delegate(VertexAppender, LineAppender, ColorAppender) dg);

    /// add triangles by user delegate.
    Mesh makeTriangles(void delegate(VertexAppender, TriangleAppender, ColorAppender) dg);
}

package:

class SdlMeshFactory : MeshFactory {

    /// add points by user delegate.
    Mesh makePoints(void delegate(VertexAppender, PointAppender, ColorAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.POINTS);
        dg(&mesh.addVertex, &mesh.addIndex, &mesh.addColor);
        return mesh;
    }

    /// add lines by user delegate.
    Mesh makeLines(void delegate(VertexAppender, LineAppender, ColorAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.LINES);
        void addLine(uint p1, uint p2) {
            mesh.addIndex(p1);
            mesh.addIndex(p2);
        }
        dg(&mesh.addVertex, &addLine, &mesh.addColor);
        return mesh;
    }

    /// add triangles by user delegate.
    Mesh makeTriangles(void delegate(VertexAppender, TriangleAppender, ColorAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.TRIANGLES);
        void addTriangle(uint p1, uint p2, uint p3) {
            mesh.addIndex(p1);
            mesh.addIndex(p2);
            mesh.addIndex(p3);
        }
        dg(&mesh.addVertex, &addTriangle, &mesh.addColor);
        return mesh;
    }
}

/// mesh class for SDL
class SdlMesh : Mesh {

    this(FaceTopology topology) {this.topology_ = topology;}

    ~this() @nogc nothrow {
        releaseFromGpu();
        vertexArray_.clear();
        colorArray_.clear();
        indexElementArray_.clear();
    }

    void transferToGpu() {
        // release old data
        releaseFromGpu();
        scope(failure) releaseFromGpu();

        // create VAO
        assert(vertexArrayObject_ is null);
        vertexArrayObject_ = new VertexArrayObject();

        // use VAO
        vertexArrayObject_.bind();
        scope(exit) vertexArrayObject_.unbind();

        // transfer verticies to a GPU buffer.
        assert(vertexArrayBuffer_ is null);
        vertexArrayBuffer_ = new VertexArrayBuffer(VertexAttributeIndex.Position); 
        vertexArrayBuffer_.transfer((&vertexArray_[0])[0 .. vertexArray_.length]);

        // transfer vertex colors to a GPU buffer.
        assert(colorArrayBuffer_ is null);
        colorArrayBuffer_ = new ColorArrayBuffer(VertexAttributeIndex.Color); 
        colorArrayBuffer_.transfer((&colorArray_[0])[0 .. colorArray_.length]);

        // transfer indicies to a GPU buffer.
        assert(indexElementArrayBuffer_ is null);
        indexElementArrayBuffer_ = new IndexElementArrayBuffer(glType); 
        indexElementArrayBuffer_.transfer((&indexElementArray_[0])[0 .. indexElementArray_.length]);
    }

    void releaseFromGpu() nothrow @nogc
    out{
        assert(vertexArrayBuffer_ is null);
        assert(colorArrayBuffer_ is null);
        assert(indexElementArrayBuffer_ is null);
        assert(vertexArrayObject_ is null);
    } body {
        destroyObject(vertexArrayBuffer_);
        destroyObject(colorArrayBuffer_);
        destroyObject(indexElementArrayBuffer_);
        destroyObject(vertexArrayObject_);
    }

    void draw()
    in{
        assert(vertexArrayObject_ !is null);
        assert(indexElementArrayBuffer_ !is null);
    } body {
        // bind VAO
        vertexArrayObject_.bind();
        scope(exit) vertexArrayObject_.unbind();

        // draw indicies
        indexElementArrayBuffer_.draw();
    }

private:

    static void destroyObject(T : GpuReleasableAsset)(ref T obj) @trusted nothrow @nogc {
        if(obj !is null) {
            obj.releaseFromGpu();
            obj = null;
        }
    }

    // vertex attribute index
    enum VertexAttributeIndex : GLuint {
        Position,
        Color
    }

    // FaceTopology to GLenum
    @property GLenum glType() @safe pure nothrow @nogc const {
        final switch(topology_) {
        case FaceTopology.POINTS:
            return GL_POINTS;
        case FaceTopology.LINES:
            return GL_LINES;
        case FaceTopology.TRIANGLES:
            return GL_TRIANGLES;
        }
    }

    uint addVertex(Number x, Number y, Number z) {
        uint result = cast(uint) vertexArray_.length;
        vertexArray_ ~= Vertex([x, y, z]);
        return result;
    }
    void addColor(Number r, Number g, Number b) {
        colorArray_ ~= Color([r, g, b]);
    }
    void addIndex(uint i) {
        indexElementArray_ ~= IndexElement([i]);
    }

    alias VertexArrayBuffer = VertexAttribute!(float, 3);
    alias Vertex = VertexArrayBuffer.Component;
    alias ColorArrayBuffer = VertexAttribute!(float, 3);
    alias Color = ColorArrayBuffer.Component;
    alias IndexElementArrayBuffer = VertexElementArrayBuffer!();
    alias IndexElement = IndexElementArrayBuffer.Component;

    FaceTopology topology_;
    Array!Vertex vertexArray_;
    Array!Color colorArray_;
    Array!IndexElement indexElementArray_;

    VertexArrayBuffer vertexArrayBuffer_;
    ColorArrayBuffer colorArrayBuffer_;
    IndexElementArrayBuffer indexElementArrayBuffer_;
    VertexArrayObject vertexArrayObject_;
}

