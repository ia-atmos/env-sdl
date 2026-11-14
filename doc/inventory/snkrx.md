# Inventory: the platform layer of SNKRX

The SDL2 layer of the port of SNKRX to Atmos, as found in
`/home/user/sdl-snxkx` at commit `f47cf6e` (read-only). This is a
record of what the layer offers and of what the game uses, with no
proposal. Paths are relative to that repository; `eng.h:N` stands for
`eng/eng.h:N`.

How the call sites were counted: `grep` of the call form (`eng.f(`,
or `f(` not preceded by a letter, digit, `_` or `.`), after removing
the comments (`;;` to the end of the line). Three counts are given:
**game** (`main.atm` and `src/*.atm`, 9987 lines), **eng** (the other
files of `eng/`), and **tst** (`tst/**/*.atm`).

## 1. Files, inclusion, and build

| File | Lines | What |
|------|------:|------|
| `eng/eng.h` | 1414 | The C side: driver (`main`), canvases, transforms, shapes, fonts, images, sounds, files, test script |
| `eng/eng.atm` | 248 | The Atmos side: the table `eng`, colors, fonts, images, sounds, trace. Includes `eng.h` in a `:prelude` (`eng.atm:22-24`) |
| `eng/phys.h` | 260 | Box2D v3 behind integer handles (game side, G) |
| `eng/phys.atm` | 174 | The Atmos side of the physics (G) |
| `eng/anim.atm` | 141 | Easings, springs, tweens, real-time waits (G, pure Atmos) |
| `eng/color.atm` | 87 | HSL, color ramps, the palette (G, pure Atmos) |
| `eng/random.atm` | 51 | Random helpers and the seed (G, pure Atmos) |
| `eng/steer.atm` | 155 | Steering behaviors (G, pure Atmos) |
| `eng/text.atm` | 177 | Text with tags, over `print_at` (G, pure Atmos) |

Only `eng/eng.atm` and `eng/phys.atm` have native literals (59 and
44 backquotes; 0 in the other five). No file of `src/` and not
`main.atm` has a native literal: **the game never calls C directly**,
and there is no game-side C other than `phys.h`. The only other
native code is the prelude of the test `tst/box2d.atm`.

Inclusion: `main.atm:4` includes `src/game.atm`, which includes
`../eng/eng.atm` first and then the other six files of `eng/`
(`src/game.atm:4-10`). The tests of the engine include
`../../eng/eng.atm` alone.

`eng.h` defines `main` (`eng.h:1227`), so the layer is an
environment in the sense of the manual ("Environments"): the prelude
replaces the default driver and calls `atm_init`, `atm_main`,
`atm_emit`, `atm_alive`, `atm_stop`, `atm_quit`. There is no
dedicated compiler (`make env`); the plain compiler is used with the
`include`.

Build (`run.sh:12-16`), from the root of the repository:

```
ATMOS_HOME=$ROOT/ext/atmos
ATMOS_CFLAGS="${ATMOS_CFLAGS:--O2} -I$ROOT -I$ROOT/ext/box2d/include"
ATMOS_LDFLAGS="$ROOT/ext/box2d/build/libbox2d.a -lSDL2 -lSDL2_image
               -lSDL2_ttf -lSDL2_mixer -lm"
exec $ROOT/ext/atmos/atmos "$@"        # default: main.atm
```

- `-I$ROOT` is what makes `#include "eng/eng.h"` resolve; the program
  must be compiled from the root (`cd "$ROOT"`).
- The tests use `-O0` instead of `-O2` (`tst/run.sh:19`), and
  `ATMOS_ASAN=1` with `ASAN=1`.
- Setup (`tools/setup.sh`), all under `ext/` (ignored by git; absent
  in this checkout): the compiler `ia-atmos/lang@main` built with
  `make`; Box2D `v3.1.1` compiled file by file into `libbox2d.a`; the
  original `a327ex/SNKRX@6b93a64`, which is the **only source of the
  assets** (`eng.atm:156`: `SNKRX_DIR` or `ext/SNKRX`, then
  `/assets/`). No asset is in the repository (`doc/assets.md`).
- System packages: `libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev
  libsdl2-mixer-dev` (plus `love xvfb xauth` for the comparison with
  the original). SDL 2.30 is installed here. The layer needs
  `SDL_RenderGeometry` (SDL >= 2.0.18) and `TTF_RenderGlyph32_Blended`
  / `TTF_GlyphMetrics32` (SDL_ttf >= 2.0.18).

## 2. Functions

Classes: **P-common** platform, plausibly needed by any game;
**P-game** platform, but specific to this game; **G** game logic.
"Call sites" is game / eng / tst, with one example.

Conventions of the interface, valid for every row:

- Colors are integers `0xRRGGBBAA`; a color that is not a number is
  opaque white (`eg_color`, `eng.h:67`).
- An argument that is not a number is 0 (`eg_dbl`, `eg_int`,
  `eng.h:47-53`); there is no error for a wrong type.
- Coordinates are game pixels (480x270), floats, in the current
  transform. Angles are radians.
- A shape is filled, or stroked with width `lw` when `lw > 0`.
- Nothing draws at once: every call appends triangles to the list of
  the current canvas (section 7).

### 2.1 The table `eng` (`eng.atm:29-130`)

