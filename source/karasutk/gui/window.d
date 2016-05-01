/**
 *  window module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.window;

/// window class.
abstract class AbstractWindow {

    @property const {
        uint width();
        uint height();
    }

    /// draw next frame
    abstract void drawFrame(void delegate() dg);
}

import karasutk.gui.sdl.window : SdlWindow;
alias Window = SdlWindow;

