/**
 *  gpu assets common module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.gpu;

/// common methods for releaseable GPU assets
interface GpuReleasableAsset {

    /// release data from GPU.
    void releaseFromGpu() @nogc nothrow;
}

/// common methods for GPU assets
interface GpuAsset : GpuReleasableAsset {

    /// transfer data to GPU.
    void transferToGpu();
}

