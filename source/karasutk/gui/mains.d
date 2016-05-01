/**
 *  main functions for GUI application
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mains;

import std.traits : isCallable, isImplicitlyConvertible, Parameters;

import karasutk.gui.context;
import karasutk.gui.event;
import karasutk.gui.window;

/**
 *  GUI option structure.
 */
struct GuiOptions {
    string windowTitle = "karasutk.gui";
    ushort windowHeight = 1024;
    ushort windowWidth = 768;
    ushort windowPositionX = 0;
    ushort windowPositionY = 0;
    bool windowCenterX = true;
    bool windowCenterY = true;
    bool windowShown = true;
    bool windowHidden = false;
    bool windowBorderless = false;
    bool windowResizeable = false;
    bool windowMinimized = false;
    bool windowMaximized = false;
    bool fullScreen = false;
    bool fullScreenDesktop = false;
}

/// GUI application environment.
struct GuiEnvironment {
    Context context;
    Window mainWindow;
    EventQueue eventQueue;
}

/// main function type.
enum isMainFunction(F)
    = isCallable!F
        && isImplicitlyConvertible!(Parameters!(F)[0], GuiEnvironment);

import karasutk.gui.sdl.mains : sdlDoGuiMain;
alias doGuiMain = sdlDoGuiMain;

