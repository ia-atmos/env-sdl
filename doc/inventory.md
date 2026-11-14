# Inventory of the three layers

What the SDL2 layers of Pingus, SNKRX, and Flare offer, and what each
game uses of them. This document only records: the interface is
designed from it, in `doc/design.md` (E2).

The detail of each layer, with every function, its SDL calls, and its
call sites, is in:

- [`inventory/pingus.md`](inventory/pingus.md) (`ia-atmos/sdl-pingus`)
- [`inventory/snkrx.md`](inventory/snkrx.md) (`ia-atmos/sdl-snxkx`)
- [`inventory/flare.md`](inventory/flare.md) (`ia-atmos/sdl-flare`)

A fourth game, SuperTux (`ia-atmos/sdl-tux`), has no layer: it starts
over this environment. What it asked for is in
[`requests/sdl-tux.md`](requests/sdl-tux.md), and it has a column
below where it matters.

The three were read, not run: the counts come from `grep`. Classes:
**common** (platform, for any game), **one game** (platform, but of
the needs of one game), **game** (logic that stays in the game).

## 1. Size and shape

| | Pingus | SNKRX | Flare |
|---|---|---|---|
| C of the layer | `engine/pingus.h`, 930 | `eng/eng.h`, 1414 | `engine/flare.h`, 670 |
| Atmos over it | `engine/sdl.atm`, 175 (table `pg`, 31 functions); `engine/engine.atm`, 453 (pure Atmos) | `eng/eng.atm`, 248 (table `eng` and globals) | `engine/engine.atm`, 323 (table `fl`, 73 entries) |
| Of the C, game logic | about 300 lines (ground maps, the mover, the minimap) | none (the physics is apart, `phys.h`) | none in `flare.h`; `map.h`, `collision.h`, `geom.h`, `astar.h` are apart (1275 lines) |
| Libraries | SDL2, image, mixer | SDL2, image, ttf, mixer, Box2D | SDL2, image, ttf, mixer |
| `main` | in the layer | in the layer | in the layer |
| Starts from `lib/sdl.atm` | no: a rewrite that kept the shape of its driver | no | no |

None of the three includes `lib/sdl.atm`, and none uses a function of
it as it is. What they kept is the shape: a prelude in C with `main`
and the loop, and a table of thin functions over natives.

Functions of SDL, SDL_image, SDL_ttf, and SDL_mixer called (measured
on the directories of the layers):

| | Functions |
|---|---|
| Pingus | 50 |
| SNKRX | 59 |
| Flare | 44 |
| The three together | 83 |
| In at least two | 46 |
| In all three | 24 |
| In `sdl.atm` today | 31 |

## 2. The window

| | Pingus | SNKRX | Flare | Tux |
|---|---|---|---|---|
| Created | in `main`, before the program | in `main`, before the program | in `main`, before the program | - |
| Size | 800x600 | 480x270 times a scale (`SNX_SCALE`) | 1280x720 | 1280x800 |
| Logical size | set by `pg.display`, later | none: composes at the size of the window | a surface of 1706x960 stretched to the window | wanted |
| Changes while running | fullscreen, size, grab, cursor (`pg.display`) | no | no | no |

- **All three create the window before the main chunk**, with the size
  in C and repeated in Atmos (`W`, `H`). `lib/sdl.atm` creates it from
  the program, with `sdl.window`. *Common: a window with a title and a
  size. One game: fullscreen and grab (Pingus).*

## 3. The events

| | Pingus | SNKRX | Flare | `sdl.atm` today |
|---|---|---|---|---|
| Quit | `:sdl.quit [name=""]` | `:quit` (never awaited) | `:quit` | `:quit` |
| Keys | `:sdl.key.dn/up [name]` | `:key.dn/up` | `:key.dn/up [scancode name]` | `:key.dn/up [name]` |
| Mouse | `:sdl.mouse.motion/dn/up [x,y,but]` | `:mouse.mv/dn/up` | `:mouse.motion [x,y]`, `:mouse.dn/up [x,y,but]` | none |
| Logic, per frame | the time (us) | `:tick [us]`, then the time scaled | `:frame [n]`, `n` from 0; **no time** | the time (us) |
| Draw | `:sdl.draw [name=""]` | `:draw`, then `:overlay` | `:draw` | `:draw` |
| Events as | tagged tables | tagged tables | tagged tables, positional | a bare tag, or a table with `name` |

