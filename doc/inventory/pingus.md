# Inventory: the SDL2 platform layer of Pingus

> **A picture of the layer before the move.** Pingus moved over this
> environment on 2026-11-17 (`sdl-pingus` `e9fd322`): its layer is
> now the game's C over the door of `sdl.atm`. This document is kept
> as the record of E1, and is not updated.

Game: `/home/user/sdl-pingus` at commit `45ea8be`. Base environment
compared: `/home/user/lang/lib/sdl.atm` (374 lines) at `e9cafa7`.
This document only records what exists; it proposes nothing.

Conventions: `sdl.atm:N` is `engine/sdl.atm`, `pingus.h:N` is
`engine/pingus.h`, `engine.atm:N` is `engine/engine.atm`, all in the
game. `lib:N` is `lang/lib/sdl.atm`. Call-site counts come from
`grep -E '\bpg\.NAME *\('` over every `.atm` outside `data/` and
outside `engine/sdl.atm` itself (so they include `engine/engine.atm`,
`game/`, `screens/`, `main.atm`, `tst/`, `tools/`).

## 1. Files, include, build

| File                | Lines | Content |
|---------------------|------:|---------|
| `engine/pingus.h`   |   930 | All the C: globals, images, shapes, bitmap fonts, audio, display, ground maps, pingu mover, test script, `main` |
| `engine/sdl.atm`    |   175 | Prelude `#include "engine/pingus.h"`; `W`, `H`; table `pg` (31 functions, thin native wrappers); tables `GP`, `MOD` |
| `engine/engine.atm` |   453 | Pure Atmos over `pg` (no native literal): data files, sprite descriptions, `Sprite`, fonts by name, translations, sound/music by name, `MOUSE`, `OPTIONS`, widgets |

Other files of the game (for scale): `main.atm` 90, `game/` 2367 in
42 files, `screens/` 1087 in 9 files, `tst/engine.atm` 24,
`tools/check.atm` 31.

Include chain: `main.atm:16` `include "engine/engine.atm"`;
`engine.atm:9` `include "sdl.atm"`; `sdl.atm:29-31` is a native
literal tagged `:prelude` whose only content is
`#include "engine/pingus.h"`. The header comes after the header of
the Atmos runtime (it uses `AVal`, `a_dbl`, `atm_emit`, ...) and
defines `main` (`pingus.h:811`). `tst/engine.atm:7` includes
`../engine/engine.atm` directly, with no game.

Build (`run.sh`, 30 lines):

- compiler: `$ATMOS`, else `../lang/atmos` (also tries
  `../ia-atmos/lang`, `../ceu-atmos`, `../fsantanna/ceu-atmos`), else
  `atmos` in the PATH (`run.sh:14-23`);
- `ATMOS_CFLAGS="${ATMOS_CFLAGS:--O2} -I$ROOT"` (`run.sh:27`): the
  `-I$ROOT` is what resolves `engine/pingus.h` from the prelude;
- `ATMOS_LDFLAGS="-lSDL2 -lSDL2_image -lSDL2_mixer -lm"`
  (`run.sh:28`): no SDL_ttf; `-lm` for `sqrtf`;
- `ATMOS_ASAN=1` is passed through to the compiler
  (`tst/run.sh:41` uses it with `ATMOS_CFLAGS="-O1 -g"`);
- `cd "$ROOT" && exec "$ATMOS" "$FILE" "$@"` (`run.sh:30`): the
  working directory is the root of the game, and every resource path
  is relative to it (`"data/..."`).
- `./run.sh -o out/pingus main.atm` builds a binary without running
  (`tst/run.sh:43`); the tests then run that binary.

There is no dedicated compiler (`make env`) and no Makefile: the
layer is included by the program.

Setup done by the layer before the program starts
(`pingus.h:812-846`): `SDL_Init(VIDEO|AUDIO)` (falls back to VIDEO
alone), `Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)` unless
`PINGUS_MUTE` is set, `Mix_AllocateChannels(32)`, window `"Pingus"`
800x600 centered with flags 0, `SDL_CreateRenderer(win, -1, 0)`
(exit 1 with a message on failure), then `atm_init`, `atm_main`.
`IMG_Init` is never called (SDL_image initializes lazily).

## 2. Functions

### 2.1 The table `pg` (`engine/sdl.atm`), exposed to Atmos

All arguments cross as numbers or strings. `pg_int` (`pingus.h:37`)
converts with a C cast (truncation toward zero; non-numbers become
0). `pg_cstr` (`pingus.h:41`) gives NULL for non-strings. Images and
fonts are integer indices. Colors are `0xRRGGBBAA` numbers.

Class: `P-common` platform, plausibly for any game; `P-game`
platform, specific to this game; `G` game logic.

