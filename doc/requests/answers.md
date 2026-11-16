# Answers of the sessions of the games

To the questions sent on 2026-11-16, after the design was approved.
Input for E3 to E6.

## Pingus (`ia-atmos/sdl-pingus`)

1. **Screenshots by pixels: accepted**, and preferred. At the logical
   800x600, RGBA. Besides the 6 golden shots (`tst/shots/`),
   `tst/options.sh` takes 6 more and compares them with each other,
   in one run; `pngcmp` serves there too.
2. **No test depends on the cap of 40 fps.** Every test runs with
   fixed frames of 25 ms. `PINGUS_FPS` and `PINGUS_COUNT` are of the
   benchmark only. One shot (`overlay.png`) shows a counter of frames
   per `await 1s`: it needs exactly one emit of the time of the frame,
   per frame. The variables of the game stay (`PINGUS_TRACE`,
   `_TRACE_ID`, `_ORDERS`, `_HOME`); its scripts pass
   `PINGUS_FRAMES/_KEYS/_MOUSE` through and take the new names.
3. **Baseline: `cc5fe72`**, after its fix of the `spawn` (`d363e63`)
   and its migration to the new rules of `pin`. `engine/engine.atm`
   changed there, so `inventory/pingus.md` (read at `45ea8be`) is out
   of date in `res_desc`, `LANG`, and `Sprite`. All its tests are
   identical; 3 of the 159 demo traces changed by a commit of the
   compiler, and now match the official game.

## SNKRX (`ia-atmos/sdl-snxkx`)

1. **A C callback of the game, once per frame**, after the last
   reaction of the frame and before the screenshot and the present:
   `void (*flush)(int render)`. With `render` 0 (test mode, no
   screenshot in this frame) the game drops its deferred lists; with
   1 it composes its canvases into the renderer. So C must know
   whether the frame is rendered. It also wants a switch to render
   every frame in the test mode (as `SNX_RENDER`, for its benchmark).
2. **`:overlay` is a second pass of drawing**, after `:draw` (texts
   under the mouse, transitions). It prefers that the environment
   emits `:draw` and then `:overlay`, or a list of passes given by
   the program.
3. **Two times per frame.** The real tick, never scaled, before the
   clock: menus and transitions use it while `eng.slow(0)` stops the
   game. Then the clock of Atmos, scaled by the factor, **with the
   remainder carried** to the next frame. `sdl.clock(f)` must keep
   that carry. `:frame` may be its real tick if the time has the
   precision of microseconds.
4. **A fixed frame time set from the program is enough**, if 60
   frames are exactly 1 s: 16666 and 16667 us alternating
   (`us = n*1e6/60 - (n-1)*1e6/60`). It never measures the time.
5. **Baseline: `2bddee7` or later.** Its three `spawn` are fixed.
   Features are still being added on its `main`, and its migration to
   the new rules of `pin` has not started.

## Flare (`ia-atmos/sdl-flare`)

1. **No task awaits a clock**: every timing counts frames. To pass
   the time once per frame does not change its 30 traces, as long as
   the time is not emitted between `:frame` and `:draw`.
2. **It depends on scancodes.** Its bindings are by scancode, as the
   original, and its scripts name keys by the name of the scancode
   (`SDL_GetScancodeFromName`). The name of the key is fine for the
   event, if the environment also gives the scancode.
3. **PNG compared by pixels: accepted.** The BMP bytes are not
   needed; it regenerates its golden from PNG in the commit of the
   move.
4. **The raw image format is needed for the pixels**, and is not an
   optimization. Measured by Flare: with the images of animations
   converted to ARGB8888, 6,000 to 11,000 pixels differ (by 1 to 9
   levels, at semi-transparent edges and shadows); with the format
   that `IMG_Load` gives (ABGR8888 for RGBA PNG), none. The original
   loads animations unconverted and everything else converted.

## What changes in the design

- `:frame` carries the time in microseconds (`us`), not `ms`: the
  nominal frame of SNKRX is not a whole number of milliseconds.
- A fixed rate set from the program: `sdl.window [..., fps=60,
  fixed=true]` gives frames of exactly 1/fps s, with the remainder
  carried. `SDL_ATM_FRAMES=n:ms` stays for whole milliseconds.
- `sdl.clock(f)` scales the clock of Atmos and carries the remainder.
- In the door in C: a function to set the callback that runs after
  the last pass of drawing, with whether the frame is rendered. In
  the test mode, a frame with no screenshot is not rendered, unless
  a variable asks for it.
- The passes of drawing: `:draw` only, by default. A second pass for
  SNKRX is open: a list of tags given by the program, or the game
  emits `:overlay` itself at the end of its own `:draw` (a task
  spawned first, whose loop on `:draw` emits it, cannot be last).
- The key events also carry the scancode: `:key.dn [key=, code=]`,
  with `code` the name of the scancode (`SDL_GetScancodeName`). A
  scripted key gives both from its name.
- `sdl.image(path, raw)`: in the software path, an image is converted
  to the format of the screen, unless `raw` keeps the format of the
  file. It changes the pixels of a blit with alpha, so it is of the
  platform.
- Screenshots: PNG compared by pixels serves the three games. The
  `.bmp` of section 9 of the design is not needed.
