/**
 *  generic buffer module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.buffer;

import std.container : Array;

/// generic buffer.
class Buffer(E) {

    alias Element = E;

    /// default constructor.
    this() {}

    /// initialize with capacity.
    this(size_t cap) {array_.reserve(cap);}

    @property pure nothrow @safe @nogc const {
        size_t length() {return array_.length;}
    }

    inout ref inout(E) opIndex(size_t i) {return array_[i];}
    void opIndexAssign(E value, size_t i) {array_[i] = value;}
    void opIndexOpAssign(string op)(E value, size_t i) {
        mixin("array_[i] " ~ op ~ " value");
    }
    void opSliceAssign(E value) {array_[] = value;}
    void opSliceAssign(E value, size_t i, size_t j) {
        array_[i..j] = value;
    }
    void opSliceOpAssign(string op)(E value) {
        mixin("array_[] " ~ op ~ " value");
    }
    void opSliceOpAssign(string op)(E value, size_t i, size_t j) {
        mixin("array_[i..j] " ~ op ~ " value");
    }

    /// reserve memory buffer.
    void reserve(size_t n) {array_.reserve(n);}

    /// return arrayslice
    inout(Element)[] opSlice() inout {
        return (&array_[0])[0 .. array_.length];
    }

    /// append new stuff.
    void opOpAssign(string op, Stuff)(Stuff e) if (op == "~") {
        array_ ~= e;
    }

    /// clear vertices.
    void clear() {array_.clear();}

    int opApply(int delegate(ref Element) dg) {
        int result = 0;
        foreach(ref p; array_) {
            result = dg(p);
            if(result) {
                break;
            }
        }
        return result;
    }

private:
    Array!Element array_;
}

