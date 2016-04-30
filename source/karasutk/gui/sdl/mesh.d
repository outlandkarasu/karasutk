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

import derelict.opengl3.gl3;

import karasutk.gui.gpu : GpuAsset, GpuReleasableAsset;
import karasutk.gui.sdl.gl :
    checkGlError,
    GlType,
    BindableObject,
    BufferData;

private alias ArrayElementOf(T : T[]) = T;

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
class VertexElementArrayBuffer(T)
        : BufferData!(GL_ELEMENT_ARRAY_BUFFER, T) {

    /**
     *  Params:
     *      mode = element mode
     */
    this(GLenum mode) {mode_ = mode;}

    /// draw elements
    void draw() {
        bind();
        scope(exit) unbind();
        glDrawElements(mode_, cast(uint) this.length, GlType!T, null);
        checkGlError();
    }

private:
    GLenum mode_;
}

/// OpenGL vertex array object class
class VertexArrayObject : BindableObject {

    /// default constructor
    this() {
        glGenVertexArrays(1, &id_);
        checkGlError();
    }

    override void bind() {
        glBindVertexArray(id_);
        checkGlError();
    }

    override void unbind() nothrow @nogc {
        glBindVertexArray(0);
    }

    void releaseFromGpu() nothrow @nogc {
        if(id_ != 0) {
            glDeleteVertexArrays(1, &id_);
            id_ = 0;
        }
    }

private:
    GLuint id_;
}

/// FaceTopology to GLenum
GLenum glType(FaceTopology topology) @safe pure nothrow @nogc {
    final switch(topology) {
    case FaceTopology.POINTS:
        return GL_POINTS;
    case FaceTopology.LINES:
        return GL_LINES;
    case FaceTopology.TRIANGLES:
        return GL_TRIANGLES;
    }
}

/// mesh class for SDL
class SdlMesh(V, I) : AbstractMesh {

    this(E, FaceTopology FT)(Vertices!V vertices, IndexBuffer!(E, I, FT) indices) {
        this.topology_ = FT;

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
        indices_ = new GlIndices(topology_.glType); 
        indices_.transfer(indices.fieldSlice);
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

    alias GlVertices = VertexAttribute!V;
    alias GlIndices = VertexElementArrayBuffer!I;

    FaceTopology topology_;
    VertexArrayObject vao_;
    GlVertices vertices_;
    GlIndices indices_;
}

