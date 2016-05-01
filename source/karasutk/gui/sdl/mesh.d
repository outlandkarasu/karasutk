/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.mesh;

import karasutk.gui.mesh;
import std.traits :
    Fields,
    FieldNameTuple,
    isStaticArray,
    isArray;
import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.gl :
    checkGlError,
    GlType,
    BufferData;
import derelict.opengl3.gl3;

private alias ArrayElementOf(T : T[]) = T;

/// mesh class for SDL
class SdlMesh(V, F) : AbstractMesh!(F) {

    this(SdlContext context, const(Buffer!V) vertices, const(Buffer!F) indices) {
        // create VAO
        assert(vao_ is null);
        vao_ = new VertexArrayObject();

        // use VAO
        vao_.bind();
        scope(exit) vao_.unbind();

        // transfer vertex attributes to a GPU buffer.
        vertices_ = new GlVertices(); 
        vertices_.transfer(vertices[]);

        // transfer indicies to a GPU buffer.
        indices_ = new GlIndices(GL_TOPOLOGY); 
        auto slice = indices[];
        auto ilen = indices.length * Face.sizeof / Index.sizeof;
        indices_.transfer((cast(const(Index)*)slice.ptr)[0 .. ilen]);
    }

    ~this() {
        destroy(indices_);
        destroy(vertices_);
        destroy(vao_);
    }

    void draw() {
        vao_.bind();
        scope(exit) vao_.unbind();
        indices_.draw();
    }

private:

    /// Topology to GLenum
    static if(TOPOLOGY == Topology.POINTS) {
        enum GL_TOPOLOGY = GL_POINTS;
    } else static if(TOPOLOGY == Topology.LINES) {
        enum GL_TOPOLOGY = GL_LINES;
    } else static if(TOPOLOGY == Topology.TRIANGLES) {
        enum GL_TOPOLOGY = GL_TRIANGLES;
    } else {
        static assert(false);
    }

    alias GlVertices = VertexAttribute!V;
    alias GlIndices = VertexElementArrayBuffer!F;

    VertexArrayObject vao_;
    GlVertices vertices_;
    GlIndices indices_;
}

/// OpenGL vertex attribute class
class VertexAttribute(T) : BufferData!(GL_ARRAY_BUFFER, T) {

    static assert(is(T == struct));

    /// trasfer buffer and register an attribute pointer.
    override void transfer(const(Component)[] data) {
        super.transfer(data);

        bind();
        scope(exit) unbind();

        foreach(i, name; FieldNameTuple!Component) {
            alias FieldType = Fields!Component[i];
            static assert(isStaticArray!FieldType || !isArray!FieldType);
            static if(isStaticArray!FieldType) {
                enum ComponentSize = FieldType.length;
                enum AttributeType = GlType!(ArrayElementOf!FieldType);
            } else {
                enum ComponentSize = 1;
                enum AttributeType = GlType!FieldType;
            }

            enum Offset = mixin("T." ~ name ~ ".offsetof");

            glEnableVertexAttribArray(i);
            glVertexAttribPointer(
                i,
                ComponentSize,
                AttributeType,
                GL_FALSE,
                Component.sizeof,
                cast(const(GLvoid*))(0 + Offset));
            checkGlError();
        }
    }
}

/// OpenGL vertex element array buffer class
class VertexElementArrayBuffer(I)
        : BufferData!(GL_ELEMENT_ARRAY_BUFFER, IndexType!I) {

    /**
     *  Params:
     *      mode = element mode
     */
    this(GLenum mode) {mode_ = mode;}

    /// draw elements
    void draw() {
        bind();
        scope(exit) unbind();
        glDrawElements(
                mode_, cast(uint) length, GlType!Component, null);
        checkGlError();
    }

private:
    GLenum mode_;
}

/// OpenGL vertex array object class
class VertexArrayObject {

    /// default constructor
    this() {
        glGenVertexArrays(1, &id_);
        checkGlError();
    }

    ~this() nothrow @nogc {
        if(id_ != 0) {
            glDeleteVertexArrays(1, &id_);
            id_ = 0;
        }
    }

    void bind() {
        glBindVertexArray(id_);
        checkGlError();
    }

    void unbind() nothrow @nogc {
        glBindVertexArray(0);
    }

private:
    GLuint id_;
}

