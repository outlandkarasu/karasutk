/**
 *  OpenGL utility module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */ 
module karasutk.gui.gl;

import std.array : join;
import std.algorithm : map;
import std.format : format;
import std.stdio : writefln;

import derelict.opengl3.gl3;

import karasutk.gui.gpu : GpuReleasableAsset;

/// OpenGL related exception.
class GlException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// error check for OpenGL
void checkGlError(string file = __FILE__, size_t line = __LINE__) {
    GLenum[] errors;
    for(GLenum error; (error = glGetError()) != GL_NO_ERROR;) {
        errors ~= error;
    }

    if(errors.length > 0) {
        auto msg = errors.map!(e => format("%02x", e)).join(",");
        throw new GlException(msg, file, line);
    }
}

enum GlType(T : float) = GL_FLOAT;
enum GlType(T : byte) = GL_BYTE;
enum GlType(T : ubyte) = GL_UNSIGNED_BYTE;
enum GlType(T : short) = GL_SHORT;
enum GlType(T : ushort) = GL_UNSIGNED_SHORT;
enum GlType(T : int) = GL_INT;
enum GlType(T : uint) = GL_UNSIGNED_INT;

abstract class BindableObject : GpuReleasableAsset {

    ~this() nothrow @nogc {releaseFromGpu();}
    abstract void bind();
    abstract void unbind() nothrow @nogc;
}

/// OpenGL buffer data class
class BufferData(GLenum Target, T, GLint ComponentSize = 1) : BindableObject {

    struct Component {
    align(1):
        T[ComponentSize] values;
    }

    /// default constructor
    this() {
        glGenBuffers(1, &id_);
        checkGlError();
    }

    /// remove from GPU
    ~this() nothrow @nogc {releaseFromGpu();}

    /// ditto
    void releaseFromGpu() nothrow @nogc {
        if(id_ != 0) {
            glDeleteBuffers(1, &id_);
            id_ = 0;
        }
    }

    /// bind this buffer
    override void bind() {
        glBindBuffer(Target, id_);
        checkGlError();
    }

    /// unbind buffer
    override void unbind() {
        glBindBuffer(Target, 0);
    }

    /// trasfer buffer data to GPU.
    void transfer(Component[] data) {
        bind();
        scope(exit) unbind();

        glBufferData(
            Target,
            data.length * Component.sizeof,
            data.ptr,
            GL_STATIC_DRAW);
        checkGlError();

        length_ = data.length;
    }

    @property size_t length() const @safe pure nothrow @nogc {
        return length_;
    }

private:
    size_t length_;
    GLuint id_;
}

/// OpenGL vertex attribute class
class VertexAttribute(T, GLint ComponentSize)
        : BufferData!(GL_ARRAY_BUFFER, T, ComponentSize) {

    /**
     *  Params:
     *      index = vertex attribute index
     *      normalized = normalized fixed value
     */
    this(GLuint index, bool normalized = false) {
        index_ = index;
        normalized_ = normalized ? GL_TRUE : GL_FALSE;
    }

    /// vertex attribute index
    @property GLuint index() @safe pure nothrow @nogc const {
        return index_;
    }

    /// trasfer buffer and register an attribute pointer.
    override void transfer(Component[] data) {
        super.transfer(data);

        bind();
        scope(exit) unbind();

        glEnableVertexAttribArray(index_);
        glVertexAttribPointer(
            index_,
            ComponentSize,
            GlType!T,
            normalized_,
            0,
            cast(const(GLvoid*)) 0);
        checkGlError();
    }

private:
    GLuint index_;
    GLboolean normalized_;
}

/// OpenGL vertex element array buffer class
class VertexElementArrayBuffer(T = uint)
        : BufferData!(GL_ELEMENT_ARRAY_BUFFER, T, 1) {

    /**
     *  Params:
     *      mode = element mode
     */
    this(GLenum mode) {
        mode_ = mode;
    }

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

    /// remove from GPU
    ~this() nothrow @nogc {releaseFromGpu();}

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

