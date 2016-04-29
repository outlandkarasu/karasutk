/**
 *  OpenGL utility module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */ 
module karasutk.gui.sdl.gl;

import std.array : join;
import std.algorithm : map;
import std.format : format;
import std.stdio : writefln;
import std.traits : Fields, FieldNameTuple, isStaticArray, isArray;

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
class BufferData(GLenum Target, T) : BindableObject {

    alias Component = T;

    /// default constructor
    this() {
        glGenBuffers(1, &id_);
        checkGlError();
    }

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
    void transfer(const(Component)[] data) {
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

alias ArrayElementOf(T : T[]) = T;

/// OpenGL vertex attribute class
class VertexAttribute(T)
        : BufferData!(GL_ARRAY_BUFFER, T) {

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
class VertexElementArrayBuffer(T = uint)
        : BufferData!(GL_ELEMENT_ARRAY_BUFFER, T) {

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

/// 2D texture class
class Texture2d : BindableObject {

    struct Pixel(T) {
        T r;
        T g;
        T b;
    }

    /// default constructor
    this() {
        glGenTextures(1, &id_);
        checkGlError();
    }

    override void bind() {
        glBindTexture(GL_TEXTURE_2D, id_);
        checkGlError();
    }

    override void unbind() nothrow @nogc {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    void releaseFromGpu() nothrow @nogc {
        if(id_ != 0) {
            glDeleteTextures(1, &id_);
            id_ = 0;
        }
    }

    /**
     *  transfer RGB pixel data to GPU.
     *
     *  Params:
     *      width = texture pixel width
     *      height = texture pixel height
     *      pixels = pixel data
     */
    void image(T)(GLsizei width, GLsizei height, const(Pixel!(T))[] pixels)
    in {
        assert(width * height == pixels.length);
    } body {
        bind();
        scope(exit) unbind();

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, pixels.ptr);
        checkGlError();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        checkGlError();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        checkGlError();
    }

private:
    GLuint id_;
}

