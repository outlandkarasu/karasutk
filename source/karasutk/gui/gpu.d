/**
 *  gpu assets common module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.gpu;

/// common methods for GPU assets
interface GpuAsset {

    /// transfer data to GPU.
    void transferToGpu();

    /// release data from GPU.
    void releaseFromGpu() @nogc nothrow;
}

