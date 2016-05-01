/**
 *  application context module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.context;

import karasutk.gui.event;
import karasutk.gui.mesh;
import karasutk.gui.texture;

/// GUI context class
abstract class AbstractContext {}

import karasutk.gui.sdl.context : SdlContext;
alias Context = SdlContext;