| Name | Signature | Purpose | SDL calls behind | Sites (example) | Class |
|------|-----------|---------|------------------|-----------------|-------|
| `pg.img` (`sdl.atm:38`) | `(path, mod [, [cx,cy,cw,ch]])` -> index, or -1 | Loads an image once per key `path#mod#cx,cy,cw,ch`; optional crop, then one of 8 rotations/flips | `IMG_Load`, `SDL_ConvertSurfaceFormat`(RGBA32), `SDL_CreateRGBSurfaceWithFormat`, `SDL_SetSurfaceBlendMode`, `SDL_BlitSurface`, `SDL_FreeSurface` (`pingus.h:94-138`) | 7, all in `engine/engine.atm` (`engine.atm:85`) | P-common for load+cache; the crop is P-common; the 8 modifiers (`pg_modify`, `pingus.h:63`) are P-game |
| `pg.size` (`sdl.atm:44`) | `(img)` -> `w, h` (0,0 if invalid) | Size of an image | none (reads `PgImg.w/h`) | 19 (`game/objs/surface_background.atm:6`) | P-common |
| `pg.draw` (`sdl.atm:51`) | `(img, x, y)` | Whole image at `x,y`, same size | via `pg_img_draw` (`pingus.h:154`): `SDL_CreateTextureFromSurface` + `SDL_SetTextureBlendMode` on the first draw, `SDL_RenderCopy` | 15 (`game/objs/surface_background.atm:40`) | P-common |
| `pg.part` (`sdl.atm:56`) | `(img, sx,sy,sw,sh, x,y [, alpha])` | Part of an image at `x,y`, optional alpha 0-255 | same, plus `SDL_SetTextureAlphaMod` (set, then restored to 255) | 2 (`game/objs/extra.atm:268`, `engine.atm:229` in `Sprite`) | P-common |
| `pg.scale` (`sdl.atm:62`) | `(img, x,y,w,h)` | Whole image stretched into a rectangle | same (`SDL_RenderCopy` with a different dst size) | 0: **unused** | P-common |
| `pg.fill` (`sdl.atm:67`) | `(rgba, x,y,w,h)` | Filled rectangle, alpha blended | `SDL_SetRenderDrawBlendMode`(BLEND), `SDL_SetRenderDrawColor`, `SDL_RenderFillRect` (`pingus.h:186`) | 4 (`game/objs/surface_background.atm:46`) | P-common |
| `pg.rect` (`sdl.atm:70`) | `(rgba, x,y,w,h)` | Rectangle outline | ..., `SDL_RenderDrawRect` (`pingus.h:193`) | 1 (`game/hud.atm:134`) | P-common |
| `pg.line` (`sdl.atm:73`) | `(rgba, x1,y1,x2,y2)` | Line | ..., `SDL_RenderDrawLine` (`pingus.h:200`) | 6 (`game/hud.atm:140`) | P-common |
| `pg.font_new` (`sdl.atm:78`) | `(size, char_spacing, vertical_spacing)` -> index, or -1 | New empty bitmap font (65536 glyph slots) | none (`malloc`) (`pingus.h:228`) | 1 (`engine.atm:261`) | P-game (bitmap fonts from the `.font` data of Pingus) |
| `pg.font_glyph` (`sdl.atm:81`) | `(font, unicode, img, x1,y1,x2,y2, ox,oy, adv)` | Sets one glyph: rectangle in an image, offset, advance | none (`pingus.h:243`) | 1 (`engine.atm:265`, in a loop over all glyphs) | P-game |
| `pg.font_draw` (`sdl.atm:84`) | `(font, txt, x, y, origin, [alpha])`; origin 0 left, 1 center, 2 right | Draws UTF-8 text, multi-line (`\n`) | `pg_img_draw` per glyph -> `SDL_RenderCopy` (`pingus.h:300`) | 1 (`engine.atm:286`, in `text`) | P-game |
| `pg.font_width` (`sdl.atm:88`) | `(font, txt)` -> pixels | Width of the widest line | none (`pingus.h:283`) | 1 (`engine.atm:290`, in `text_width`) | P-game |
| `pg.sound` (`sdl.atm:93`) | `(path [, vol=1.0])` | Plays a WAV; chunks cached by path (max 64) | `Mix_LoadWAV`, `Mix_PlayChannel(-1)`, `Mix_Volume(ch)` (`pingus.h:331`) | 1 (`engine.atm:342`, in `sound`) | P-common (per-play volume is an addition) |
| `pg.music` (`sdl.atm:97`) | `(path)` | Loops a music file; no-op if the same path is already playing | `Mix_LoadMUS`, `Mix_PlayMusic(-1)`; stops the previous one first (`pingus.h:406`) | 1 (`engine.atm:349`, in `music`) | P-common |
| `pg.music_stop` (`sdl.atm:108`) | `()` | Stops and frees the music | `Mix_HaltMusic`, `Mix_FreeMusic` (`pingus.h:396`) | 1 (`engine.atm:347`) | P-common |
| `pg.volume` (`sdl.atm:100`) | `(snd, mus)`, each 0..1 | Global volumes of sounds and music | `Mix_Volume(-1)`, `Mix_VolumeMusic` (`pingus.h:360`) | 1 (`screens/options.atm:25`) | P-common |
| `pg.display` (`sdl.atm:104`) | `(full, w, h, grab, soft)` (booleans and numbers) | Logical size 800x600; fullscreen-desktop or window size; mouse grab; hide system cursor | `SDL_RenderSetLogicalSize`, `SDL_SetWindowFullscreen`, `SDL_SetWindowSize`, `SDL_SetWindowPosition`, `SDL_SetWindowGrab`, `SDL_ShowCursor` (`pingus.h:380`) | 1 (`screens/options.atm:28`) | P-common (window/fullscreen/grab/cursor) |
| `pg.map_new` (`sdl.atm:113`) | `(w, h)` | Allocates the ground of a level: collision bytes + RGBA32 surface + tile table (frees the previous one) | `SDL_CreateRGBSurfaceWithFormat`, `SDL_FillRect` (`pingus.h:467`) | 1 (`game/game.atm:129`) | G |
| `pg.map_free` (`sdl.atm:116`) | `()` | Frees the ground | `SDL_FreeSurface`, `SDL_DestroyTexture` (`pingus.h:447`) | 1 (`game/game.atm:131`, in a `defer`) | G |
| `pg.map_get` (`sdl.atm:119`) | `(x, y)` -> ground type 0..8 (8 outside) | Reads the collision map | none (`pingus.h:481`) | 4 (`game/objs/extra.atm:71`) | G |
| `pg.map_put` (`sdl.atm:122`) | `(img, x, y, type)` | Blits an image into the ground image; marks its fully opaque pixels in the collision map | `SDL_BlitSurface` (`pingus.h:504`) | 1 (`game/ground.atm:5`) | G |
| `pg.map_col` (`sdl.atm:125`) | `(img, x, y, type)` | Sets the type of the opaque pixels in the collision map only | none (`pingus.h:536`) | 2 (`game/objs/extra.atm:350`) | G |
| `pg.map_remove` (`sdl.atm:128`) | `(gfx, col, x, y)` | Erases pixels of the ground image (mask `gfx`) and of the collision map (mask `col`), except solid | none, direct pixel writes (`pingus.h:560`) | 1 (`game/ground.atm:9`) | G |
| `pg.move` (`sdl.atm:132`) | `(x, y, vx, vy, h)` -> `hit, x', y'` | The mover of a pingu, unit steps in 32-bit `float` up to a collision; results via globals `PG_MX`, `PG_MY` | none (`pingus.h:609-648`) | 1 (`game/pingu/pingu.atm:120`) | G |
| `pg.f32` (`sdl.atm:138`) | `(x)` -> `x` rounded to a C `float` | 32-bit rounding as the original game | none (inline cast) | 20 (`game/pingu/actions/boarder.atm:16`) | G (a numeric helper, no SDL) |
| `pg.map_draw` (`sdl.atm:142`) | `(ox, oy)` | Draws the ground image at an offset, through 128x128 streaming textures updated when dirty | `SDL_CreateTexture`(RGBA32, STREAMING), `SDL_SetTextureBlendMode`, `SDL_UpdateTexture`, `SDL_RenderCopy` (`pingus.h:651`) | 1 (`game/game.atm:139`) | G (needs the renderer) |
| `pg.map_small` (`sdl.atm:145`) | `(x, y, w, h)` | Draws the minimap from the collision map; rebuilt when the map serial changes | `SDL_CreateTexture`, `SDL_DestroyTexture`, `SDL_UpdateTexture`, `SDL_RenderCopy` (`pingus.h:685`) | 1 (`game/hud.atm:123`) | G (needs the renderer) |
| `pg.frame` (`sdl.atm:150`) | `()` -> frame number (1-based) | `PG_FRAME` | none | 0: **unused** | P-common |
| `pg.testing` (`sdl.atm:153`) | `()` -> boolean | `PG_TEST` (true iff `PINGUS_FRAMES` is set) | none | 1 (`main.atm:28`, to seed the random numbers with 0) | P-common |

