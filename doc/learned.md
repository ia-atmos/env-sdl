# What was learned (E7)

The three games ported over SDL2 (Pingus, SNKRX, Flare) each had a
platform layer of their own. Each moved to this environment in its own
repository, by its own session, with its tests identical. This document
records what the three layers had in common, what each game changed,
and what the environment costs. The design is in
[`design.md`](design.md); the layers as they were, in
[`inventory.md`](inventory.md).

## The moves

| | Pingus | SNKRX | Flare |
|---|---|---|---|
| Done | 2026-11-17 | 2026-11-21 | 2026-11-25 (on a branch; its merge waits for the author) |
| Baseline | `cc5fe72` | `ad37d31` | `6e79237` |
| Over | `sdl-pingus` `e9fd322` | `sdl-snkrx` `8d2f653` | `sdl-flare` `f724aae` |
| Tests | 37 checks, 6 golden screenshots, 159 demo traces: identical | 39 of 40 identical; the 40th prints the new names of the events | 38 traces against the original, data dumps, screenshots against the original and of the units: identical |
| C of the layer | `pingus.h` 930 -> 591 | `eng.h` 1470 -> 1281 (its `main` also gained features meanwhile) | `flare.h` 670 -> 373 |
| Atmos of the layer | `sdl.atm` 175 -> 150 | `eng.atm` 267 -> 304 | `engine.atm` 327 -> 415 |

Lines counted at the baseline and at the commit of the move of each
game. What left the layers is the window, the loop, the events, the
time, the test mode, and (Pingus, Flare) the images, the sounds, and
the music. The Atmos side grew in SNKRX and Flare: the calls that their
own `main` made in C became calls of the environment from Atmos.

## What the three had in common

The inventory found it small (24 of 83 functions of SDL in all three),
and it held:

- **The loop and its order**: input, the logic of the frame, the
  drawing, the screenshot, the present. The three had it; it became
  input, `:frame`, the time, `:draw`, which the author then fixed for
  every environment.
- **The test mode**: frames, scripted keys and mouse, screenshots, a
  mute. Four spellings of one idea became `SDL_ATM_*`. Each game kept
  its own traces and seeds.
- **Images by path with a part and an alpha, a fill, keys and mouse as
  events, sounds with a volume, one music.**

## What each game changed

- **Pingus**: the least. Its drawing was already textures with the
  renderer. Its images with 8 modifiers and crops became
  `sdl_new_image` of surfaces it makes itself; its bitmap fonts and
  ground maps stay in its C over the door. It renamed its own
  `:frame` (sprites), which clashed with the event of the environment.
- **SNKRX**: kept its whole drawing (canvases, geometry, the shadow,
  atlas fonts) and its sounds (with pitch) in its C, as the design
  proposed. What it needed was the frame: frames of exactly 1/60 s
  (`fixed=true`), `:frame` before the clock (it sets the factor of the
  clock there), `sdl.clock(f)` with the carry, a second pass of
  drawing (`:overlay`), and a function of flush that knows whether the
  frame is rendered.
- **Flare**: the software path (one ARGB8888 surface, blits, the raw
  format of the images of animations, which changes the pixels of a
  blend), the scancode in the key events (it binds by scancode), and
  its scripted input converted to `SDL_ATM_*`. Its map, fonts and
  input state stay in its C over `sdl_scr()`.

## What the environment gained from them

Each move found something the design did not have, and it was added
here, with a test, not in the game:

| From | What |
|---|---|
| Pingus | a scripted press moves the mouse first; `fps=0` |
| SNKRX | `:frame [n, us]` in microseconds; `fixed=true`; `:frame` before the clock; `passes`; `sdl_on_flush`; `SDL_ATM_RENDER`; `clear=false` |
| Flare | `code` in the key events; `sdl.image(path, raw)`; `sdl_sfc` converted; the mouse scaled in the software path |
| Tux (before its move) | `sdl.draw_ex`; a music that loops between two points |
| The compiler | the numeric options (`ATMOS_CLOCK=ms`); `--test` (`-t`) with no window; the kinds of native values as `char[]` (LTO) |

## What it costs

- **SNKRX** measured its stress scenario at 18.07 s against 16.62 s
  before the move (83 against 90 frames per second); 0.82 s of it was
  the clear of the window before the passes, which `clear=false` now
  skips (its later runs saw a smaller gain, within the spread). The
  rest is not explained (its `doc/bench.md`, "On env-sdl").
- **Pingus** and **Flare** did not report a cost; their runs are of
  fixed frames, which do not measure it.

## What did not fit

- **A common model of drawing**: SNKRX's canvases and geometry fit no
  common interface, as the inventory feared; it keeps them, over the
  door. The door in C (the renderer, the screen surface, the surfaces
  and textures of images) is what let three different drawings stay
  in their games.
- **Fonts**: none of the three uses `sdl.text` as it is. Pingus has
  bitmap fonts, SNKRX an atlas with the metrics of LÖVE, Flare a TTF
  style, Solid or Blended, and a double blit. Each copies the pixels of
  its original.
- **Native values against indices**: the three games used integer
  indices that were never freed; the environment gives native values.
  Each game kept a table of its own as the cache.
