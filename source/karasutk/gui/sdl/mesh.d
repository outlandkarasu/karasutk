/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.mesh;

import karasutk.gui.mesh;

import std.container : Array;
import derelict.opengl3.gl3;

import karasutk.gui.gpu :
    GpuAsset,
    GpuReleasableAsset;

import karasutk.gui.sdl.gl :
    checkGlError,
    VertexAttribute,
    VertexElementArrayBuffer,
    VertexArrayObject;

class SdlMeshFactory : AbstractMeshFactory!SdlMesh {

    /// add points by user delegate.
    Mesh makePoints(void delegate(AttributesAppender, PointAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.POINTS);
        dg(&mesh.addAttributes, &mesh.addIndex);
        return mesh;
    }

    /// add lines by user delegate.
    Mesh makeLines(void delegate(AttributesAppender, LineAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.LINES);
        void addLine(uint p1, uint p2) {
            mesh.addIndex(p1);
            mesh.addIndex(p2);
        }
        dg(&mesh.addAttributes, &addLine);
        return mesh;
    }

    /// add triangles by user delegate.
    Mesh makeTriangles(void delegate(AttributesAppender, TriangleAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.TRIANGLES);
        void addTriangle(uint p1, uint p2, uint p3) {
            mesh.addIndex(p1);
            mesh.addIndex(p2);
            mesh.addIndex(p3);
        }
        dg(&mesh.addAttributes, &addTriangle);
        return mesh;
    }
}

/// mesh class for SDL
class SdlMesh : AbstractMesh {

    this(FaceTopology topology) {this.topology_ = topology;}

    ~this() @nogc nothrow {
        releaseFromGpu();
        vertexAttributesArray_.clear();
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

        // transfer vertex attributes to a GPU buffer.
        assert(vertexAttributesArrayBuffer_ is null);
        vertexAttributesArrayBuffer_ = new VertexAttributesBuffer(); 
        vertexAttributesArrayBuffer_.transfer((&vertexAttributesArray_[0])[0 .. vertexAttributesArray_.length]);

        // transfer indicies to a GPU buffer.
        assert(indexElementArrayBuffer_ is null);
        indexElementArrayBuffer_ = new IndexElementArrayBuffer(glType); 
        indexElementArrayBuffer_.transfer((&indexElementArray_[0])[0 .. indexElementArray_.length]);
    }

    void releaseFromGpu() nothrow @nogc
    out{
        assert(vertexAttributesArrayBuffer_ is null);
        assert(indexElementArrayBuffer_ is null);
        assert(vertexArrayObject_ is null);
    } body {
        destroyObject(vertexAttributesArrayBuffer_);
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

    uint addAttributes(VertexAttributes attributes) {
        immutable result = vertexAttributesArray_.length;
        vertexAttributesArray_ ~= attributes;
        return cast(uint) result;
    }

    void addIndex(uint i) {indexElementArray_ ~= i;}

    alias VertexAttributesBuffer = VertexAttribute!VertexAttributes;
    alias IndexElementArrayBuffer = VertexElementArrayBuffer!();
    alias IndexElement = IndexElementArrayBuffer.Component;

    FaceTopology topology_;
    Array!VertexAttributes vertexAttributesArray_;
    Array!IndexElement indexElementArray_;

    VertexAttributesBuffer vertexAttributesArrayBuffer_;
    IndexElementArrayBuffer indexElementArrayBuffer_;
    VertexArrayObject vertexArrayObject_;
}

