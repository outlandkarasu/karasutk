/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import std.container : Array;

import derelict.opengl3.gl3;
import gl3n.linalg : vec3;

import karasutk.gui.gl : checkGlError;

/// number for mesh coordinate
alias Number = float;

/// Mesh interface
interface Mesh {

    /// face topology types
    enum FaceTopology {
        POINTS,
        LINES,
        TRIANGLES,
    }

    /// transfer data to GPU.
    void transferToGpu();

    /// release data from GPU.
    void releaseFromGpu() @nogc nothrow;

    /// draw to display
    void draw() const;
}

/// Mesh factory interface.
interface MeshFactory {

    /// vertices appender function.
    alias void delegate(Number, Number, Number) VertexAppender;

    /// point appender function.
    alias void delegate(uint) PointAppender;

    /// line appender function.
    alias void delegate(uint, uint) LineAppender;

    /// triangle appender function.
    alias void delegate(uint, uint, uint) TriangleAppender;

    /// add points by user delegate.
    Mesh makePoints(void delegate(VertexAppender, PointAppender) dg);
}

package:

class SdlMeshFactory : MeshFactory {

    /// add points by user delegate.
    Mesh makePoints(void delegate(VertexAppender, PointAppender) dg) {
        auto mesh = new SdlMesh(Mesh.FaceTopology.POINTS);
        dg(&mesh.addVertex, &mesh.addIndex);
        return mesh;
    }
}

/// mesh class for SDL
class SdlMesh : Mesh {

    this(FaceTopology topology) {this.topology_ = topology;}

    ~this() @nogc nothrow {
        releaseFromGpu();
        vertexBuffer_.clear();
        vertexArray_.clear();
    }

    void transferToGpu() {
        // release old data
        releaseFromGpu();
        scope(failure) releaseFromGpu();

        // transfer vertices data
        glGenBuffers(1, &vertexBufferId_);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId_);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        glBufferData(
                GL_ARRAY_BUFFER,
                vertexBuffer_.length * vec3.sizeof,
                &vertexBuffer_[0],
                GL_STATIC_DRAW);

        checkGlError();

        // transfer indicies data
        glGenVertexArrays(1, &vertexArrayId_);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vertexArrayId_);
        scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        glBufferData(
                GL_ELEMENT_ARRAY_BUFFER,
                vertexArray_.length * size_t.sizeof,
                &vertexArray_[0],
                GL_STATIC_DRAW);

        checkGlError();

        vertexArraySize_ = cast(uint) vertexArray_.length;
    }

    void releaseFromGpu() nothrow {
        if(vertexBufferId_) {
            glDeleteBuffers(1, &vertexBufferId_);
            vertexBufferId_ = 0;
        }
        if(vertexArrayId_) {
            glDeleteVertexArrays(1, &vertexArrayId_);
            vertexArrayId_ = 0;
        }
        vertexArraySize_ = 0;
    }

    void draw() const {
        // bind and enable vertices
        glBindVertexArray(vertexArrayId_);
        scope(exit) glBindVertexArray(0);

        enable(VertexAttribute.Position, vertexBufferId_, 3, GL_FLOAT);
        scope(exit) glDisableVertexAttribArray(VertexAttribute.Position);

        // draw indicies
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vertexArrayId_);
        scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glDrawElements(this.glType, vertexArraySize_, GL_UNSIGNED_INT, null);
        checkGlError();
    }

private:

    // vertex attribute index
    enum VertexAttribute : GLuint {
        Position
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

    void addVertex(Number x, Number y, Number z) {vertexBuffer_ ~= vec3(x, y, z);}
    void addIndex(uint i) {vertexArray_ ~= i;}

    void enable(
            VertexAttribute attribute,
            GLuint bufferId,
            GLuint size,
            GLenum type,
            GLuint stride = 0,
            GLuint offset = 0) const nothrow @nogc {
        glEnableVertexAttribArray(attribute);
        glBindBuffer(GL_ARRAY_BUFFER, bufferId);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);
        glVertexAttribPointer(attribute, size, type, GL_FALSE, stride, cast(const(GLvoid*)) offset);
    }

    FaceTopology topology_;
    Array!vec3 vertexBuffer_;
    Array!uint vertexArray_;
    uint vertexArraySize_;
    GLuint vertexBufferId_;
    GLuint vertexArrayId_;
}

