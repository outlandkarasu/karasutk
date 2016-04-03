/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import std.container : Array;

import derelict.opengl3.gl3;

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
        vertexArrayBuffer_.clear();
        colorArrayBuffer_.clear();
        indexElementArrayBuffer_.clear();
    }

    void transferToGpu() {
        // release old data
        releaseFromGpu();
        scope(failure) releaseFromGpu();

        glGenVertexArrays(1, &vertexArrayId_);
        glBindVertexArray(vertexArrayId_);
        scope(exit) glBindVertexArray(0);

        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        // transfer vertices data
        glGenBuffers(1, &vertexArrayBufferId_);
        glBindBuffer(GL_ARRAY_BUFFER, vertexArrayBufferId_);
        glBufferData(
                GL_ARRAY_BUFFER,
                vertexArrayBuffer_.length * Number.sizeof,
                &vertexArrayBuffer_[0],
                GL_STATIC_DRAW);
        enable(VertexAttribute.Position, vertexArrayBufferId_, 3, GL_FLOAT);

        // transfer vertices color data
        glGenBuffers(1, &colorArrayBufferId_);
        glBindBuffer(GL_ARRAY_BUFFER, colorArrayBufferId_);
        glBufferData(
                GL_ARRAY_BUFFER,
                colorArrayBuffer_.length * Number.sizeof,
                &colorArrayBuffer_[0],
                GL_STATIC_DRAW);
        enable(VertexAttribute.Color, colorArrayBufferId_, 3, GL_FLOAT);

        // transfer indicies data
        glGenBuffers(1, &indexElementArrayBufferId_);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexElementArrayBufferId_);
        scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        glBufferData(
                GL_ELEMENT_ARRAY_BUFFER,
                indexElementArrayBuffer_.length * uint.sizeof,
                &indexElementArrayBuffer_[0],
                GL_STATIC_DRAW);
    }

    void releaseFromGpu() nothrow {
        if(vertexArrayBufferId_) {
            glDeleteBuffers(1, &vertexArrayBufferId_);
            vertexArrayBufferId_ = 0;
        }
        if(colorArrayBufferId_) {
            glDeleteBuffers(1, &colorArrayBufferId_);
            colorArrayBufferId_ = 0;
        }
        if(indexElementArrayBufferId_) {
            glDeleteBuffers(1, &indexElementArrayBufferId_);
            indexElementArrayBufferId_ = 0;
        }
        if(vertexArrayId_) {
            glDeleteVertexArrays(1, &vertexArrayId_);
            vertexArrayId_ = 0;
        }
    }

    void draw() const {
        // bind VAO
        glBindVertexArray(vertexArrayId_);
        scope(exit) glBindVertexArray(0);

        // bind VBO
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexElementArrayBufferId_);
        scope(exit) glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        // draw indicies
        glDrawElements(this.glType, cast(uint) indexElementArrayBuffer_.length, GL_UNSIGNED_INT, null);
    }

private:

    // vertex attribute index
    enum VertexAttribute : GLuint {
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
        immutable result = cast(uint) vertexArrayBuffer_.length / 3;
        vertexArrayBuffer_ ~= x;
        vertexArrayBuffer_ ~= y;
        vertexArrayBuffer_ ~= z;
        return result;
    }
    void addColor(Number r, Number g, Number b) {
        colorArrayBuffer_ ~= r;
        colorArrayBuffer_ ~= g;
        colorArrayBuffer_ ~= b;
    }
    void addIndex(uint i) {indexElementArrayBuffer_ ~= i;}

    void enable(
            VertexAttribute attribute,
            GLuint bufferId,
            GLuint size,
            GLenum type,
            GLuint stride = 0,
            GLuint offset = 0) const {
        glEnableVertexAttribArray(attribute);

        glBindBuffer(GL_ARRAY_BUFFER, bufferId);
        scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);

        glVertexAttribPointer(attribute, size, type, GL_FALSE, stride, cast(const(GLvoid*)) offset);
    }

    FaceTopology topology_;
    Array!Number vertexArrayBuffer_;
    Array!Number colorArrayBuffer_;
    Array!uint indexElementArrayBuffer_;
    GLuint vertexArrayId_;
    GLuint vertexArrayBufferId_;
    GLuint colorArrayBufferId_;
    GLuint indexElementArrayBufferId_;
}

