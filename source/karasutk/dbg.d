/**
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.dbg;

import std.stdio : writefln;

debug {
    /// debug writefln
    void dwritefln(ARGS...)(string fmt, ARGS args) @safe {
        writefln(fmt, args);
    }
} else {
    /// debug writefln for release module
    void dwritefln(ARGS...)(lazy ARGS args) @safe pure nothrow @nogc {
        // do nothing
    }
}