- **Keys by name, mouse with position and button**: common, with
  three spellings.
- **The key has two names**: the name of the key (Pingus, `sdl.atm`)
  and the name of the scancode (Flare). They differ on other layouts.
- **The frame differs most.** Pingus passes the real time (fixed in
  tests). SNKRX passes a nominal 1/60 s always, never measured, in two
  clocks: `:tick` and the time of Atmos scaled by `eng.slow(f)` (slow
  motion; no time at all when `f` is 0). Flare passes no time: one
  frame is one step of the logic, numbered from 0. Tux wants the real
  elapsed time and steps its own ticks.
- **Polled input, besides events**: `eng.mouse()`, `fl.mouse()`,
  `MOUSE` of Pingus (a table kept by a task), and `fl.pressed(action)`
  of Flare, which is a table of actions and locks kept in C (*one
  game*).
- **Where the games await**: Pingus has 39 loops on the draw event, so
  the order of the layers is the order of the spawns. Flare awaits
  `:frame` in 6 places and `:draw` in 2.

## 4. The loop

| Step | Pingus | SNKRX | Flare |
|---|---|---|---|
| 1 | SDL events | SDL events | reset of the input; SDL events |
| 2 | scripted keys, scripted mouse | scripted input | scripted input |
| 3 | the time, once | `:tick`, then the time | `:frame [n]` |
| 4 | clear, `:sdl.draw` | `:draw`, `:overlay`, render | clear, `:draw` |
| 5 | screenshot, present | screenshot, present | screenshot, present |
| 6 | delay | delay | delay |
| Cap | 40 fps, less the time spent (`PINGUS_FPS`) | 60 Hz | 16 ms (62.5 fps) |
| At the end | `atm_stop`, `atm_quit`, `SDL_Quit` | the same | the same, and `flare: frames N` on stderr |

- **The order is the same in the three**, and it is the order of
  `sdl.atm`: input, scripted input, logic, draw, screenshot, present,
  delay. *Common.*
- **The cap differs** (40, 60, 62.5 fps; `sdl.atm` sleeps a flat
  16 ms). *Common, with a parameter.*
- SNKRX only renders, in the test mode, the frames that have a
  screenshot.

## 5. Images and drawing

| | Pingus | SNKRX | Flare | Tux |
|---|---|---|---|---|
| Path | textures drawn by the renderer; the surface is kept (RGBA32) | triangles (`SDL_RenderGeometry`) into render targets | **software only**: blits onto one ARGB8888 surface, one texture update per frame | renderer |
| Load | `pg.img(path, mod, crop)`: 8 flips and rotations, at load | `image(name)` | `fl.img(path, raw)`: two pixel formats | PNG |
| Draw | whole; a part; scaled; alpha | position, rotation, scale, color | a part, alpha, color, blend | a part, flip, scale, rotation, alpha, color |
| Shapes | fill, rect, line | rect (rounded), circle, ellipse, arc, polygon, polyline, line, gradient; line widths | fill | fill with alpha |
| Transforms | none | a stack of 32: push, pop, rotate, translate | none | none |
| Colors | `0xRRGGBBAA` | a number made by `rgba(r,g,b,a)` in [0,1] | `0xRRGGBBAA` | - |
| Many draws in C | the ground map and the minimap (*game*) | everything is deferred in C | the tiles and the queue of objects (`map.h`, *game*) | the tiles |

- **Common**: load an image once by its path; its size; draw the
  whole, or a part, at a position, with an alpha; a filled rectangle
  with a color and an alpha; a line.
- **Three paths of rendering, and each game depends on its own for
  its pixels.** Pingus: `SDL_RenderCopy` of textures made from
  surfaces. Flare: `SDL_BlitSurface` only. SNKRX: geometry, with a
  tessellation that copies LÖVE, and a composition done by hand in the
  software renderer.
- **SNKRX does not fit the model of the others.** Its canvases are
  render targets of 480x270 with premultiplied content, composed to
  the window in the order of creation; the shadow replays the list of
  the main canvas in gray, displaced by 1.5 game pixels, so the
  composition is at the size of the window. The software path of the
  composition assumes exactly one shadow canvas. *One game*, and the
  largest part of its layer.