| Name | Signature | Purpose | C behind (`eng.h`) | SDL calls | Call sites | Class |
|------|-----------|---------|--------------------|-----------|------------|-------|
| `eng.canvas` | `(screen, shadow) -> id` (-1 if 8 exist) | Creates a 480x270 canvas; `screen`: composed to the window; `shadow`: with a shadow under it | `eg_canvas_new` :172 | `SDL_CreateTexture` (RGBA8888, TARGET; and RGBA32 STREAMING without premultiplied blending), `SDL_ComposeCustomBlendMode`, `SDL_SetTextureBlendMode`, `SDL_SetTextureAlphaMod` | 3 / 0 / 4, `src/shared.atm:9` | P-game |
| `eng.target` | `(id)` | Selects the canvas that receives the next shapes (global) | `eg_canvas_set` :207 | none | 5 / 0 / 4, `src/shared.atm:13` | P-game |
| `eng.canvas_draw` | `(id, x, y, color)` | Draws an earlier canvas into the current one | `eg_canvas_draw` :443 | none (vertices; `SDL_RenderGeometry` at the end of the frame) | **unused** 0 / 0 / 0 | P-game |
| `eng.canvas_draw_outside` | `(id, x1, y1, x2, y2, color)` | The same, except inside a rectangle (8 quads around a hole; LÖVE's inverted stencil mask) | `eg_canvas_draw_outside` :458 | none (vertices) | 1 / 0 / 0, `src/arena.atm:122` | P-game |
| `eng.background` | `(color)` | The color under all the canvases | global `EG_BG` :170 | none (`SDL_SetRenderDrawColor`+`SDL_RenderClear` in `eg_frame`) | 1 / 0 / 3, `src/shared.atm:12` | P-common |
| `eng.push` | `(x, y, r, sx, sy)`; `sx` defaults to 1, `sy` to `sx` | Pushes a transform: scale and rotation around (x,y), as LÖVE's `graphics.push` of the original | `eg_push` :110 | none | 46 / 1 / 1, `src/attack.atm:243` | P-common |
| `eng.pop` | `()` | Pops the transform | `eg_pop` :121 | none | 46 / 1 / 1, `src/arena.atm:121` | P-common |
| `eng.rotate` | `(r)` | Rotates the top transform | `eg_rotate` :103 | none | 1 / 0 / 0, `src/fx.atm:86` | P-common |
| `eng.translate` | `(x, y)` | Translates the top transform | `eg_translate` :93 | none | 2 / 0 / 0, `src/fx.atm:85` | P-common |
| `eng.rect` | `(x, y, w, h, rx, ry, color, lw)` | Rectangle centered at (x,y), rounded corners (rx,ry) | `eg_rect` :558 | none (vertices) | 45 / 0 / 4, `src/attack.atm:270` | P-common (rounding as LÖVE: P-game) |
| `eng.rect2` | same, (x,y) top-left | Rectangle from its top-left corner | `eg_rect` :558 | none | 2 / 0 / 1, `src/level.atm:225` | P-common |
| `eng.circle` | `(x, y, r, color, lw)` | Circle | `eg_ellipse` :588 | none | 15 / 0 / 2, `src/attack.atm:244` | P-common |
| `eng.ellipse` | `(x, y, rx, ry, color, lw)` | Ellipse | `eg_ellipse` :588 | none | **unused** 0 / 0 / 0 | P-common |
| `eng.arc` | `(type, x, y, r, r1, r2, color, lw)`; type `:pie`, `:open`, `:closed` | Arc | `eg_arc` :599 | none | 2 / 0 / 2, `src/attack.atm:248` (both `:open`) | P-common |
| `eng.polygon` | `(pts, color, lw)`; `pts` = `[x1,y1,x2,y2,...]`, convex, <= 1024 points | Polygon (a fan) | `eg_polygon` :635, `eg_pts` :616 | none | 1 / 0 / 1, `src/arena.atm:61` | P-common |
| `eng.triangle_equilateral` | `(x, y, w, color, lw)` | Equilateral triangle pointing right (computed in Atmos, then `eg_polygon`) | `eg_polygon` | none | 1 / 0 / 0, `src/summons.atm:551` | G |
| `eng.polyline` | `(pts, color, lw)`; `lw` defaults to 1 | Open line through points, miter joins | `eg_polyline` :644, `eg_stroke` :505 | none | 5 / 0 / 1, `src/attack.atm:781` | P-common |
| `eng.line` | `(x1, y1, x2, y2, color, lw)` | Segment | `eg_line` :648 | none | 7 / 0 / 1, `src/level.atm:228` | P-common |
| `eng.gradient` | `(x, y, w, h, c1, c2)` | Rectangle with a vertical gradient (a color per vertex) | `eg_gradient` :656 | none | 1 / 0 / 1, `src/shared.atm:30` | P-common |
| `eng.slow` | `(f)` | The game time runs at `f` times the real time (0 stops it) | global `EG_SLOW` :42 | none | 7 / 0 / 2, `main.atm:75` | P-game |
| `eng.mouse` | `() -> x, y` | The last position of the mouse, in game pixels | globals `EG_MX`, `EG_MY` :41 | none (set from the events) | 8 / 0 / 0, `src/button.atm:29` | P-common |
| `eng.tick` | `() -> n` | The number of the current tick (from 1; 0 before the loop) | global `EG_TICK` :40 | none | 6 / 1 / 28, `src/input.atm:16` | P-common |
| `eng.testing` | `() -> bool` | Test mode (`SNX_FRAMES` is set) | global `EG_TEST` :39 | none | 0 / 1 / 0, `eng/random.atm:5` | P-common |
| `eng.read_file` | `(path) -> string or nil` | A whole file | `eg_read_file` :1119 | none (stdio) | 1 / 0 / 0, `src/save.atm:30` | P-common (not SDL) |
| `eng.write_file` | `(path, s) -> bool` | Writes a string, creating the directories (`mkdir` 0755, POSIX) | `eg_write_file` :1136 | none (stdio, `sys/stat.h`) | 1 / 0 / 0, `src/save.atm:24` | P-common (not SDL) |

### 2.2 Globals of `eng.atm` outside the table

| Name | Signature | Purpose | C behind (`eng.h`) | SDL calls | Call sites | Class |
|------|-----------|---------|--------------------|-----------|------------|-------|
| `W`, `H` | constants 480, 270 (`eng.atm:26-27`; `EG_W`, `EG_H` in `eng.h:32-33`) | The size of the game | none | none | 100 and 107 / 0 / 1, `src/arena.atm:13` | P-game (the value), P-common (the notion) |
| `rgba` | `(r, g, b, a) -> color`, components in [0,1], `a` defaults to 1 | Packs a color | pure Atmos | none | 5 / 5 / 4, `src/elite.atm:216` | G (encodes the color format of the interface) |
| `hex` | `("#rrggbb") -> color` | Packs an opaque color | pure Atmos | none | 0 / 11 / 21, `eng/color.atm:74` | G |
| `comps` | `(color) -> r, g, b, a` in [0,1] | Unpacks a color | pure Atmos | none | 4 / 1 / 0, `src/elite.atm:211` | G |
| `ASSETS` | string | The directory of the assets | pure Atmos (`os.getenv`) | none | 0 / 0 / 0 (used by `font`, `image`, `sound`) | G |
| `font` | `(name, size) -> :Font [i, h]`; asserts | Loads `fonts/<name>.ttf` at a size, as an atlas | `eg_font_new` :720, `eg_glyph` :688, `EG_FNTS[i].h` | `TTF_OpenFont`, `TTF_FontLineSkip`, `TTF_FontAscent`, `TTF_GlyphMetrics32`, `TTF_RenderGlyph32_Blended`, `SDL_ConvertSurfaceFormat`, `SDL_CreateRGBSurfaceWithFormat`, `SDL_SetSurfaceBlendMode`, `SDL_BlitSurface`, `SDL_FillRect`, `SDL_MapRGBA`, `SDL_CreateTextureFromSurface`, `SDL_SetTextureBlendMode`, `SDL_FreeSurface`, `TTF_CloseFont` | 2 / 0 / 4, `src/shared.atm:15` | P-common (the path convention: G) |
| `text_width` | `(font, s) -> pixels` | Sum of the advances (ASCII 32-126, no kerning) | `eg_text_width` :778 | none | 3 / 2 / 2, `src/button.atm:13` | P-common |
| `print_at` | `(font, s, x, y, r, sx, sy, ox, oy, color)` | Text as `love.graphics.print`: origin (ox,oy), rotation, scale | `eg_print` :791 | none (vertices) | 1 / 1 / 1, `src/level.atm:203`; the one of `eng/text.atm:146` draws every character of every tagged text | P-common |
| `print_centered` | `(font, s, x, y, r, sx, sy, color)` | Text centered at (x,y) (`print_at` with `ox = width/2`, `oy = h/2`) | pure Atmos | none | 5 / 0 / 2, `src/level.atm:188` | P-common |
| `image` | `(name) -> :Image [i, w, h]`; asserts | Loads `images/<name>.png` once | `eg_img` :847, `eg_img_dim` :872 | `IMG_LoadTexture`, `SDL_SetTextureBlendMode`, `SDL_QueryTexture` | 3 / 0 / 1, `src/shared.atm:37` (the other two load all the icons in loops: `src/passives.atm:40`, `src/shop.atm:20`) | P-common (the path convention: G) |
| `draw_image` | `(img, x, y, r, sx, sy, color)` | The whole image centered at (x,y), rotated, scaled, modulated by a color. No source rectangle, no flip | `eg_img_draw` :877 | none (vertices) | 4 / 0 / 1, `src/choose.atm:16` | P-common |
| `VOLUME` | table `[sfx=0.5, music=0.5]` | Volume per kind of sound; multiplied in `play`; changed by the options | pure Atmos | none | 11 / 0 / 1, `main.atm:42` | G |
| `sound` | `(file, tag) -> :Sound [i, kind]`; `tag` `:sfx` (default) or `:music`; asserts | Loads `sounds/<file>` once, decoded whole | `eg_snd` :940 | `Mix_LoadWAV` | 106 / 0 / 1, all in `src/sounds.atm` (`:4`) | P-common |
| `play` | `(snd, opts) -> inst` (-1 with no audio); `opts.volume` (1), `opts.pitch` (1), `opts.loop` | Plays an instance in a free channel | `eg_snd_play` :994, `eg_resample` :967, `eg_snd_gc` :927 | `Mix_QuerySpec`, `Mix_PlayChannel`, `Mix_Volume`, `Mix_Playing`, `SDL_malloc`, `SDL_free` | 237 / 0 / 4, `src/attack.atm:185`; 233 lines of the game give `pitch=`; none gives `loop=` | P-common (the pitch: P-game) |
| `playing` | `(inst) -> bool` | The instance still plays | `eg_snd_playing` :1036 | `Mix_Playing` | 1 / 0 / 9, `main.atm:43` | P-common |
| `stop` | `(inst)` | Stops the instance | `eg_snd_stop` :1041 | `Mix_HaltChannel` | 1 / 0 / 3, `main.atm:47` | P-common |
| `set_volume` | `(inst, v)`, `v` in [0,1] (not multiplied by `VOLUME`) | The volume of an instance that plays | `eg_snd_volume` :1048 | `Mix_Volume` | 1 / 0 / 0, `main.atm:42` | P-common |
| `sound_len` | `(snd) -> seconds` | The length of a sound | `eg_snd_len` :1056 | `Mix_QuerySpec` | **unused by the game** 0 / 0 / 1, `tst/eng/sound.atm:8` | P-common |
| `TRACE` | bool (`SNX_TRACE` is set) | Whether `trace` prints | pure Atmos | none | 0 / 0 / 0 (used by `trace`) | G |
| `trace` | `(ev, details)` | Prints `tick<TAB>ev<TAB>details` to stdout when `TRACE` | pure Atmos (`eng.tick`) | none | 26 / 0 / 0, `main.atm:66` | G |

### 2.3 C reached from native literals without a wrapper

All in `eng.atm`; none in the game.

- Globals written or read directly: `EG_BG` (`eng.atm:48`),
  `EG_SLOW` (`:109`), `EG_MX`, `EG_MY` (`:114`), `EG_TICK` (`:117`),
  `EG_TEST` (`:120`), `EG_FNTS[i].h` (`:163`).
- Conversion helpers: `eg_int`, `eg_dbl`, `eg_cstr`, `eg_color`.
- Runtime API used by `eng.h`: `a_isnum`, `a_dbl`, `a_int`, `a_num`,
  `a_nil`, `a_strz`, `a_tab`, `a_tag`, `a_setindex`, `a_tab_get`,
  `A_TAB_OF`, `A_STR_OF`, `a_dec`, `a_truthy` (in `eng.atm`),
  `atm_init`, `atm_main`, `atm_emit`, `atm_alive`, `atm_stop`,
  `atm_quit`, `a_escape_err`, `a_error_dump`. Not used: `a_nat`
  (no native box), `atm_emit_to`.

### 2.4 The physics, briefly (all G)

`eng/phys.atm` over `eng/phys.h` (Box2D v3, no SDL): `phys_world`,
`phys_world_free`, `phys_disable`, `phys_trigger`, `body`,
`body_free`, `body_pos`, `body_vel`, `body_angle`, `body_mass`,
`body_set`, `body_restitution`, `body_friction`, `phys_step`,
`tagged`; in C `pw_world`, `pw_world_free`, `pw_ok`, `pw_body`,
`pw_body_free`, `pw_of_shape`, `pw_def`, `pw_circle`, `pw_rect`,
`pw_polygon`, `pw_shapes`, `pw_get`, `pw_set`, `pw_ev`, `pw_step`.
Bodies are integer handles into static arrays of 4096; one world,
global. It shares nothing with `eng.h` (no renderer, no time): the
game steps it from `:clock` (`src/arena.atm:200`). It needs only
`-I ext/box2d/include` and `libbox2d.a` in the flags.

The other files of `eng/` (anim, color, random, steer, text) are pure
Atmos and G. They depend on the layer through `:tick [us]`
(`eng/anim.atm:111,125,137`), `:clock`, `eng.tick`, `eng.testing`,
`eng.push`/`eng.pop`, `print_at`, `text_width`, `rgba`, `hex`,
`comps`.

## 3. Events

All are emitted globally with `atm_emit` from `main` (`eng.h`),
through `eg_emit` (`eng.h:1079`). **Every tagged event is a table**
with the tag, even with no field (`:quit`, `:draw`, `:overlay` are
empty tagged tables, not bare tags as in `lib/sdl.atm`). Tags have no
prefix (`:key.dn`, not `:sdl.key.dn`). The tests await the parents
`:mouse` and `:key` (`tst/eng/input.atm:7,12`); the game does not.

| Event | Payload | When in the frame | Awaited by the game |
|-------|---------|-------------------|---------------------|
| `:quit` | none | Step 1, on `SDL_QUIT` (`eng.h:1291`); the loop ends after this frame | **never** (0). The `:quit` of `main.atm:69` and `src/menu.atm:76` is a value returned by a screen, not this event |
| `:key.dn` | `name`: `SDL_GetKeyName` of the keysym (`'A'`, `'Left'`, `'Escape'`, `'1'`); or the text after `dn:` in `SNX_INPUT` | Step 1; key repeats are dropped (`eng.h:1296`) | 7 awaits (`src/input.atm:37`, `src/menu.atm:64`, `src/options.atm:92,142`, `src/level.atm:420`, `src/choose.atm:43`, `src/shop.atm:784`) |
| `:key.up` | `name` | Step 1 | 1 (`src/input.atm:42`) |
| `:mouse.mv` | `x`, `y` (floats, game pixels = window pixels / scale), `but` = 0 | Step 1; from SDL only outside the test mode (`eng.h:1304`); from `SNX_INPUT` in step 2 | 16 (`src/button.atm:37`; 12 in `src/shop.atm`) |
| `:mouse.dn` | `x`, `y`, `but` (SDL: 1 left, 2 middle, 3 right) | as `:mouse.mv` | 9 (`src/button.atm:51`, `src/input.atm:47`) |
| `:mouse.up` | `x`, `y`, `but` | as `:mouse.mv` | 1 (`src/input.atm:52`) |
| `:tick` | `us`: the real time of the tick, an integer, 16666 or 16667 | Step 3, once per frame, always | 5 in the game (`main.atm:41`, `src/fx.atm:57`, `src/level.atm:293`), 3 in `eng/anim.atm` (`TweenReal`, `UISprings`, `WaitReal`) |
| (time) | a plain integer, microseconds of game time | Step 4, once per frame, **only if >= 1 us** (not emitted while `eng.slow(0)`) | `:clock`: 41 in the game (`src/arena.atm:192`), 3 in `eng/` (`eng/anim.atm:64,85`); durations (`await 8s`, `await 50ms`): 99 in the game (`src/arena.atm:85`) |
| `:draw` | none | Step 5, once per frame, always (also when the frame is not rendered) | 53 `loop on :draw` (`src/arena.atm:60`) |
| `:overlay` | none | Step 6, right after all of `:draw` | 2 (`src/info.atm:54`, `src/shared.atm:116`) |

Not emitted: mouse wheel, text input, window events (resize, focus),
controllers, touch.

The position of the mouse is also kept in `EG_MX`/`EG_MY` at each
mouse event (`eg_mouse`, `eng.h:1108`), and a scripted `dn:m1` uses
the kept position.

`:overlay` exists because the order of drawing is the order of the
tasks that await `:draw`: what must be over everything (texts under
the mouse, the transition between screens) awaits a second event.

## 4. The main loop

`main` (`eng.h:1227-1414`).

Start, in order: `SDL_Init(VIDEO|AUDIO)` (video alone if it fails);
`TTF_Init`; `Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)`
unless `SNX_MUTE`, then `Mix_AllocateChannels(64)` and
`Mix_ChannelFinished`; the variables of the environment; the hint
`SDL_HINT_RENDER_SCALE_QUALITY=0` (nearest); the window `"SNKRX"`,
centered, 480*scale x 270*scale, flags 0; the hint
`SDL_HINT_RENDER_DRIVER` (if any); `SDL_CreateRenderer(win, -1, 0)`
(no vsync flag); `SDL_SetRenderDrawBlendMode(BLEND)`; the pixel
offsets by the name of the renderer (section 7). Then `atm_init` and
`atm_main`: **the window and the renderer exist before the main chunk
runs**, so the program creates canvases, fonts, images, and sounds at
its top level (`src/shared.atm:9-16`). There is no `IMG_Init`.

A frame is a tick; `tick` counts from 1. The loop runs while
`st==A_OK && !quit && atm_alive()`:

1. **Input**: `SDL_PollEvent` until empty, each event emitted as it is
   read (`:quit`, `:key.dn`, `:key.up`, `:mouse.*`) (`eng.h:1289`).
2. **Scripted input**: the entries of `SNX_INPUT` of this tick
   (`eng.h:1320`).
3. **Real time**: `:tick [us]`, with
   `us = tick*1000000/60 - (tick-1)*1000000/60` in integers
   (`eng.h:1324`): 16666 or 16667, so that 60 ticks are exactly 1 s.
4. **Game time**: `EG_GAME += us * EG_SLOW` (a double, in us); its
   integer part, if > 0, is emitted as a number (`atm_emit(a_int(g))`)
   and the fraction is kept (`eng.h:1330-1335`). This is what
   `await 1s` and `:clock` follow.
5. **Draw**: `:draw` (`eng.h:1341`).
6. **Overlay**: `:overlay` (`eng.h:1345`).
7. **Render and present**: `eg_frame()` (renders the lists into the
   canvases and composes them to the window), then the screenshots of
   `SNX_SHOT` for this tick, then `SDL_RenderPresent`
   (`eng.h:1350-1353`). In the test mode this happens only in the
   ticks that have a screenshot, unless `SNX_RENDER`; otherwise the
   lists are just emptied (`eng.h:1355-1359`).
8. **Delay**: if `SNX_FRAMES` is reached, quit; else, outside the
   test mode, `next += period` (`period` = performance frequency / 60)
   and `SDL_Delay` of the rest in ms; if the frame is late,
   `next = now` (no catching up) (`eng.h:1367-1377`).

Time:

- **dt is fixed, always**: the time emitted is the nominal 1/60 s, in
  integer microseconds, in the test mode and in the normal mode. The
  clock of the machine only paces the loop; it is never measured into
  the game. A slow machine slows the game down; it does not skip.
- Two clocks: the real one as the event `:tick [us]`, and the game
  one as the time of Atmos, scaled by `eng.slow(f)`. The reason is in
  `doc/compiler.md`, 1: time in Atmos is global, and the original
  slows down a part of the game while the interface keeps moving.
- Frame cap: 60 Hz by `SDL_Delay` (granularity 1 ms, truncated); no
  vsync; no cap at all in the test mode.
- The logic step and the frame are the same thing (one emit of time
  per frame); there is no accumulator.

Quit:

- `SDL_QUIT` emits `:quit` and sets `quit`; the rest of that frame
  still runs (tick, time, draw, render), then the loop ends.
- The loop also ends when the program ends (`atm_alive()` false) or
  when an emit returns a status other than `A_OK` (every step is
  guarded by `st == A_OK`).
- The button "quit" of the game leads to a `break` of the loop of
  screens (`main.atm:69-70`). How the program then terminates was
  not verified here; `doc/compiler.md`, 5 reports a hang related to
  ending inside an emit.

Shutdown, in order (`eng.h:1380-1413`):

1. The profile to stderr, with `SNX_PROFILE`.
2. `atm_stop()` if the status is `A_OK`.
3. `fflush(stdout)`.
4. `A_ESCAPE` becomes `a_escape_err()`; a status other than `A_OK`
   prints with `a_error_dump()`.
5. `atm_quit()`.
6. With audio: `Mix_HaltChannel(-1)`, `Mix_CloseAudio()`, the
   resampled copies freed, then `Mix_FreeChunk` of every sound
   (after the device is closed).
7. `TTF_Quit()`, `SDL_Quit()`.
8. The exit code is 0 for `A_OK`, else 1.

Never destroyed explicitly: the textures (canvases, shadow, atlases
of the fonts, images, the streaming textures), the renderer, the
window, the pixel buffers of the CPU composition, and the `strdup`ed
paths. There is no `Mix_Quit` or `IMG_Quit`.

## 5. Test mode

Variables read by the layer (C, `getenv`):

| Variable | Format | Meaning | Where |
|----------|--------|---------|-------|
| `SNX_FRAMES` | `n` | Test mode: `EG_TEST=1`, runs `n` ticks with no frame cap and quits; mouse events of SDL are ignored (keys of SDL are not); the renderer is `software` by default; a frame is rendered only if it has a screenshot. `n <= 0` gives the test mode with no end | `eng.h:1239`, `1304`, `1254`, `1350`, `1367` |
| `SNX_INPUT` | `f:mv:x:y`, `f:dn:k`, `f:up:k`, separated by commas | At tick `f`: moves the mouse to (x,y) in game pixels (floats); presses or releases `k`, a key name of SDL (`Left`, `Escape`, `A`) emitted as given, or `m1`, `m2`, `m3` for a mouse button at the kept position. Works outside the test mode too. An item is at most 255 characters | `eg_script`, `eng.h:1160` |
| `SNX_SHOT` | `f:path.png`, separated by commas | Saves the window at tick `f`. In the test mode it also makes that tick be rendered | `eg_script`, `eg_shot_due` `eng.h:1193`, `eg_shot` `eng.h:1098` |
| `SNX_MUTE` | set (any value, even empty) | No audio device: sounds "load" (the path is recorded, no file is opened) and `play` returns -1 | `eng.h:1232` |
| `SNX_SCALE` | `n > 0` | Window pixels per game pixel (default 2) | `eng.h:1244` |
| `SNX_RENDER` | set | In the test mode, renders and presents every frame | `eng.h:1243` |
| `SNX_PROFILE` | set | At the end, prints to stderr the ticks and the seconds in logic (steps 1-4), draw (5-6), render (7), and inside the render: canvases, unpremultiply/copy, compose, blend | `eng.h:1380` |
| `SNX_RENDERER` | a render driver of SDL (`software`, `opengl`) | Overrides the driver (default: `software` in the test mode, the best one otherwise) | `eng.h:1252` |
| `SNX_RENDERER_INFO` | set | Prints the name of the renderer to stderr | `eng.h:1274` |
| `SNX_NO_PREMUL` | set | Forces the path without the premultiplied blend mode (the CPU composition) on any renderer | `eng.h:185` |

Read by Atmos code (`os.getenv`):

| Variable | Meaning | Where | Class |
|----------|---------|-------|-------|
| `SNKRX_DIR` | The checkout of the original (default `ext/SNKRX`) | `eng.atm:156` | G |
| `SNX_TRACE` | `trace()` prints | `eng.atm:242` | G |
| `SNX_SEED` | The seed; default 1 in the test mode, `os.time()` otherwise | `eng/random.atm:4` | G |
| `SNX_SAVE` | The directory of the save; default none in the test mode (reads `SNX_FRAMES` itself), else `$HOME/.local/share/sdl-snkrx` | `src/save.atm:19-20` | G |
| `SNX_STRESS` | A crowd of enemies, for the benchmark | `src/unit.atm:130` | G |

Set by the runner, for SDL itself: `SDL_VIDEODRIVER=dummy`,
`SDL_AUDIODRIVER=dummy` (`tst/run.sh:21`). The benchmark uses
`SDL_VIDEODRIVER=x11` under Xvfb, `SNX_RENDERER=opengl`,
`SNX_RENDER=1`, `SDL_AUDIODRIVER=disk` (`tools/bench/perf.py:54-57`).

Scripted input: yes, keys **and mouse**, by tick, through `SNX_INPUT`
(above). It is injected after the real events of SDL and before
`:tick`. `tst/original/run1.sh` holds the same script for the
original (`SNKRX_INPUT`, read by `tools/bench/bench.lua`), so the
format is shared with the reference.

Screenshots (`eg_shot`): after `eg_frame` and before
`SDL_RenderPresent`, the window (render target NULL) is read with
`SDL_RenderReadPixels` in `SDL_PIXELFORMAT_RGBA32` at the output size
of the renderer, and saved with `IMG_SavePNG`. The stored ones are
960x540, 8-bit RGBA (scale 2). They are compared **byte by byte**
(`cmp -s`, `tst/run.sh:60`): the PNG file itself must be identical,
which is why the test mode renders in software.

A trace: with `SNX_TRACE=1`, the game prints lines
`tick<TAB>event<TAB>details` to stdout at chosen points (26 calls of
`trace`: screen changes `go`, `wave`, `add`, `enemy.die`, `unit.hit`,
...), in the format of the trace of the original
(`tools/bench/bench.lua`). The trace is simply the standard output
of the test, so it is compared as any output. `tools/compare.py`
aligns a trace of the port with one of the original
(`tst/original/run1.txt`) and lists the ticks side by side; it is a
tool, not part of the runner.

The runner (`tst/run.sh`): for each `tst/*.atm` and `tst/*/*.atm`,
from the root: sources `X.sh` if any with `set -a` (the variables of
the test; `$OUT` is `build/tst`), runs the compiler on the test with
`timeout` (default 600 s), stdout and stderr together into
`build/tst/<name>.got`, appends `(exit N)` on failure; compares with
`diff -u X.out`, and each `build/tst/<name>.png` and
`<name>.*.png` with `tst/shots/` by `cmp`. `tst/run.sh update`
stores the new results (refused if the output has `==> ERROR`). A
test with `SNX_MUTE=` (empty) in its `.sh` runs with audio on the
dummy driver (`tst/run.sh:39`, `tst/eng/sound.sh`).

Numbers: **33 tests** (1 `tst/box2d.atm`, 10 in `tst/eng`, 22 in
`tst/game`), 31 with a `.sh`, 42 stored screenshots, 16 tests with a
trace, 9 with scripted input, 21 with screenshots. 31 set
`SNX_FRAMES`.

## 6. Resources

No resource is a native box (`a_nat`), none has a finalizer, and none
is ever freed before the end of the program. All are indexes into
static tables of `eng.h`, wrapped by `eng.atm` in small tagged
tables.

| Resource | Atmos value | C representation | Cache | Limit | Freed |
|----------|-------------|------------------|-------|-------|-------|
| Canvas | integer id | `EgCanvas EG_CVS[8]`: target texture, `out` texture, vertex list, run list, flags | no | 8 (`eng.canvas` returns -1) | never; lists emptied each frame |
| Shadow | none | one texture `EG_SHADOW`, created with the first canvas that has `shadow` | - | 1 | never |
| Font | `:Font [i, h]` | `EgFont EG_FNTS[16]`: one atlas texture, 95 boxes, offsets, advances, height. The `TTF_Font` is closed after the atlas is built | **no**: each `font(name, size)` builds a new atlas | 16 (then the `assert` fails) | never |
| Image | `:Image [i, w, h]` | `EgImg EG_IMGS_[256]`: path, texture, size | by path (linear `strcmp`) | 256 | never |
| Sound | `:Sound [i, kind]` | `EgSnd EG_SNDS_[256]`: path, `Mix_Chunk` (NULL when muted) | by path | 256 | `Mix_FreeChunk` at shutdown |
| Music | the same as a sound, with `kind=:music` | a `Mix_Chunk` too, decoded whole in memory; **no `Mix_Music`** | by path | - | as sounds |
| Sound instance | integer `channel \| generation << 8` | arrays of 64: `EG_OWN` (resampled copy), `EG_GEN`, `EG_DONE` | - | 64 channels | the copy: after the channel finishes, at the next `play` (`eg_snd_gc`), when the channel is reused, or at shutdown |

Notes:

- The game loads everything at start: 106 sounds at the top level of
  `src/sounds.atm` (5 of them songs, decoded whole to 44.1 kHz 16-bit
  stereo), the icons in loops (`src/passives.atm:40`,
  `src/shop.atm:20`), two fonts, one star.
- A load that fails prints to stderr and returns -1; the wrappers
  `assert`.
- An instance handle is checked against the generation of its
  channel, so `stop` or `set_volume` of an old instance is a no-op.
- The pitch has no support in SDL_mixer: an instance with a pitch
  other than 1 plays a private copy of the samples, resampled once by
  linear interpolation in C (`eg_resample`), only if the device is
  16-bit stereo. The flag `EG_DONE` is set from the audio thread
  (`Mix_ChannelFinished`) and read by the main thread (`volatile
  int`).
- Music: one instance at a time, kept by the task `Music`
  (`main.atm:21-50`), which sets its volume in every `:tick` and
  polls `playing` to start the next song. No loop points, no fades in
  the layer (the fade is a tween in the game).

## 7. Rendering path

### Summary

- **Everything visible is geometry**: each shape, glyph, image, and
  canvas-in-canvas becomes triangles (`SDL_Vertex`: position, color,
  texture coordinate) appended to the list of the current canvas
  (`eg_vertex`, `eng.h:226`). Consecutive vertices with the same
  texture form a run. At the end of the frame each run is one
  `SDL_RenderGeometry` (`eng.h:271`). There is no immediate drawing,
  and no `SDL_RenderCopy`, `SDL_RenderFillRect`, or `SDL_RenderDrawLine`
  for the content.
- **Render targets**: each canvas is a 480x270 target texture
  (`SDL_PIXELFORMAT_RGBA8888`, `SDL_TEXTUREACCESS_TARGET`), cleared
  to (0,0,0,0) each frame.
- **Software surfaces** are used only to build the atlases of the
  fonts and for the screenshot. But two CPU paths over raw pixels
  exist when the renderer has no premultiplied blending (below).
- **Textures**: images by `IMG_LoadTexture`; atlases by
  `SDL_CreateTextureFromSurface`; both with `SDL_BLENDMODE_BLEND`.
  Filtering is nearest for all (`SDL_HINT_RENDER_SCALE_QUALITY=0`,
  set before any texture is created).
- **No logical size**: `SDL_RenderSetLogicalSize` and
  `SDL_RenderSetScale` are not used. The game draws at 480x270 into
  canvases; the canvases are stretched to the window (480*S x 270*S)
  by the composition. The mouse is divided by S by hand
  (`eng.h:1305`). The window is not resizable; S is an integer from
  `SNX_SCALE`.

### Transforms

A stack of 32 affine matrices in doubles (`EG_MATS`, `eng.h:81`),
applied on the CPU to every vertex (`eg_xy`, `eng.h:127`); SDL sees
final coordinates. `eg_push` does translate, scale, rotate, translate
back; `eg_print` and `eg_img_draw` push their own (translate, rotate,
scale). A push beyond 32 is silently ignored, and so is a pop at 0.
`EG_TOP` is reset to 0 at the end of each frame (`eng.h:414,439`),
but `EG_MATS[0]` is not reset to the identity.

The game relies on the reset and on an unbalanced pair: the camera
is pushed by one task (`cam_push`, `src/fx.atm:83`) and popped by
another one, later in the same `:draw` (`src/arena.atm:121`).

### Shapes

Tessellated in C as LÖVE 11 does, so that the pixels match the
original:

- Circles and ellipses: `max(8, floor(sqrt(((rx+ry)/2)*20)))`
  segments (`eg_points`, `eng.h:488`); arcs in proportion.
- Rounded rectangles: the radii clamped to `side/2 - 0.01`, each
  corner with `points/4 + 1` segments (`eng.h:570-579`).
- Fills are fans (convex only). Strokes are quads with miter joins,
  the miter limited to 4 half-widths (`eg_stroke`, `eng.h:505`).
- At most 1024 points per shape (`EG_PTS`); static scratch arrays.

### Pixel coverage

A constant offset is added to x and y of every vertex (`EG_OFF`,
`eng.h:213-223`, set in `main` at `eng.h:1269-1273`), chosen by the
name of the renderer, measured against LÖVE 11.5:

| Renderer | Shapes, images, canvases | Text |
|----------|--------------------------|------|
| `software` | +0.499 | +0.501 |
| any other (OpenGL) | 0 | +0.001 |

Pixel exactness therefore depends on: the renderer (software in the
tests), the rasterization rules of `SDL_RenderGeometry` of the SDL
version, these offsets, nearest filtering, FreeType (glyph bitmaps
and metrics), the PNG encoder behind `IMG_SavePNG` (screenshots are
compared as files), the scale 2, and the exact order of the
floating-point operations of the transforms and tessellation.

### Text

A font is one atlas of the printable ASCII glyphs (32 to 126), in one
row, white with alpha (`eng.h:666-772`): each glyph is rendered with
`TTF_RenderGlyph32_Blended`, converted to RGBA32, cropped to the
bounding box of its non-zero alpha, and placed with 1 pixel between
glyphs. Metrics, as LÖVE 11:

- height of the font = `TTF_FontLineSkip`;
- pen advance = `advance` of `TTF_GlyphMetrics32`; no kerning;
- offset of the box from the pen: `ox = minx`,
  `oy = TTF_FontAscent - maxy`.

Text is then quads from the atlas, colored by vertex, under the
transform (so rotation and non-integer scale work, e.g. 0.75 at
`src/level.atm:203`). Bytes outside 32-126 are skipped: **no UTF-8**.
The space has no box, only an advance. `eng/text.atm` draws tagged
text one character per `print_at` call, each inside its own
`eng.push`/`eng.pop`.

### The canvas model

A canvas is three things: a 480x270 target texture; the list of
triangles drawn "into" it during this frame; and two flags given at
creation, `screen` and `shadow`. The canvas that receives the shapes
is a global, set by `eng.target`. The game creates three, in this
order (`src/shared.atm:9-11`):

```
STARS = eng.canvas(false, false)   -- off screen
BACK  = eng.canvas(true,  false)   -- background, no shadow
MAIN  = eng.canvas(true,  true)    -- everything else, with shadow
```

The default target is MAIN; a task that draws elsewhere selects the
other canvas and selects MAIN back (`src/shared.atm:22,31,71,73`).

The end of a frame (`eg_frame`, `eng.h:394`):

1. For each canvas **in the order of creation**: set it as the render
   target, clear to (0,0,0,0), render its runs. Untextured triangles
   blend with the draw blend mode of the renderer (`BLEND`), textured
   ones with the blend mode of their texture. Blending into a
   transparent target leaves **premultiplied** colors in it, as a
   canvas of LÖVE.
2. A canvas can be drawn into another one (`eng.canvas_draw`,
   `eng.canvas_draw_outside`): it is a textured quad in the list of
   the current canvas, whose texture is the `out` of the source. So
   the source must have been created before the destination, to hold
   this frame's content when the destination is rendered. A canvas
   cannot be drawn into itself (ignored). The game does it once:
   STARS into MAIN, except inside the arena (`src/arena.atm:122`),
   in place of a stencil mask of the original.
3. Composition to the window, in the order of creation, of the
   canvases with `screen`: the window is cleared to the background
   color (`EG_BG`); each canvas is stretched to the whole window.
4. **The shadow**: before a canvas with `shadow` is composed, its
   list is replayed into the single shadow texture, cleared to
   (25,25,25,0), with the color of every vertex replaced by
   (25,25,25) and its alpha kept (`eg_render` with `shadow`,
   `eng.h:260-268`; the list is overwritten in place, after its
   normal render). Textured runs replay too, so images, text, and the
   stars become dark silhouettes. The shadow is composed under the
   canvas at half opacity (alpha mod 128), **1.5 game pixels down and
   right**, that is 1.5*S window pixels (`eng.h:429`). It replaces a
   shader of the original.

Two consequences for a common interface:

- The shadow offset is half a game pixel off the grid: the
  composition happens **at the resolution of the window**, not at
  480x270. A logical size of 480x270 on the renderer could not
  express it at scale 2 as it is today (3 window pixels).
- The shadow needs the **draw list** of the canvas, not only its
  pixels: it re-renders the geometry with another color. (It could
  be made from the pixels of the canvas, but it is not what the code
  does, and the screenshots are compared exactly.)

Premultiplied composition, two paths (`EG_PREMUL_OK`,
`eng.h:163-195`):

- **With a custom blend mode** (`SDL_ComposeCustomBlendMode(ONE,
  ONE_MINUS_SRC_ALPHA, ADD, ONE, ONE_MINUS_SRC_ALPHA, ADD)` accepted
  by `SDL_SetTextureBlendMode`; OpenGL): the target textures carry
  that mode, `out` is the target itself, and the composition is
  `SDL_RenderCopyF` of the shadow then the canvas, on the GPU
  (`eng.h:417-433`).
- **Without it** (the software renderer, so **all the tests**; or
  `SNX_NO_PREMUL`): the targets get `BLENDMODE_NONE`.
  - A canvas that is not on screen (STARS) is read back with
    `SDL_RenderReadPixels`, each color divided by its alpha on the
    CPU, and uploaded to a streaming texture `out` (RGBA32,
    `BLENDMODE_BLEND`) (`eg_canvas_out`, `eng.h:279`).
  - The screen canvases are composed on the CPU (`eg_compose_cpu`,
    `eng.h:311-392`): each one and the shadow are read back
    (`SDL_RenderReadPixels`, RGBA32); the canvases other than the one
    with a shadow are blended over the background per game pixel;
    then, per window pixel, the shadow (alpha * 128/255, offset
    `(int)(1.5*S + 0.5)` window pixels) and the canvas with the
    shadow, with integer arithmetic (`EG_DIV255`); the result goes to
    a window-sized streaming texture and one `SDL_RenderCopy`.
  - This path assumes **at most one** canvas with a shadow and puts
    it on top of all the others, whatever the order of creation
    (`eng.h:336-338`).

Pixel formats: targets and shadow `RGBA8888`; streaming textures,
read-backs, atlases, and screenshots `RGBA32` (byte order R,G,B,A).
Images keep the format `IMG_LoadTexture` gives.

Not present: clipping or scissor, stencil, shaders, additive or
other blend modes for the content, sub-rectangles of images, flips
(other than a negative scale), texture filtering other than nearest,
canvases of another size.

## 8. Differences from `lib/sdl.atm`

`/home/user/lang/lib/sdl.atm` (374 lines) against this layer:

| Aspect | `lib/sdl.atm` | SNKRX layer |
|--------|---------------|-------------|
| Structure | one `.atm`, C in the prelude | `eng.h` included by the prelude of `eng.atm`; needs `-I` of the root |
| Window | created by the program: `sdl.window [title,width,height]` | created by `main` before the main chunk; fixed title and size, `SNX_SCALE` |
| Event tags | `:sdl.key.dn`, `:sdl.key.up`, `:sdl.quit`, `:sdl.draw` | `:key.dn`, `:key.up`, `:quit`, `:draw`, plus `:mouse.mv/dn/up`, `:tick`, `:overlay` |
| Event values | bare tag when there is no payload | always a tagged table |
| Mouse | none | events and `eng.mouse()` |
| Time | real elapsed ms per frame (`SDL_GetTicks`), or fixed in the test mode; emitted if > 0 | always the nominal 1/60 s in us; a real clock as `:tick [us]` and a game clock scaled by `eng.slow` |
| Frame cap | `SDL_Delay(16)` | 60 Hz on the performance counter |
| Drawing | immediate: `SDL_RenderCopy`, `SDL_RenderFillRect`, on the window, cleared to black before `:sdl.draw` | deferred lists of triangles per canvas, `SDL_RenderGeometry`, composition with shadow |
| Draw state | a current color (`sdl.color`, `0xRRGGBB`, no alpha) | a color per call (`0xRRGGBBAA`), a transform stack, a current canvas |
| Coordinates | integer rectangles `[x,y,w,h]` in window pixels | floats in game pixels, transformed |
| Shapes | filled rectangle | rounded rectangles, circles, ellipses, arcs, polygons, polylines, lines, gradient; fill or stroke |
| Images | `sdl.image(path)`: a native box with a finalizer (`SDL_DestroyTexture`), `pin`; `sdl.copy(tex, crop, rect)` with a source rectangle; no rotation, no color | index into a table, cached by path, never freed; whole image, centered, rotation, scale, color; no source rectangle |
| Fonts | `sdl.font`: a native box (`TTF_CloseFont`) | an atlas of ASCII glyphs; the `TTF_Font` is closed at once |
| Text | `sdl.write`: `TTF_RenderUTF8_Blended` + a texture per call, centered, UTF-8, current color | quads from the atlas, ASCII only, any transform, `text_width`, LÖVE metrics |
| Sound | `sdl.play(path)`: cache of 64 by path, no handle, no volume | `sound`/`play`/`playing`/`stop`/`set_volume`/`sound_len`: handles, volume, pitch, loop, 64 channels, 256 sounds |
| Files | none | `eng.read_file`, `eng.write_file` |
| Helpers | `sdl.pct_to_pos`, `sdl.rect_vs_rect`, `sdl.size` | none of these; `rgba`, `hex`, `comps` |
| Test: frames | `SDL_ATM_FRAMES=n:ms` (the ms fixes dt and removes the delay) | `SNX_FRAMES=n` (dt is fixed anyway) |
| Test: input | `SDL_ATM_KEYS=f:dn:A` (keys) | `SNX_INPUT=f:dn:k`, `f:up:k`, `f:mv:x:y`, `m1..m3` (keys and mouse) |
| Test: shots | `SDL_ATM_SHOT=f:x.png`, every frame is rendered | `SNX_SHOT=f:x.png`; only those frames are rendered |
| Test: other | none | `SNX_MUTE`, `SNX_SCALE`, `SNX_RENDER`, `SNX_RENDERER`, `SNX_RENDERER_INFO`, `SNX_NO_PREMUL`, `SNX_PROFILE` |
| Renderer | default driver | `software` forced in the test mode |
| Shutdown | `atm_stop`, `atm_quit`, `Mix_CloseAudio`, `TTF_Quit`, `SDL_Quit` | the same order, plus `Mix_HaltChannel` and the chunks freed |

The same in both: `SDL_Init` with the fallback to video alone;
`TTF_Init`; `Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)`; key
names from `SDL_GetKeyName` with repeats dropped; the shape of the
test script (`frame:...` items separated by commas, parsed by a
function that is almost the same, `sdl_script` / `eg_script`); the
screenshot (`SDL_RenderReadPixels` RGBA32 + `IMG_SavePNG` before the
present); the order events, time, draw, present; the end of `main`.
`eng.h` was visibly derived from the driver of `lib/sdl.atm`.

## 9. Oddities and risks for a shared environment

1. **Exact screenshots.** 42 PNGs are compared with `cmp`, rendered
   by the software renderer at scale 2. Any change in tessellation,
   offsets, blending arithmetic (`EG_DIV255`, the unpremultiply
   rounding `(p*255 + a/2)/a`), order of composition, glyph cropping,
   or PNG writing changes them. The plan of the game asks for
   "identical traces and screenshots" after the move
   (`.claude/plans/TODO.md`, B4).
2. **The canvas model** is LÖVE's, not SDL's: premultiplied canvases,
   a shadow replayed from the draw list, composition at window
   resolution with a 1.5-pixel offset, a CPU composition path on the
   software renderer that knows about exactly one shadow canvas.
   The game's plan states that a common interface "must keep that".
3. **Deferred drawing.** Nothing is drawn when the game calls; a
   shared environment with immediate drawing changes when and where
   pixels appear (the shadow, canvas-in-canvas, and skipping the
   render in the test mode all rely on the lists).
4. **Global mutable state**, all `static` in one translation unit:
   current canvas, transform stack, background color, time scale,
   mouse, tick, text offset `EG_OFF` (switched during `eg_print`),
   scratch point arrays, the tables of resources. Names are prefixed
   `EG_`/`eg_` (and `PW_`/`pw_` in `phys.h`); `lib/sdl.atm` uses
   `SDL_`/`sdl_` for its own, which sits in SDL's own namespace.
5. **Order dependences between tasks**: the draw order is the order
   of the tasks awaiting `:draw`; the camera transform is pushed in
   one task and popped in another; tasks switch the target canvas and
   must switch it back; `EG_TOP` is reset each frame but
   `EG_MATS[0]` is not.
6. **Time is not real.** The layer never measures elapsed time; a
   tick is 1/60 s by definition, in whole microseconds (16666/16667),
   and the game depends on these exact values (`tick_dt`,
   `eng/anim.atm:100`, rounds them back to 1/60 to reproduce the
   float sums of the original). `eng.tick()/60` is used as the real
   clock in seconds (`src/input.atm:16`, `src/fx.atm:59`,
   `eng/text.atm:129`). An environment that emits the measured
   elapsed time would change behavior and the traces.
7. **Two clocks and the slow motion in the driver.** `eng.slow`
   scales the time emitted to Atmos, and with 0 no time is emitted at
   all; `:tick` carries the unscaled time. This lives in the loop of
   the environment, not in the game.
8. **`:draw` is emitted even when nothing is rendered** (test mode),
   and `:overlay` is a second draw event. The game's logic may run
   inside `:draw` handlers (e.g. `rfloat` is called while drawing,
   `src/attack.atm:244`), so skipping `:draw` would change the
   random sequence and the traces.
9. **Events are tables with fixed tag names** with no prefix; 53
   `:draw`, 16 `:mouse.mv`, 9 `:mouse.dn`, 7 `:key.dn` sites and the
   tests await them by name, and compare `e.name` with SDL key names
   (`"Escape"`, `"R"`, `"1"`) and `e.but` with SDL button numbers.
10. **Performance-sensitive C**: the per-vertex transform and
    tessellation; the per-window-pixel loop of `eg_compose_cpu`
    (960x540 per rendered frame) and the read-backs, on the software
    renderer; the resampling of a sound at every pitched `play` (233
    of the 237 play sites give a pitch; a song is resampled whole if
    pitched, which the game does not do). `doc/bench.md` measures the
    render at about 8 s of 1500 ticks under llvmpipe, against 0.2 to
    4 s of logic.
11. **Many small native calls per frame from Atmos**: the background
    is 288 `eng.rect2` calls per frame (`src/shared.atm:23-29`);
    tagged text is a push, a print, and a pop per character
    (`eng/text.atm:145-148`). There is no batch entry point in C for
    the game, and the game has no C of its own that would need the
    renderer or a texture pointer; today nothing outside `eng.h`
    touches `EG_REN` or an `SDL_Texture*`.
12. **Resources are never freed** and are capped by static tables
    (8 canvases, 16 fonts with no cache, 256 images, 256 sounds, 64
    channels, 32 transforms, 1024 points). A full table returns -1
    (or ignores the call) rather than raising. Moving to native boxes
    with finalizers changes lifetimes: the game keeps `:Font`,
    `:Image`, `:Sound` tables in globals for the whole run.
13. **Music as a chunk**: five songs decoded whole in memory at
    start, played on an ordinary channel, with the volume set every
    tick and the end polled. There is no `Mix_Music`.
14. **Thread**: `EG_DONE` is written by the audio thread; the copies
    are freed on the main thread only when `Mix_Playing` is false.
15. **Silent conversions**: wrong types become 0 or white; text
    outside ASCII is dropped; `SNX_INPUT` items of the wrong form are
    ignored; `eng.target` of a bad id is ignored.
16. **The window exists before the program runs**, with a size the
    program cannot choose (480x270 times `SNX_SCALE`, constants in
    C). The top level of the game creates canvases and loads
    resources right away, so a shared environment must have a
    renderer before the first statement of the game, or the game
    must change.
17. **Mouse in the test mode**: real mouse events are dropped, real
    key events are not. Test-mode detection also leaks into the game
    (`eng.testing` for the seed, `SNX_FRAMES` read by
    `src/save.atm:20`).
18. **Names**: the layer exports short global names into the
    program (`W`, `H`, `font`, `image`, `sound`, `play`, `stop`,
    `playing`, `hex`, `rgba`, `comps`, `trace`, `VOLUME`, `ASSETS`),
    besides the table `eng`. `font`, `image`, and `sound` take a
    name of an asset of the original, not a path.
19. **Variables of the environment** are named `SNX_*` and are used
    by 31 test scripts, `tools/bench/perf.py`, and the game itself.
20. **Not SDL**: files (`eng.read_file`, `eng.write_file`, with
    `mkdir`, POSIX only) and the physics are in `eng/` but are
    independent of SDL.
21. **Shutdown details**: `Mix_FreeChunk` runs after
    `Mix_CloseAudio`; textures, renderer, and window are left to
    `SDL_Quit`.
