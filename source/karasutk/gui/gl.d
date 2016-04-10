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

enum GlType(T) = GL_FLOAT;
enum GlType(T : float) = GL_FLOAT;
enum GlType(T : byte) = GL_BYTE;
enum GlType(T : ubyte) = GL_UNSIGNED_BYTE;
enum GlType(T : short) = GL_SHORT;
enum GlType(T : ushort) = GL_UNSIGNED_SHORT;
enum GlType(T : int) = GL_INT;
enum GlType(T : uint) = GL_UNSIGNED_INT;

abstract class BindableObject {

    ~this() nothrow @nogc {release();}
    abstract void bind();
    abstract void unbind() nothrow @nogc;
    abstract void release() nothrow @nogc;
}

/// OpenGL buffer data class
class BufferData(T) : BindableObject {

    /**
     *  Params:
     *      target = buffer binding target
     *      index = vertex attribute index
     *      normalized = normalized fixed value
     */
    this(GLenum target, GLuint index, bool normalized = false) {
        target_ = target;
        index_ = index;
        normalized_ = normalized ? GL_TRUE : GL_FALSE;
        glGenBuffers(1, &id_);
        checkGlError();
    }

    /// ditto
    ~this() nothrow @nogc {
        release();
    }

    /// remove from gpu
    override void release() nothrow @nogc {
        glDeleteBuffers(1, &id_);
        id_ = 0;
    }

    /// bind this buffer
    override void bind() {
        glBindBuffer(target_, id_);
        checkGlError();
    }

    /// unbind buffer
    override void unbind() {
        glBindBuffer(target_, 0);
    }

    /// trasfer buffer data to GPU.
    void transfer(T[] data) {
        bind();
        scope(exit) unbind();

        glBufferData(
            target_,
            data.length * T.sizeof,
            data.ptr,
            GL_STATIC_DRAW);
        checkGlError();

        glVertexAttribPointer(
            index_,
            T.sizeof,
            GlType!T,
            normalized_,
            0,
            cast(const(GLvoid*)) 0);
        checkGlError();
    }

    /// vertex attribute index
    @property GLuint index() @safe pure nothrow @nogc const {
        return index_;
    }

private:
    GLenum target_;
    GLuint id_;
    GLuint index_;
    GLenum type_;
    GLboolean normalized_;
}

/// OpenGL vertex array object class
class VertexArrayObject : BindableObject {

    /// default constructor
    this() {
        glGenVertexArrays(1, &id_);
        checkGlError();
    }

    /// remove from GPU
    ~this() nothrow @nogc {release();}

    override void bind() {
        glBindVertexArray(id_);
        checkGlError();
    }

    override void unbind() nothrow @nogc {
        glBindVertexArray(0);
    }

    override void release() nothrow @nogc {
        glDeleteVertexArrays(1, &id_);
        id_ = 0;
    }

    /// enable vertex attribute.
    void enable(T)(BufferData!T bufferData)
    in {
        assert(bufferData !is null);
    } body {
        glEnableVertexArrayAttrib(id_, bufferData.index);
        checkGlError();
    }

    /// disable vertex attribute.
    void disable(T)(BufferData!T bufferData)
    in {
        assert(bufferData !is null);
    } body {
        glDisableVertexArrayAttrib(id_, bufferData.index);
        checkGlError();
    }

private:
    GLuint id_;
}