- **Games draw from their own C.** Pingus (ground map: the renderer,
  and the RGBA32 surface of an image by its index), Flare (`map.h`
  calls `fl_img_draw` and `fl_fill` with image indices, and reads the
  size of the render), and Tux (asks for the renderer and the texture
  behind an image). Only SNKRX has no C outside its layer.

## 6. Text

| | Pingus | SNKRX | Flare | Tux |
|---|---|---|---|---|
| Fonts | bitmap, from the `.font` files of the game (no SDL_ttf) | TTF, as an atlas of ASCII 32-126 with the metrics of LÖVE | TTF, UTF-8, two qualities | TTF, UTF-8 |
| Draw | at a position, origin left/center/right, alpha | rotation, scale, origin, color | color, justify, blend; blitted twice | with a color |
| Measure | width | width | width, height | width, height |

- **Common**: a font from a file and a size; a text at a position
  with a color; its width and height. `sdl.atm` only centers.
- **One game**: the bitmap fonts of Pingus (glyphs cut from an
  image), the atlas with the metrics of LÖVE of SNKRX, the double
  blit of Flare.

## 7. Sound

| | Pingus | SNKRX | Flare | Tux |
|---|---|---|---|---|
| Sounds | `pg.sound(path, vol)`, cached by path | `sound`, `play(snd, opts)` -> an instance; volume, loop, **pitch** (a resampled copy) | `fl.snd(path)`, `fl.play(snd, vol)` | wav and ogg, with a volume |
| Instances | no | `playing`, `stop`, `set_volume` | no | no |
| Music | `pg.music`, `pg.music_stop` (`Mix_Music`) | as sounds (`Mix_Chunk`, decoded whole) | `fl.music`, `fl.music_stop` (unused) | ogg, a loop between two points, fade out |
| Volumes | `pg.volume(snd, mus)` | per instance, and a table of the game | per play | per play |
| Mute | `PINGUS_MUTE` | `SNX_MUTE` | `FLARE_MUTE` | wanted |

- **Common**: load a sound once, play it with a volume; one music
  that loops, and stops; a general volume; a mute for the tests.
- **One game**: the pitch and the instances of SNKRX (233 of its 237
  plays pass a pitch); the loop points of Tux.
- No game tests its audio: the tests run muted.

## 8. Resources

| | Pingus | SNKRX | Flare | `sdl.atm` |
|---|---|---|---|---|
| A resource is | an integer index, -1 on failure | an integer index, in a tagged table | an integer index, -1 on failure | a native value with a finalizer, `nil` on failure |
| Tables | 4096 images, 16 fonts, 64 sounds | 8 canvases, 16 fonts, 256 images, 256 sounds, 64 channels | 4096 images, 64 fonts, 1024 sounds | 64 sounds |
| Cache | images by `path#mod#crop` | images and sounds by path | images by (path, raw), sounds by path | sounds by path |
| Freed | the music and the ground map | nothing before the end | the music | with the block (`pin`) or the last reference |

- **The three chose indices into static tables**, loaded once and
  never freed, and all three cache by path. None uses a native value.
  It is the opposite of `sdl.atm`, and the largest difference to
  settle in the design.
- An overflow of a table fails in silence (-1, or nothing happens).

## 9. The test mode