Constants in `engine/sdl.atm`:

| Name | Value | Uses outside `engine/` | Class |
|------|-------|------------------------|-------|
| `W`, `H` (`sdl.atm:33-34`) | 800, 600 (duplicated from `PG_W`, `PG_H`, `pingus.h:32-33`) | 40 and 32 lines | P-common |
| `GP` (`sdl.atm:159`) | ground types 0..8, mirror of the enum at `pingus.h:425` | 49 lines | G |
| `MOD` (`sdl.atm:172`) | modifiers 0..7 | 0 outside; 1 in `engine.atm:119` (`res_surface`) | P-game |

### 2.2 C functions and macros

No Atmos file other than `engine/sdl.atm` has a native literal
(verified: `grep` for a backquote outside comments finds none in
`main.atm`, `game/`, `screens/`, `tst/`, `tools/`,
`engine/engine.atm`). The game has no C file of its own:
`engine/pingus.h` is the only C. So "C called directly" means the C
names used inside the literals of `engine/sdl.atm`:

| C name | Where | Used by literal(s) |
|--------|-------|--------------------|
| `pg_int(AVal)` -> int | `pingus.h:37` | almost all |
| `pg_cstr(AVal)` -> `const char*` | `pingus.h:41` | img, font_draw, font_width, sound, music |
| `a_dbl(AVal)` (runtime) | - | fill/rect/line (color as `int64_t`), font_new, sound, volume, move, f32 |
| `pg_img(int)` -> `PgImg*` and fields `w`, `h` | `pingus.h:140` | `pg.size`, inside GCC statement expressions `({ ... })` (`sdl.atm:45-46`) |
| `pg_img_load`, `pg_img_draw` | `pingus.h:94,154` | img; draw, part, scale |
| `pg_fill`, `pg_rect`, `pg_line` | `pingus.h:186-204` | same names |
| `pg_font_new/glyph/draw/width` | `pingus.h:228-324` | same names |
| `pg_sound`, `pg_volume`, `pg_music`, `pg_music_stop` | `pingus.h:331-419` | same names |
| `pg_display` | `pingus.h:380` | display |
| `pg_map_new/free/get/put/col/remove/draw/small` | `pingus.h:447-726` | same names |
| `pg_move`, globals `PG_MX`, `PG_MY` | `pingus.h:607-648` | move (three literals in sequence, `sdl.atm:133-134`) |
| globals `PG_FRAME`, `PG_TEST` | `pingus.h:809,35` | frame, testing |

Internal C, never named from Atmos: `pg_modify`, `pg_tex`,
`pg_color`, `pg_utf8`, `pg_font_line_width`, `pg_map_dirty`,
`pg_collides`, `pg_field`, `pg_emit`, `pg_shot`, `pg_script`, `main`.

Literal tags used: `:prelude`, `:number`, `:number.float`,
`:boolean`, and untagged statements. No `:value`, no native boxes.

### 2.3 Second level: `engine/engine.atm` (pure Atmos)

Not SDL, but it is "the engine" the game actually calls; most game
code reaches `pg` only through it. Counts are lines with a call,
excluding the definition (they include uses inside `engine.atm`).

