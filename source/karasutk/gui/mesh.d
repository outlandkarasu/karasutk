/**
 *  3D mesh module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mesh;

import karasutk.gui.gpu : GpuAsset;

/// number for mesh coordinate
alias Number = float;

/// Mesh interface
interface AbstractMesh : GpuAsset {

    /// face topology types
    enum FaceTopology {
        POINTS,
        LINES,
        TRIANGLES,
    }

    /// draw to display
    void draw();
}

struct VertexAttributes {
    float[3] position;
    float[3] color;
    float[2] uv;
}

/// Mesh factory interface.
interface AbstractMeshFactory(M) {

    alias Mesh = M;

    /// vertex attirbutes appender function.
    alias AttributesAppender = uint delegate(VertexAttributes);

    /// point appender function.
    alias PointAppender = void delegate(uint);

    /// line appender function.
    alias LineAppender = void delegate(uint, uint);

    /// triangle appender function.
    alias TriangleAppender = void delegate(uint, uint, uint);

    /// add points by user delegate.
    Mesh makePoints(void delegate(AttributesAppender, PointAppender) dg);

    /// add lines by user delegate.
    Mesh makeLines(void delegate(AttributesAppender, LineAppender) dg);

    /// add triangles by user delegate.
    Mesh makeTriangles(void delegate(AttributesAppender, TriangleAppender) dg);
}

import karasutk.gui.sdl.mesh : SdlMeshFactory;
alias MeshFactory = SdlMeshFactory;
alias Mesh = SdlMeshFactory.Mesh;