| | Pingus | SNKRX | Flare | `sdl.atm` |
|---|---|---|---|---|
| Frames | `PINGUS_FRAMES` | `SNX_FRAMES=n` | `FLARE_FRAMES`, `FLARE_FAST` | `SDL_ATM_FRAMES=n:ms` |
| Keys | `PINGUS_KEYS` | `SNX_INPUT` (keys and mouse, by tick) | `FLARE_INPUT`: a **file** of lines `<frame> move/down/up/key/keyup/quit` | `SDL_ATM_KEYS=f:dn:A,...` |
| Mouse | `PINGUS_MOUSE` | in `SNX_INPUT` | in `FLARE_INPUT` | none |
| Screenshot | `PINGUS_SHOT`, PNG | `SNX_SHOT`, PNG | `FLARE_SHOT=n:file`, one BMP | `SDL_ATM_SHOT=f:x.png,...` |
| Compared by | `cmp` of the file | `cmp` of the file | md5 of the file | pixels (`tools/pngcmp.c`) |
| Mute | `PINGUS_MUTE` | `SNX_MUTE` | `FLARE_MUTE` | `SDL_AUDIODRIVER=dummy` |
| Speed | `PINGUS_FPS` | `SNX_RENDER`, `SNX_PROFILE` | `FLARE_FAST` | fixed frames do not sleep |
| Others of the layer | `PINGUS_COUNT` | `SNX_SCALE`, `_RENDERER`, `_RENDERER_INFO`, `_NO_PREMUL` | `FLARE_SEED`, `FLARE_TRACE` | - |
| Of the game | `PINGUS_TRACE`, `_TRACE_ID`, `_ORDERS` | `SNX_TRACE`, `_SEED`, `_SAVE`, `_STRESS` | - | - |
| Tests | 31 traces, 6 screenshots | 33 tests, 42 screenshots | 9 tests; one replays 30 runs against the original game | 8 |

- **Common**: a number of frames and then the end; keys and mouse
  scripted by frame; screenshots at frames; a mute; no sleep. The
  four modes are the same idea with four spellings.
- **The screenshots are compared as files**, byte for byte, in the
  three games. So they depend on the software renderer and on the
  writer of PNG of SDL_image (or of BMP of SDL), and not only on the
  pixels.
- **What is not platform**: the traces (each game prints its own),
  the seed, the orders. The random generator of Flare is in its layer
  because its C and its Atmos share it; it is *game*.
- The frame of the script counts from 1 in Pingus and `sdl.atm`, and
  from 0 in Flare (fixed by its 30 stored traces).

## 10. What is of a game, inside the layers

It stays in the game, and it needs a way to reach the platform from C:

| Game | What | Needs from the platform, in C |
|---|---|---|
| Pingus | ground and collision maps, the mover in 32-bit floats, the minimap (`pg.map_*`, `pg.move`, `pg.f32`) | the renderer; the RGBA32 surface of an image |
| Pingus | sprites and widgets in Atmos (`engine.atm`) | nothing: over `pg` |
| SNKRX | physics (`phys.h`), animation, colors, steering, tagged text | nothing |
| Flare | tileset, map, camera, queue of objects, collision, path finding, geometry (`fl.tset_*`, `fl.map_*`, `fl.ren`, `fl.cam_*`, `fl.col_*`, ...: 41 of the 73 entries of `fl`) | to draw a part of an image by its handle; a fill; the size of the render |
| Flare | the random generator, the trace | nothing |
| Tux | the tiles | the renderer; the texture of an image |

## 11. What the inventory says to the design

1. **A common part exists and is small**: the window, the loop and
   its order, keys and mouse as events, images by path with a part
   and an alpha, a fill and a line, a font with a text and its size,
   sounds with a volume, one music, the test mode. The three wrote
   it three times, with different names.
2. **A door in C is needed, documented**: three of the four games
   (Pingus, Flare, Tux) draw from C of their own. The environment must give,
   to C, the renderer, and the texture and the surface behind an
   image.
3. **Two paths of drawing, at least**: textures with the renderer
   (Pingus, Tux) and blits onto a surface (Flare). They do not give
   the same pixels, and the games compare files.
4. **SNKRX needs a different model** (deferred geometry, canvases, a
   transform stack, the composition of the shadow). It is the risk
   that the plan named: "a common interface that fits none". The
   choices are to put that model in the environment, as a second
   level, or to leave it in the game over the door in C.
5. **Indices or native values.** The three games use indices that
   are never freed; `sdl.atm` uses native values that are pinned.
6. **The frame**: the real time, a nominal time, or none; one event
   or two; the number of the frame from 0 or from 1. The names of
   the events wait for the author (`TODO.md`).
7. **The window before the program, or from it.**
8. **The test mode moves the scripts of the tests of each game**:
   the variables, a file or a variable for the input, PNG or BMP,
   `cmp` of files or of pixels.
9. **The speed is in the loops in C** of the games (tiles, ground,
   geometry) and in the many small calls of SNKRX per frame (288
   rectangles for its background; a push, a print, and a pop per
   character of a text).