| Name | Line | Purpose | Uses (example) | Class |
|------|-----:|---------|----------------|-------|
| `file_exists(path)` | 13 | `io.open` probe | 4 (`game/hud.atm:19`) | P-common |
| `data_load(path)` | 24 | Reads a file and `X.load`s it | 11 (`main.atm:58`) | P-game |
| `dirname`, `path_norm` | 32, 44 | Path helpers | 1 each (engine only) | P-common |
| `res_desc(name)` | 63 | Sprite description by name, cached in `DESCS`; 404 image fallback | 5 (`game/objs/extra.atm:263`) | P-game |
| `origin(o, w, h)` | 100 | Offset of a named origin | 2 (engine only) | P-game |
| `res_surface(name, mod)` | 117 | Image index of a resource (first frame, modifier) | 44 (`game/objs/surface_background.atm:5`) | P-game |
| `look(d, anchor)` | 142 | Drawing data of a description | 3 (`game/objs/extra.atm:266`) | P-game |
| `task Sprite(name, pos, o)` | 177 | Animated sprite task: draws on `:sdl.draw`, advances on `:clock` (ms = us//1000) or on `:tick` (+33ms), emits `:frame` to its parent | 88 (`game/objs/spike.atm:20`) | P-game (animation by tasks could be common; `:tick`, `CAM`, `turn` are game) |
| `res_frame_size(name)` | 237 | Frame size of a resource | 12 (`game/objs/exit.atm:9`) | P-game |
| `task Image(img, pos)` | 244 | Draws an image forever | 0: **unused** | P-common |
| `font(name)`, `FONT` | 255, 274 | Fonts by name from `.font.atm`; four fonts loaded at include time | `FONT.` on 37 lines outside engine | P-game |
| `text(f,s,x,y,[o],[a])` | 285 | Draws text | 55 (`game/hud.atm:42`) | P-game wrapper of a P-common need |
| `text_width`, `break_lines` | 289, 294 | Measure, word wrap | 2, 2 (`screens/common.atm:46`, `screens/story.atm:21`) | P-common |
| `tr`, `lang_set`, `langs`, `LANG` | 316-337 | Translations from `data/po/` | 39, 1, 1 | G |
| `sound(name [, vol])` | 341 | `pg.sound("data/sounds/NAME.wav")` | 22 (`game/game.atm:271`) | P-game |
| `music(name)` | 345 | `pg.music("data/music/NAME")`, or stop for nil/""/"none" | 6 (`game/game.atm:133`) | P-game |
| `CAM`, `ZERO` | 137-138 | Camera of the level | `CAM` on 34 lines outside engine | G |
| `MOUSE` + spawned tracker | 357-365 | Last mouse position, updated from `:sdl.mouse.motion` | `MOUSE.` on 16 lines outside engine | P-common |
| `OPTIONS` | 372 | Player options (defaults) | 15 lines outside engine | G |
| `inside(r, x, y)` | 386 | Point in rectangle | 18 (`game/hud.atm:46`) | P-common |
| `task Click(r [, but])` | 394 | Button down then up inside `r` | 10 (`game/hud.atm:29`) | P-common |
| `task Hover(r, name, snd)` | 405 | Sprite while the mouse is over | 1 (`screens/menu.atm:33`) | P-game |
| `task Button(r, n, h, p)` | 419 | Three-sprite button | 9 (`tst/engine.atm:23`) | P-game |
| `task Wood()` | 443 | Tiled background | 3 (`tst/engine.atm:9`) | G |

## 3. Events

All events are built by `pg_emit` (`pingus.h:741`) and broadcast with
`atm_emit`. Every event is a **tagged table**: with a name it is
`:tag [name=...]`, otherwise `:tag [x=, y=, but=]` (integers).

| Tag | Payload | Emitted | Awaited (non-comment lines; example) |
|-----|---------|---------|--------------------------------------|
| `:sdl.quit` | `[name=""]` (an empty string) | Poll phase, on `SDL_QUIT` (`pingus.h:857`); also sets `quit=1` | 1 (`main.atm:89`) |
| `:sdl.key.dn` | `[name=SDL_GetKeyName(sym)]` (`"Escape"`, `"Return"`, `"F5"`, `"Left"`, `"P"`, `"Space"`, ...); key repeats dropped | Poll phase (`pingus.h:862`); then scripted keys (`pingus.h:789`) | 13 (`game/game.atm:284`) |
| `:sdl.key.up` | `[name=...]` | Poll phase (`pingus.h:866`); scripted (`pingus.h:791`) | 2 (`game/game.atm:296`, `game/playfield.atm:101`) |
| `:sdl.mouse.motion` | `[x, y, but=0]` | Poll phase (`pingus.h:869`); scripted `mv` and before each scripted `dn` (`pingus.h:797,799`) | 17, of which 5 in `engine/engine.atm` (`game/hud.atm:46`) |
| `:sdl.mouse.dn` | `[x, y, but]` (`but` is SDL's: 1 left, 2 middle, 3 right) | Poll phase (`pingus.h:872`); scripted (`pingus.h:800`) | 9, 2 in engine (`game/playfield.atm:31`) |
| `:sdl.mouse.up` | `[x, y, but]` | Poll phase (`pingus.h:875`); scripted (`pingus.h:802`) | 6, 2 in engine (`game/hud.atm:113`) |
| a number (time) | `ms * 1000`, an integer in microseconds, emitted as a bare number | After input, once per frame, only if `ms > 0` (`pingus.h:887`) | as `:clock`: 11 `loop us on :clock` (`game/game.atm:96`); as timers: 2 (`await 1s` at `screens/options.atm:192`, `watching 1s` at `game/hud.atm:159`) |
| `:sdl.draw` | `[name=""]` | After the time, once per frame, after the clear (`pingus.h:894`) | 39: 4 in engine, 1 in `tst/engine.atm`, 34 in `game/` + `screens/` (`game/game.atm:138`) |

Not emitted: mouse wheel, text input, window events (resize, focus),
joystick/controller, touch. The game uses only keys by name, and the
mouse buttons 1 and 3.

Key names the game matches (all literals): `F5` (`main.atm:80`),
`Escape`, `Return`, `Space`, `P`, `F`, `Left`, `Right`, `Up`, `Down`
(`game/playfield.atm:94`), `S`, `A` (`game/game.atm:284-300`), and
the digits `0`-`9` through `tonumber(e.name)` (`game/hud.atm:61`).

Game-internal events (not from the layer, for contrast): `:tick`,
`:tock`, `:frame`, `:screens`, `:options`, `:go.options`, `:game.*`.

## 4. Main loop

`main` is `pingus.h:811-930`. Before the loop: init (section 1),
`atm_init(argc, argv)`, `st = atm_main()` (the whole top level of the
program runs here, with window and renderer already created).

One frame (`for frame=1; st==A_OK && !quit && atm_alive(); frame++`,
`pingus.h:850`):

1. `PG_FRAME = frame`; `t0 = SDL_GetTicks()`.
2. **Input**: `while SDL_PollEvent`: quit, key down (no repeats), key
   up, mouse motion, button down, button up, each emitted at once, in
   the order of SDL (`pingus.h:854-878`).
3. **Scripted input**: `pg_script("PINGUS_KEYS", frame)` then
   `pg_script("PINGUS_MOUSE", frame)` (`pingus.h:879-880`).
4. **Time**: `ms = fixed ? fixed : now - prv` (real elapsed
   milliseconds since the same point of the previous frame);
   if `ms > 0`, `atm_emit(a_int(ms*1000))` (`pingus.h:883-888`).
   Timers and `:clock` awake here: all the logic of the game runs in
   this emit and in the input emits.
5. **Draw**: `SDL_SetRenderDrawColor(0,0,0,255)`, `SDL_RenderClear`,
   emit `:sdl.draw`, `pg_script("PINGUS_SHOT", frame)`,
   `SDL_RenderPresent` (`pingus.h:891-897`).
6. **End or delay**: if `frames>0 && frame>=frames`, `quit=1`; else,
   if not fixed and `period>0`, `SDL_Delay(period - spent)` when the
   frame took less than the period (`pingus.h:899-906`).

Time:

- Real mode: variable dt, the measured milliseconds, passed in
  microseconds. A frame with 0 ms elapsed emits no time (possible
  with `PINGUS_FPS=0`).
- Test mode (`PINGUS_FRAMES=n:ms` with `ms>0`): fixed dt of `ms` per
  frame, no delay at all (runs as fast as possible).
- The game converts to its own world clock: `Clock`
  (`game/game.atm:92-119`) accumulates `us // 1000` and emits `:tick`
  + `:tock` per 20 ms (4 pairs per 20 ms in fast forward). World
  sprites advance 33 ms per tick (`engine.atm:218`).

Frame cap: 40 frames per second by default ("as the original",
`pingus.h:829`), `period = 1000/fps` = 25 ms (integer division);
`PINGUS_FPS=n` changes it, 0 removes the cap. The renderer is created
with flags 0: no vsync requested. The delay accounts for the time
spent in the frame (unlike `lib`, which always delays 16 ms).

Quit:

- `SDL_QUIT` emits `:sdl.quit` and sets `quit=1`: the loop ends at
  the end of this frame, whatever the program does (the rest of the
  frame still runs: scripted input, time, draw).
- `main.atm:89` awaits `:sdl.quit` as a branch of the top `par :any`,
  so the program also terminates by itself, and `atm_alive()` fails.
- The program ending (menu `:exit`, or a level played from the
  command line returning) ends the loop through `atm_alive()`.
- Any `st != A_OK` from an emit ends the loop.

Shutdown order (`pingus.h:909-929`):

1. `PINGUS_COUNT` set: `fprintf(stderr, "frames: %d\n", PG_FRAME)`;
2. `if (st == A_OK) st = atm_stop()`;
3. `fflush(stdout)`;
4. `A_ESCAPE` -> `a_escape_err()`; if not OK, `a_error_dump()`;
5. `atm_quit()`;
6. `pg_map_free()`; `pg_music_stop()`;
7. `Mix_CloseAudio()` if audio was open;
8. `SDL_Quit()`; exit code 0 if OK, else 1.

Not done at shutdown: the image table (surfaces and textures), font
glyph tables, cached `Mix_Chunk`s, renderer and window are never
destroyed explicitly; no `IMG_Quit`/`Mix_Quit`.

## 5. Test mode

Environment variables read by the layer (`pingus.h`):

| Variable | Format | Meaning | Read at |
|----------|--------|---------|---------|
| `PINGUS_FRAMES` | `n:ms` (`sscanf "%d:%d"`) | Run `n` frames, each of fixed `ms`; sets `PG_TEST=1` (even if malformed). With `ms=0` time is real | `pingus.h:824` |
| `PINGUS_KEYS` | `f:dn:Name,f:up:Name,...` | At frame `f`, emit `:sdl.key.dn`/`.up [name=Name]` | `pingus.h:787` |
| `PINGUS_MOUSE` | `f:mv:x:y`, `f:dn:x:y:b`, `f:up:x:y:b`, comma separated (`b` defaults to 1) | `mv`: motion; `dn`: motion **then** button down; `up`: button up only | `pingus.h:793-803` |
| `PINGUS_SHOT` | `f:path.png,...` | Save the screen at frame `f` | `pingus.h:785` |
| `PINGUS_MUTE` | any value | Audio is not opened; all sound functions become no-ops | `pingus.h:815` |
| `PINGUS_FPS` | integer | Frame cap; 0 = none; default 40 | `pingus.h:830` |
| `PINGUS_COUNT` | any value | Print `frames: N` to stderr at exit | `pingus.h:909` |

Read by the game, not by the layer (via `os.getenv`):

| Variable | Meaning | Where |
|----------|---------|-------|
| `PINGUS_TRACE` | `1`: print the trace; `2` (+ `PINGUS_TRACE_ID`): per-tick detail of one pingu | `game/game.atm:25`, `game/pingu/pingu.atm:191` |
| `PINGUS_ORDERS` | `tick:pingu:action,...`: give an action to a pingu at a world tick | `game/game.atm:35` |
| `PINGUS_HOME` | Directory of the save file `.pingus-atmos.atm` (else `$HOME`, else `/tmp`) | `screens/common.atm:71` |

Standard SDL variables set by the tests: `SDL_VIDEODRIVER=dummy`,
`SDL_AUDIODRIVER=dummy` (`tst/run.sh:23`). `PINGUS_BIN` is a variable
of the shell scripts only.

Scripted input (`pg_script`, `pingus.h:772-807`): each frame the
variable is re-read with `getenv` and split on `,`; an item whose
leading integer equals the frame number is executed. Items are copied
into a 256-byte buffer (longer items, e.g. long screenshot paths, are
truncated). Scripted events are emitted with the same `pg_emit` as
real ones, after the real events of the frame and before the time.
Frame numbers are 1-based. Several items may share a frame; they run
in the order written. Real SDL events are still polled in test mode.

Screenshots (`pg_shot`, `pingus.h:758-765`): at step 5 of the frame,
after `:sdl.draw` and before `SDL_RenderPresent`:
`SDL_GetRendererOutputSize`, `SDL_CreateRGBSurfaceWithFormat`
(RGBA32), `SDL_RenderReadPixels` of the whole target, `IMG_SavePNG`.
The result is an 800x600 8-bit RGBA PNG (`tst/shots/menu.png`). In
test mode `pg_display` neither resizes nor goes fullscreen
(`pingus.h:382`), so the size does not depend on the saved options.

Determinism besides fixed frames: `main.atm:28-32` seeds
`math.randomseed(0)` when `pg.testing()`.

A trace is text on stdout printed by the game, not by the layer:
one line per change of action of a pingu,
`"%5d pingu %2d %-9s %4d %4d"` = world tick, pingu id, action, x, y
(`game/game.atm:29`), plus prints such as `view 0 440` and the final
`saved a/b, killed c, needed d: solved|failed` (`main.atm:71`).

The runner `tst/run.sh` (builds once, then runs the binary):

- `check NAME FILE` compares with `cmp -s` against
  `tst/golden/NAME.out` (byte exact; stdout and stderr merged, so any
  warning or sanitizer report fails); on failure prints 10 lines of
  `diff`. `tst/run.sh update` copies the outputs over the goldens.
- Screenshots are compared with `cmp -s` against `tst/shots/*.png`:
  the PNG **files** must be byte identical (so also the PNG encoder
  of SDL_image, not only the pixels).
- `ASAN=1` builds with the address sanitizer.
- Levels run 4 at a time with `xargs -P 4` through `tst/play.sh`,
  which sets `PINGUS_TRACE=1`, `PINGUS_FRAMES="$2:25"`,
  `PINGUS_ORDERS`, and `PINGUS_KEYS="2:dn:Return,3:dn:F,..."`
  (start the level, fast forward).

Number of tests: **31 text outputs** in `tst/golden/` (`data`,
`engine`, `screens`, `clicks`, `worldmap`, `options`, and the 25
levels of `tst/levels.txt`) and **6 screenshots** in `tst/shots/`
(`menu`, `levelsets`, `start`, `game`, `options`, `overlay`): 37
comparisons. `tst/options.sh` also takes 6 `view-*.png` and compares
them with each other (results printed into `options.out`).
`tst/demos.sh` (replay of the demos of the original game) is not
part of `tst/run.sh`. `data` does not use SDL at all
(`tools/check.atm` does not include the engine).

All test runs use 25 ms frames (`:25`), the period of the 40 fps cap.

## 6. Resources

No resource is a native value: there is no `a_nat`, no finalizer, no
`pin`. Everything is a number indexing a static C table, or a path.

| Kind | Representation | Cache | Freed |
|------|----------------|-------|-------|
| Image | index into `PG_IMGS[4096]` (`pingus.h:56-58`): key string, RGBA32 `SDL_Surface` (kept for the masks of the ground), lazily created `SDL_Texture`, `w`, `h` | Linear `strcmp` search by key `path#mod#cx,cy,cw,ch` (`pingus.h:99-104`); a 4097th image returns -1 | Never (process exit). Both surface and texture stay alive |
| Font | index into `PG_FONTS[16]` (`pingus.h:224`); each has `malloc(65536 * sizeof(PgGlyph))` = 1 MB; glyphs reference image indices | By name in Atmos, `FONTS_CACHE` (`engine.atm:253`); 4 fonts created at include time (`engine.atm:274-279`) | Never |
| Sound | none at the Atmos side: played by path | Function-static table of 64 `{path, Mix_Chunk*}` (`pingus.h:332`); a 65th distinct path is silently not played | Never |
| Music | none: played by path | One current `Mix_Music*` + its path (`pingus.h:393-394`); same path = keep playing | On change, on `pg.music_stop()`, and at shutdown |
| Ground map | one global `PG_MAP` (`pingus.h:445`): collision bytes, RGBA32 surface, tile textures, dirty flags, minimap texture | - | `pg.map_free()` (`defer` in `game/game.atm:130-132`), at `pg.map_new`, and at shutdown |
| Sprite descriptions | Atmos tables in `DESCS` (`engine.atm:61`) | by resource name | Never (garbage of the program) |

Ownership is entirely the layer's; the program holds only numbers,
which stay valid until the process ends. A failed load returns -1
(`pg.img`), and drawing an invalid index is a silent no-op.

## 7. Rendering path

- One `SDL_Window` 800x600 (flags 0) and one `SDL_Renderer` created
  with `SDL_CreateRenderer(win, -1, 0)`: default driver, no
  `ACCELERATED`/`SOFTWARE`/`PRESENTVSYNC` flag. With
  `SDL_VIDEODRIVER=dummy` this is the software renderer; on a desktop
  it is whatever SDL picks.
- All drawing to the screen goes through the renderer:
  `SDL_RenderCopy` of textures, `SDL_RenderFillRect`/`DrawRect`/
  `DrawLine`. No render targets, no `SDL_RenderCopyEx`, no direct
  window surface.
- Software surfaces are used off screen: every image keeps its
  RGBA32 surface (`SDL_PIXELFORMAT_RGBA32`, byte order R,G,B,A;
  alpha read as byte `4*x + 3`, `pingus.h:525`); rotations/flips and
  crops are done on surfaces at load time; the ground image is a
  level-sized RGBA32 surface modified by `SDL_BlitSurface` (blend
  mode BLEND on the source) and by direct alpha writes.
- Textures: one static texture per image, created at its first draw
  (`pg_tex`, `pingus.h:144`), blend mode BLEND. Ground: one
  `SDL_TEXTUREACCESS_STREAMING` RGBA32 texture per 128x128 tile,
  created when first visible, re-uploaded with `SDL_UpdateTexture`
  when dirty (`pingus.h:665-676`). Minimap: one streaming texture.
- Text: bitmap glyphs, one `SDL_RenderCopy` per glyph from the font
  images. No SDL_ttf.
- Logical size: `SDL_RenderSetLogicalSize(800, 600)` is set only in
  `pg_display` (`pingus.h:381`), which the game calls at include time
  of `screens/options.atm` (line 39) and at each change of options
  (line 43). A program that never calls `pg.display`
  (`tst/engine.atm`) has no logical size. The game always draws in
  800x600 coordinates; SDL scales to the window and maps mouse
  coordinates back.
- The frame starts with a clear to opaque black; the program redraws
  everything at each `:sdl.draw`. Draw order is the order in which
  the tasks awake (the order of spawning), which the game relies on
  for layers (`main.atm:12-14`, `game/game.atm:135`).
- `pg_img_draw` culls against `PG_W`, `PG_H` (`pingus.h:161`).

Pixel exactness (the byte-identical PNGs of `tst/shots/`) depends
on: the software renderer of the SDL version in use and its blending
arithmetic; conversion of every image to RGBA32; `pg_int` truncating
coordinates toward zero (so do the `(int)` casts in `pg_font_draw`,
which accumulates `dx` in `float`); integer division in the Atmos
code (`//`); the minimap sampling `sx * m->w / w`; alpha via
`SDL_SetTextureAlphaMod`; default (nearest) scale quality, no hint
set; no scaling in tests (window = logical size); the 1:1 reading of
the back buffer before present; and the PNG encoder of SDL_image.
The traces depend on the 32-bit `float` arithmetic of `pg_move` and
`pg.f32`, on the fixed 25 ms frames, and on `math.randomseed(0)`.

## 8. Differences from `lang/lib/sdl.atm`

The layer says it "extends `lib/sdl.atm`" (`sdl.atm:3`), but it does
not include it: it is a separate rewrite that kept the structure of
its driver (`pg_script` and `main` follow `sdl_script` and `main` of
`lib:205-312` almost line by line) and its conventions for keys.

Kept (same behaviour): `SDL_Init` with fallback; `Mix_OpenAudio`
parameters; `:sdl.key.dn/up [name]` with `SDL_GetKeyName`, repeats
dropped; time as a number in microseconds; clear to black, emit
`:sdl.draw`, shot, present; the frame order input, script, time,
draw; `FRAMES=n:ms`, `KEYS`, `SHOT` formats; the sound cache of 64;
the shutdown sequence `atm_stop`, flush, error dump, `atm_quit`,
`Mix_CloseAudio`, `SDL_Quit`.

Changed:

| Aspect | `lib/sdl.atm` | Pingus layer |
|--------|---------------|--------------|
| C location | inline in the `:prelude` literal | separate header `engine/pingus.h`, needs `-I` |
| Table name | `sdl` | `pg` |
| Window | created by the program, `sdl.window [title,width,height]` (`lib:79`); default 640x480 | created in `main` before `atm_main`, fixed `"Pingus"` 800x600 |
| Images | `sdl.image(path)` -> native `sdl.texture` box with finalizer, or nil (`lib:93`); texture only | integer index, -1 on failure; cached by key; surface + lazy texture; crop and 8 modifiers at load |
| Drawing an image | `sdl.copy(tex, crop, rect)` with rectangle tables `[x,y,w,h]` | `pg.draw/part/scale` with scalar arguments, optional alpha |
| Color | state: `sdl.color(0xRRGGBB)`, opaque (`lib:121`) | per call: `0xRRGGBBAA`, alpha blended |
| Fill | `sdl.fill(rect)` table | `pg.fill(c, x,y,w,h)` scalars |
| Text | TTF: `sdl.font(path,size)` native box, `sdl.write` centered, a texture per call | bitmap fonts by index, origin left/center/right, multi-line, width query, alpha |
| Sound | `sdl.play(path)` | `pg.sound(path, vol)` with per-channel volume; 32 channels allocated |
| Events | `:sdl.quit` and `:sdl.draw` are the bare tag (`lib:186`); key events a tagged table | every event a tagged table; `:sdl.quit`/`:sdl.draw` carry `[name=""]` |
| Frame cap | `SDL_Delay(16)` after every frame, unconditional | 40 fps, compensated for the time spent; `PINGUS_FPS` |
| Draw without renderer | skipped if `SDL_REN==NULL` (window is optional) | renderer always exists |
| Env prefix | `SDL_ATM_` | `PINGUS_` |
| Libraries | `-lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer` | no `-lSDL2_ttf`, plus `-lm` |

Added: mouse events (`:sdl.mouse.motion/dn/up`); `PINGUS_MOUSE`
scripting; `PINGUS_MUTE`, `PINGUS_FPS`, `PINGUS_COUNT`; `pg.frame`,
`pg.testing`; `pg.rect`, `pg.line`; `pg.scale`; alpha on parts;
`pg.music`, `pg.music_stop`, `pg.volume`; `pg.display` (logical
size, fullscreen, window size, grab, cursor); bitmap fonts; the
ground maps, the mover and `pg.f32`; constants `W`, `H`, `GP`, `MOD`.

Removed (present in `lib`, absent here): `sdl.window`; native
texture/font values and their finalizers (`lib:39-43`); `sdl.font`,
`sdl.write` and all of SDL_ttf (`TTF_Init`/`TTF_Quit`); `sdl.color`;
`sdl.pct_to_pos` (`lib:363`); `sdl.rect_vs_rect` (`lib:370`); the
table helpers `sdl_fld`, `sdl_str`, `sdl_rect` (`lib:46-77`).

## 9. Oddities and risks for a shared environment

1. **Game logic in the platform header.** About 300 of the 930 lines
   of `pingus.h` (421-726) are the ground maps, the mover and the
   minimap: game logic (`G`) that needs `PG_REN`, `PG_W`, `PG_H`,
   `pg_img(i)->sfc` (the RGBA32 surface of an image, read per pixel)
   and the blend/format conventions. If the environment is shared,
   this C must live in the game and reach the renderer and the
   surface of an image by index from outside the environment. It is
   also the performance-sensitive part (per-pixel loops over masks,
   128x128 tile uploads, `pg_move` called per pingu per tick).
2. **Images must keep their surface.** `pg_map_put/col/remove` read
   the alpha of image surfaces; a texture-only image (as `lib`)
   cannot serve them. Opacity is tested as alpha `== 255` exactly.
3. **Integer ids instead of values.** The game stores image and font
   indices in tables and compares/tests them as numbers
   (`pg.img(...) < 0` at `engine.atm:85`; `c ?? :number` at
   `engine.atm:257`). Nothing is ever freed, so nothing is pinned.
   Moving to native boxes with finalizers changes lifetimes; the
   image cache makes `pg.img` cheap to call repeatedly, which
   `engine.atm` relies on (`look`, `res_frame_size` call it at each
   sprite creation).
4. **Hard limits, silent failure.** 4096 images, 16 fonts (1 MB of
   glyph table each), 64 sounds, 32 channels, 256 bytes per script
   item, 1024 bytes per image key. Exceeding them returns -1 or does
   nothing, with no message. The image cache is a linear `strcmp`
   scan on every `pg.img`.
5. **Global state.** `PG_WIN`, `PG_REN`, `PG_W/H`, `PG_SND`,
   `PG_TEST`, `PG_FRAME`, `PG_IMGS`, `PG_FONTS`, `PG_SND_VOL`,
   `PG_MUS`, `PG_MAP` (a single level at a time), `PG_MX/PG_MY`
   (results of `pg.move` returned through globals read by two later
   literals, `sdl.atm:133-134`). All `static` in a header included
   once.
6. **Window before the program.** The window and renderer exist
   before `atm_main`, with a fixed title and size; top-level code of
   the game loads fonts and applies options at include time
   (`engine.atm:274`, `screens/options.atm:39`). `lib` creates the
   window on request from the program instead.
7. **Size duplicated.** 800x600 is in C (`PG_W`, `PG_H`) and in
   Atmos (`W`, `H`), not derived from one another.
8. **Logical size only via `pg.display`.** See section 7; a program
   that does not call it gets no scaling. In test mode `pg.display`
   still sets grab and cursor state but skips size and fullscreen.
9. **Event payloads.** `:sdl.draw` and `:sdl.quit` carry a table with
   `name=""`, an accident of `pg_emit`'s signature; a table is
   allocated for `:sdl.draw` every frame. Motion events carry
   `but=0`. A scripted `dn` emits a motion first; a scripted `up`
   does not. No awaiting code reads `name` of draw/quit.
10. **Order of drawing is the order of tasks.** 39 independent
    `on :sdl.draw` loops; layering relies on spawn order and on the
    overlay being the last branch of `main.atm`. Any environment
    must keep one broadcast `:sdl.draw` per frame after the time.
11. **Time semantics the game depends on.** One time emit per frame,
    after all input of that frame; dt in microseconds; fixed 25 ms
    in tests; 40 fps cap otherwise. The goldens were recorded with
    this exact order (input, scripted keys, scripted mouse, time,
    draw, shot). Scripted frame numbers are 1-based.
12. **Quit is forced.** `SDL_QUIT` ends the loop even if the program
    ignores `:sdl.quit`.
13. **Audio volume interplay.** `pg_volume` sets all channels with
    `Mix_Volume(-1)`, and each `pg_sound` then sets the volume of
    its channel to `volume * PG_SND_VOL`; a sound already playing
    keeps the channel volume of the last global change.
    `PG_SND_VOL` is a tentative definition used before its
    initializer (`pingus.h:330` and `:368`): valid C, not C++.
    `pg_display` sits in the middle of the audio code
    (`pingus.h:380`, between `pg_volume` and `pg_music_stop`).
14. **`PINGUS_MUTE` and missing audio** make all sound functions
    no-ops; the tests always run muted, so audio has no test.
15. **GCC extensions in literals.** `pg.size` uses statement
    expressions `({ ... })` and reaches into the struct `PgImg`
    (`sdl.atm:45-46`), as `lib:364-365` does for the output size.
16. **Leaks by design.** Images, fonts and chunks are never
    released; `tst/run.sh` with `ASAN=1` passes only because they
    stay reachable from statics. The renderer and window are not
    destroyed before `SDL_Quit`.
17. **Unused surface.** `pg.scale`, `pg.frame`, `task Image` and the
    Atmos table `MOD` outside the engine have no caller; `MOD` is
    indexed by the tag of the data files in `res_surface`
    (`engine.atm:119`).
18. **Screenshots are compared as files**, not as pixels, and read
    `SDL_GetRendererOutputSize` (the real output, not the logical
    size). A shared environment that changes the renderer flags, the
    pixel format of the read-back, or the PNG writer invalidates the
    6 shots even with identical pixels.
19. **Paths relative to the working directory.** `run.sh` does `cd`
    to the root of the game; data paths (`"data/..."`) and the
    `#include "engine/pingus.h"` (through `-I$ROOT`) depend on it.
20. **No C in the game proper.** All native code is behind `pg`, in
    one file; the game and screens are pure Atmos. The boundary to
    cut is therefore `engine/sdl.atm` + `engine/pingus.h`, with
    `engine/engine.atm` as the only heavy client of images, fonts
    and audio (`pg.img`, `pg.font_*`, `pg.sound`, `pg.music*` are
    called nowhere else).
