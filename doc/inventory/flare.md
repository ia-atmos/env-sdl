# Inventory: the SDL2 layer of `sdl-flare`

The platform layer of the port of Flare to Atmos, as found in
`/home/user/sdl-flare` at commit `f301ff3` (read on 2026-11-14).
Only a record: what the layer offers, and what the game uses.
References are `file:line` relative to that repository. Counts are
by `grep` of `fl.<name>` and are split in **game** (`src/*.atm` and
`main.atm`) and **tst** (`tst/*.atm` and `tools/*.atm`).

Classes: `P-common` (platform, plausibly of any game), `P-game`
(platform, but shaped by this game), `G` (game logic).

## 1. Files and build

| File | Lines | Contents |
|------|------:|----------|
| `engine/flare.h` | 670 | C: globals, random, dir listing, trace, images, fill, fonts, sounds, music, input state, scripted input, `main` (the loop) |
| `engine/engine.atm` | 323 | Atmos: the prelude `#include "engine/flare.h"`, the tables `Input`, `MOVE`, `COLLIDE`, the table `fl` (73 entries), the task `Frames` |
| `engine/map.h` | 676 | G: tileset, layers, camera, isometric render of tiles and objects |
| `engine/collision.h` | 256 | G: `MapCollision` (valid positions, move, slide, line of sight) |
| `engine/geom.h` | 117 | G: directions, distances, vectors in 32-bit floats |
| `engine/astar.h` | 226 | G: path finding |

- `flare.h` includes the other four headers in its middle
  (`flare.h:337-340`), after images/sounds and before the input and
  the driver, so they see `fl_img_draw`, `fl_fill`, `fl_rand`,
  `FL_W`, `FL_H`. Everything is `static` in one translation unit.
- The game includes the layer with `include "engine/engine.atm"`
  (`main.atm:7`); the tests with `include "../engine/engine.atm"`
  (`tst/engine.atm:7`, `anim`, `font`, `map`, `power`;
  `tools/anim-dump.atm:6`). `tst/ini.atm`, `tst/parse.atm` and
  `tools/ini-dump.atm` do not include it: they run on the default
  environment of Atmos (`lang/rt/main.c`).
- The prelude defines `int main` (`flare.h:522`), which replaces
  the default driver of the runtime.
- Runner: `run.sh` (33 lines). It finds the compiler (`$ATMOS`,
  `../lang/atmos`, `../ceu-atmos/atmos`, or `atmos`), exports
  `FLARE_DATA` (default `../flare-orig/data`), and sets
  (`run.sh:30-31`):
  - `ATMOS_CFLAGS="${ATMOS_CFLAGS:--O2} -I$ROOT"` (the `-I` is what
    makes `#include "engine/flare.h"` resolve);
  - `ATMOS_LDFLAGS="-lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf -lm"`;
  - then `cd $ROOT && exec $ATMOS <file> <args>` (the program must
    run from the root). `ATMOS_ASAN=1` builds with the sanitizer
    (the tests then use `-O1 -g`, `tst/run.sh:29`).
- System headers used by the layer: `stdio stdlib string stdint
  time dirent` and `SDL.h`, `SDL_image.h`, `SDL_mixer.h`,
  `SDL_ttf.h` (`flare.h:41-50`); `math.h` (`map.h:11`); `float.h`
  (`astar.h:7`). SDL2 here is 2.30.0.
- No setup call from Atmos: the window, audio and TTF are created
  in `main` before `atm_init`, with fixed values. There is no
  `fl.window`.

## 2. Functions

### 2.1 The table `fl` (`engine/engine.atm:26-316`)

All arguments cross as numbers or strings (`fl_int`, `fl_cstr`,
`a_dbl`); handles are indices (`-1`: failure). "tst" examples are
given when the game has no call.

Platform:

| Name | Signature | Purpose | SDL calls behind | game | tst | Example | Class |
|------|-----------|---------|------------------|-----:|----:|---------|-------|
| `fl.W`, `fl.H` | numbers (1706, 960), read once when the table is built | size of the render | none (`FL_W`, `FL_H`) | 0 | 1 | `tst/engine.atm:12` | P-common; unused by the game as `fl.W` (but `FL_W`/`FL_H` are read in C: 2.3) |
| `fl.frame` | `() -> n` | logic frames done (`FL_FRAME`) | none | 0 | 1 | `tst/anim.atm:31` | P-common; unused by the game |
| `fl.FPS` | number 60 | logic rate | none | 0 | 0 | | P-game; **unused** |
| `fl.rand` | `() -> int` in 0..2^31-1 | LCG of the patched original, seed `FLARE_SEED` | none | 28 | 3 | `src/loot.atm:139` | P-game (determinism against the original) |
| `fl.rand_calls` | `() -> n`, then resets | calls to the generator since the last count | none | 1 | 0 | `src/play.atm:67` | P-game (debug of the trace) |
| `fl.dir` | `(path, ext) -> vector of names or nil` | files of a directory ending in `ext`, in `readdir` order | none (`opendir`) | 1 | 0 | `src/enemy.atm:21` | P-game (OS, not SDL) |
| `fl.trace` | `(s)` | a line `<frame> <s>` in the trace, if open | none | 13 | 3 | `src/loot.atm:104` | P-game (test mode) |
| `fl.tracing` | `() -> bool` | the trace is open | none | 1 | 0 | `src/play.atm:26` | P-game |
| `fl.img` | `(path [,raw]) -> index or -1` | load an image, cached by (path, raw); `raw` keeps the format of `IMG_Load` | `IMG_Load`, `SDL_ConvertSurfaceFormat(ARGB8888)`, `SDL_FreeSurface` | 2 | 2 | `src/map.atm:34`, `src/anim.atm:213` (raw) | P-common (the `raw` flag is P-game) |
| `fl.size` | `(img) -> w, h` | size of an image (0,0 if invalid) | none | 0 | 1 | `tst/engine.atm:16` | P-common; unused by the game |
| `fl.draw` | `(img, x, y)` | whole image at x,y | via `fl_img_draw` | 0 | 1 | `tst/engine.atm:42` | P-common; unused by the game |
| `fl.part` | `(img, sx,sy,sw,sh, x,y [,alpha [,color [,blend]]])` | a region at x,y, same size; alpha 0..255, color mod 0xRRGGBB, blend 0 normal / 1 add | `SDL_SetSurfaceBlendMode`, `SDL_SetSurfaceColorMod`, `SDL_SetSurfaceAlphaMod`, `SDL_BlitSurface` | 0 | 2 | `tst/engine.atm:41` | P-common; unused by the game from Atmos (all game draws go through `fl.ren` and C) |
| `fl.fill` | `(0xRRGGBBAA, x,y,w,h)` | rectangle, no blending (alpha is written) | `SDL_FillRect`, `SDL_MapRGBA` | 0 | 1 | `tst/engine.atm:43` | P-common; unused by the game from Atmos (C: `map.h:638`) |
| `fl.font` | `(path, size [,style]) -> index or -1` | open a TTF; style bits 1 bold, 2 italic, 4 underline | `TTF_OpenFont`, `TTF_SetFontStyle` | 1 | 1 | `src/font.atm:56` | P-common |
| `fl.text` | `(font, s, x, y [,color [,justify [,blend]]])` | UTF-8 text; justify 0 left, 1 right, 2 center; blend `false` = solid, else blended; blitted twice | `TTF_RenderUTF8_Blended` or `TTF_RenderUTF8_Solid`, `SDL_BlitSurface` x2, `SDL_FreeSurface` | 3 | 1 | `src/font.atm:83` | P-common (the double blit is P-game) |
| `fl.text_width` | `(font, s) -> w` | width of a text | `TTF_SizeUTF8` | 1 | 1 | `src/font.atm:93` | P-common |
| `fl.text_height` | `(font) -> h` | line skip of a font | `TTF_FontLineSkip` | 1 | 1 | `src/font.atm:59` | P-common |
| `fl.snd` | `(path) -> index or -1` | load a sound, cached by path; -1 with no audio | `Mix_LoadWAV` | 1 | 3 | `src/hero.atm:138` | P-common |
| `fl.play` | `(snd [,vol])` | play once on a free channel; volume 0..128 (default 128) | `Mix_PlayChannel(-1,..,0)`, `Mix_Volume` | 1 | 1 | `src/hero.atm:243` | P-common |
| `fl.music` | `(path)` | stop the current music, load, loop forever | `Mix_HaltMusic`, `Mix_FreeMusic`, `Mix_LoadMUS`, `Mix_PlayMusic(-1)` | 0 | 0 | | P-common; **unused** |
| `fl.music_stop` | `()` | stop and free the music | `Mix_HaltMusic`, `Mix_FreeMusic` | 0 | 0 | | P-common; **unused** from Atmos (C: `flare.h:663`) |
| `fl.pressing` | `(action) -> bool` | the action is held | none (`FL_PRESSING`) | 0 | 0 | | P-game; **unused** |
| `fl.locked` | `(action) -> bool` | the action is locked | none (`FL_LOCK`) | 0 | 0 | | P-game; **unused** |
| `fl.lock` | `(action, bool)` | lock/unlock an action until its release | none | 1 | 0 | `src/event.atm:305` | P-game (`InputState` of Flare) |
| `fl.pressed` | `(action) -> bool` | held and not locked | none | 15 | 0 | `src/play.atm:114` | P-game |
| `fl.mouse` | `() -> x, y` | last mouse position, in render coordinates | none (`FL_MOUSE_X/Y`) | 3 | 0 | `src/play.atm:90` | P-common |
| `fl.f32` | `(x) -> x` rounded to a C `float` | 32-bit float arithmetic of the original | none | 91 | 0 | `src/loot.atm:104` | G (numeric fidelity; no platform) |

Game side in C (class G), exposed through `fl`:

| Name | Signature | Purpose | SDL | game | tst | Example |
|------|-----------|---------|-----|-----:|----:|---------|
| `fl.tset_reset` | `()` | free the tileset | none | 1 | 0 | `src/map.atm:22` |
| `fl.tset_tile` | `(i, img, x,y,w,h, ox,oy)` | define a tile as a clip of an image index | none | 1 | 0 | `src/map.atm:38` |
| `fl.tset_anim` | `(i, x, y, dur)` | add a frame of a tile animation | none | 1 | 0 | `src/map.atm:48` |
| `fl.tset_done` | `()` | compute the max tile sizes | none | 1 | 0 | `src/map.atm:55` |
| `fl.tset_logic` | `()` | advance tile animations one logic frame | none | 2 | 1 | `src/play.atm:238` |
| `fl.map_new` | `(w, h)` | free the map, start a new one | none | 1 | 0 | `src/map.atm:86` |
| `fl.map_layer` | `(name) -> index` | new layer | none | 1 | 0 | `src/map.atm:95` |
| `fl.map_row` | `(layer, y, csv) -> bool` | a row of a layer, parsed in C | none | 1 | 0 | `src/map.atm:101` |
| `fl.map_done` | `(bg)` | sets `FL_BG` (0xRRGGBBAA), splits the collision layer | none | 1 | 0 | `src/map.atm:109` |
| `fl.map_mod` | `(layer, x, y, tile)` | change one tile | none | 1 | 0 | `src/event.atm:192` |
| `fl.hotspot_hit` | `(x, y, mx, my) -> bool` | mouse over a tile of (x,y) | none | 1 | 0 | `src/event.atm:292` |
| `fl.map_render` | `()` | background, layers, sorted objects | **yes**: `fl_fill` (`map.h:638`), `fl_img_draw` (`map.h:411`, `419`) | 1 | 1 | `src/play.atm:331` |
| `fl.ren_clear` | `()` | empty the object lists | none | 1 | 1 | `src/play.atm:332` |
| `fl.ren` | `(dead, img, sx,sy,sw,sh, ox,oy, mx,my, prio, hero [,alpha, color, blend])` | queue an object (clip of an image at a map position) for `map_render` | none (drawn later) | 3 | 0 | `src/play.atm:252` |
| `fl.cam_warp` | `(x, y)` | camera jumps | none | 1 | 1 | `src/play.atm:212` |
| `fl.cam_target` | `(x, y)` | camera target | none | 1 | 0 | `src/hero.atm:390` |
| `fl.cam_shake` | `(frames)` | sets `FL_SHAKE_TIMER` | none | 2 | 0 | `src/combat.atm:358` |
| `fl.cam_logic` | `()` | camera step (draws from `fl_rand` when shaking) | none | 2 | 1 | `src/play.atm:239` |
| `fl.cam` | `() -> x, y` | camera position | none | 2 | 0 | `src/play.atm:76` |
| `fl.map2scr` | `(x, y, cx, cy) -> sx, sy` | map to screen; uses `FL_W`, `FL_H` | none | 1 | 0 | `src/play.atm:77` |
| `fl.scr2map` | `(x, y) -> mx, my` | screen to map at the camera | none | 1 | 0 | `src/play.atm:121` |
| `fl.col_block` | `(x, y, ally)` | mark a tile as occupied | none | 9 | 0 | `src/ai.atm:385` |
| `fl.col_unblock` | `(x, y)` | unmark | none | 7 | 0 | `src/ai.atm:301` |
| `fl.col_outside` | `(x, y) -> bool` | outside the map | none | 1 | 0 | `src/play.atm:251` |
| `fl.col_valid` | `(x, y, mt, ct) -> bool` | valid position | none | 12 | 0 | `src/loot.atm:92` |
| `fl.col_sight` | `(x1,y1,x2,y2) -> bool` | line of sight | none | 1 | 0 | `src/ai.atm:115` |
| `fl.move` | `(x, y, dir, speed, eff, mt, hero) -> ok, x, y` | entity move with sliding | none | 2 | 0 | `src/ai.atm:83` |
| `fl.line_move` | `(x1,y1,x2,y2, mt) -> bool` | free line of movement | none | 2 | 0 | `src/ai.atm:71` |
| `fl.path` | `(sx,sy,ex,ey, mt) -> vector of [x,y]` | A* path, end to start | none | 1 | 0 | `src/ai.atm:335` |
| `fl.direction` | `(x0,y0,x1,y1) -> dir` | 8-way direction | none | 6 | 0 | `src/ai.atm:171` |
| `fl.dist` | `(x1,y1,x2,y2) -> d` | distance (float) | none | 10 | 0 | `src/ai.atm:104` |
| `fl.vector` | `(x, y, dir, d) -> x, y` | point at a distance | none | 6 | 0 | `src/ai.atm:175` |
| `fl.real_speed` | `(speed, dir, eff) -> s` | speed by direction | none | 1 | 0 | `src/ai.atm:293` |
| `fl.clamp_dist` | `(rmin, rmax, sx,sy, tx,ty) -> x, y` | clamp a target to a range | none | 5 | 0 | `src/combat.atm:121` |
| `fl.random_neighbor` | `(x, y, range, mt, ct) -> x, y` | free tile around (draws from `fl_rand`) | none | 5 | 0 | `src/loot.atm:93` |
| `fl.theta` | `(x1,y1,x2,y2) -> angle` | angle | none | 2 | 0 | `src/combat.atm:172` |
| `fl.missile_speed` | `(base, angle) -> sx, sy` | missile step | none | 1 | 0 | `src/combat.atm:183` |
| `fl.repeater_speed` | `(speed, theta) -> sx, sy` | repeater step (has the literal `60.f / 60.f`) | none | 1 | 0 | `src/combat.atm:199` |
| `fl.rotate` | `(dir, v) -> dir` | rotate a direction | none | 1 | 0 | `src/ai.atm:174` |
| `fl.face_next` | `(dir, x,y, mx,my) -> dir` | turn towards a point | none | 2 | 0 | `src/ai.atm:236` |

Total uses of `fl.<x>` in the game: 216 (by file: `combat` 55,
`play` 43, `ai` 41, `hero` 20, `event` 15, `enemy` 13, `map` 9,
`font` 6, `anim` 5, `loot` 5, `effect` 3, `power` 1).

### 2.2 Other names of `engine/engine.atm`

| Name | What | game | tst | Example | Class |
|------|------|-----:|----:|---------|-------|
| `Input` (`engine.atm:13-20`) | action numbers, a subset (29 of 46) of the C enum `FL_*` (`flare.h:347-357`) | 17 uses: `MAIN1` 4, `UP`/`DOWN`/`LEFT`/`RIGHT` 2 each, `MAIN2` 1, `AIM_*` 1 each | 0 | `src/play.atm:113` | P-game |
| `MOVE` (`engine.atm:23`) | `NORMAL`, `FLYING`, `INTANGIBLE` | 21 | 0 | `src/loot.atm:92` | G |
| `COLLIDE` (`engine.atm:24`) | `NONE`, `ALL`, `HERO`, `HAZARD` | 17 (`HERO` unused) | 0 | `src/loot.atm:92` | G |
| task `Frames (n)` (`engine.atm:319`) | awaits n `:frame` | 0 | 1 | `tst/engine.atm:34` | P-common; unused by the game |

### 2.3 C names used directly by the game (outside the layer)

| C name | Where it is used | Class |
|--------|------------------|-------|
| `FL_W`, `FL_H` | `src/ai.atm:51` (a native literal computes `ENCOUNTER_DIST`); `map.h:333,343,447,448,488,489,638` | P-common (size of the render, needed from C) |
| `fl_rand()` | `src/combat.atm:69`, `src/enemy.atm:67` (native literals, in float arithmetic); `map.h:321,322`; `geom.h:106` | P-game |
| `fl_img_draw(i, sx,sy,sw,sh, dx,dy, alpha, color, blend)` | `map.h:411` (tiles), `map.h:419` (objects) | P-common: the C door to draw an image handle |
| `fl_fill(rgba, x,y,w,h)` | `map.h:638` (background) | P-common |
| `M_PI`, `roundf`, `floorf`, `sqrtf`, `powf` | `src/combat.atm:61,177,180`, `src/parse.atm:83`, `src/ai.atm:51` | G (libm, `-lm`) |
| `fl_toint`, `fl_tofloat` | defined in a prelude of `src/parse.atm:15-29`, used at `:52`, `:57` | G (not in the layer; shares the `fl_` prefix) |
| runtime API | `AVal`, `a_isnum`, `a_dbl`, `A_STR`, `A_STR_OF`, `a_nil`, `a_tab`, `a_strz`, `a_int`, `a_setindex`, `a_setindex_next`, `a_tag`, `a_dec`, `atm_init`, `atm_main`, `atm_alive`, `atm_emit`, `atm_stop`, `atm_quit`, `a_escape_err`, `a_error_dump` | |

C helpers internal to `flare.h`: `fl_int`, `fl_cstr`, `fl_env`,
`fl_img` (index to `FlImg*`), `fl_input_frame`, `fl_input_key`,
`fl_input_mouse`, `fl_emit`, `fl_shot`, `fl_script`. `fl_field`
(`flare.h:430`) is defined and never called.

`collision.h`, `geom.h`, `astar.h` call no SDL and touch no SDL
object; their only tie to the layer is `fl_rand` (`geom.h:106`).
`map.h` calls no `SDL_*` function directly either: it draws only
through `fl_img_draw` and `fl_fill`, and reads `FL_W`/`FL_H`.

Native literal forms the layer relies on: `:prelude`, `:number`,
`:number.float`, `:boolean`, `:value`, plain statements, `$var`,
and GNU statement expressions `({ ... })` (`engine.atm:69`).
Functions with two results evaluate the C function once per result
(`engine.atm:237-238`), except where it has an effect
(`random_neighbor` stores in `FL_MOVE_X/Y`, `engine.atm:271`).

## 3. Events

Every event is a tagged table built by `fl_emit` (`flare.h:440`);
the payload is positional (`e@0`, `e@1`, `e@2`), not named. The tags
have no prefix. Order within one frame is the order of the table.

| Tag | Payload | When | Awaited by the game | Awaited by tests |
|-----|---------|------|---------------------|------------------|
| `:key.dn` | `@0` SDL **scancode** name | real: in the poll loop, not on repeats (`flare.h:583-588`); scripted: after the real events (`flare.h:510`) | 0 | caught by `loop e on true` + `e ?? :key`, `tst/engine.atm:23-25` |
| `:key.up` | `@0` scancode name | same (`flare.h:589-592`, `513`) | 0 | same |
| `:mouse.motion` | `@0` x, `@1` y (render coordinates) | poll loop (`flare.h:594-598`); scripted `move` (`:501`) | 0 | `e ?? :mouse`, `tst/engine.atm:25` |
| `:mouse.dn` | `@0` x, `@1` y, `@2` button (1 left, 3 right, SDL numbers) | poll loop (`flare.h:599-603`); scripted `down` (`:504`) | 0 | same |
| `:mouse.up` | `@0` x, `@1` y, `@2` button | poll loop (`flare.h:604-608`); scripted `up` (`:507`) | 0 | same |
| `:quit` | none (empty tagged table) | `SDL_QUIT` (`flare.h:580`) or scripted `quit` (`:515`); the loop then ends | 0 | 0 |
| `:frame` | `@0` n, the logic frame, from 0 | once per iteration, after all input, unless quitting (`flare.h:616-624`) | 6: `src/play.atm:267`, `:314`, `src/anim.atm:330,333,336,339` | `tst/anim.atm:30`, `tst/map.atm:23`, `engine.atm:321` (`Frames`) |
| `:draw` | none | once per iteration, after `:frame`, after the screen is cleared to opaque black (`flare.h:632-633`) | 2: `src/play.atm:246`, `:325` | 4: `tst/engine.atm:39`, `tst/anim.atm:36`, `tst/font.atm:23`, `tst/map.atm:28` |

- The game awaits no input event. It polls the state the layer
  keeps: `fl.pressed` (15), `fl.lock` (1), `fl.mouse` (3). The key
  and mouse events exist only for `tst/engine.atm`.
- No time event: the layer never emits a number, so `await 1s`
  and `:clock` never fire under this layer.
- Nothing else of SDL is handled: no window, text input, wheel,
  controller, or touch events.
- No event carries the frame or the time except `:frame`.

## 4. The main loop (`flare.h:522-670`)

Start, in order: `SDL_Init(VIDEO [|AUDIO])` (retry with video only
on failure); `Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)`
and `Mix_AllocateChannels(128)` unless `FLARE_MUTE`; `TTF_Init`;
the environment variables; `SDL_CreateWindow("Flare", centered,
1280x720, flags 0)`; `SDL_CreateRenderer(win, -1, 0)` (exit 1 on
failure); the screen surface and the streaming texture, both
1706x960 ARGB8888; `atm_init`; `atm_main`. So the main chunk
(all loading: `main.atm:23-30`) runs with the window open and with
`FL_FRAME == 0`.

One iteration, while `st == A_OK && !quit && atm_alive()`:

1. `t0 = SDL_GetTicks()`.
2. `fl_input_frame()`: actions released in the previous frame
   leave `PRESSING` and `LOCK` (`flare.h:388`).
3. `SDL_PollEvent` until empty: updates the action state and the
   mouse position, and emits `:quit`, `:key.*`, `:mouse.*`. A
   repeat of a key updates the state but emits nothing. After
   `SDL_QUIT` the remaining events are still handled.
4. Scripted input due at this frame (`fl_script`), unless quitting.
5. `:frame [FL_FRAME]`, then `FL_FRAME++`; if `FLARE_FRAMES` is
   reached, `quit = 1`. Skipped when quitting.
6. `SDL_FillRect(screen, opaque black)`; `:draw`; the screenshot
   if `FL_FRAME == shot`; `SDL_UpdateTexture`; `SDL_RenderClear`;
   `SDL_RenderCopy(tex, NULL, NULL)`; `SDL_RenderPresent`. This
   step only needs `st == A_OK`: the last iteration (quit or
   `FLARE_FRAMES`) still emits `:draw` and presents.
7. Unless `FLARE_FAST`: `SDL_Delay(period - spent)` with
   `period = 1000 / 60 = 16` ms (integer), i.e. a cap near 62.5
   iterations per second, not 60. No vsync flag.

- Time: there is no dt. One iteration is exactly one logic frame
  and one draw. The game counts frames (durations are converted to
  frames at 60 per second in `src/parse.atm:83`); a slow machine
  slows the game, with no catch-up and no frame skipping.
- Quit: `:quit` is emitted, then the loop ends by the flag `quit`;
  the program cannot refuse. The loop also ends when the main chunk
  terminates (`atm_alive`), or on an error status.
- Shutdown order (`flare.h:651-669`): `atm_stop()` if ok;
  `fflush(stdout)`; `A_ESCAPE` becomes an error (`a_escape_err`);
  `a_error_dump()` on error; `fprintf(stderr, "flare: frames
  %lu\n")` (always; the tests filter it or store it);
  `atm_quit()`; `fl_music_stop()`; `Mix_CloseAudio()` if open;
  `TTF_Quit()`; `SDL_Quit()`; exit code 0 or 1.
- Not released: images, sounds, fonts (`TTF_Quit` runs with fonts
  open), the texture, the surface, the renderer, the window, the
  trace file. No `IMG_Init`/`IMG_Quit`, no `Mix_Init`/`Mix_Quit`.

## 5. Test mode

Variables read by the layer (`fl_env`: an empty value counts as
unset, `flare.h:70`):

| Variable | Format | Meaning | Where |
|----------|--------|---------|-------|
| `FLARE_SEED` | decimal, 64 bits | seed of `fl_rand`; default `time(NULL)` | `flare.h:534` |
| `FLARE_FAST` | any | no delay at the end of the frame | `flare.h:543`, `643` |
| `FLARE_FRAMES` | n | quit after n logic frames (0/unset: never) | `flare.h:542`, `625` |
| `FLARE_INPUT` | file path | scripted input | `flare.h:539` |
| `FLARE_TRACE` | file path, or `-` for stdout | opens the trace | `flare.h:536` |
| `FLARE_SHOT` | `n:path` | one screenshot | `flare.h:546-550`, `634` |
| `FLARE_MUTE` | any | no `SDL_INIT_AUDIO`, no mixer; `fl.snd` returns -1 | `flare.h:523` |

Variables read by the game or the scripts, not by the layer:
`FLARE_DATA` (`run.sh:25`, `main.atm:23`), `FLARE_MAP`,
`FLARE_POS` (`main.atm:32-40`), `FLARE_DUMP`, `FLARE_DUMPE`,
`FLARE_RNG` (`src/play.atm:58-66`), `FLARE_NOHERO`
(`src/play.atm:328`); `SDL_VIDEODRIVER=dummy`,
`SDL_AUDIODRIVER=dummy` (`tst/run.sh:28`); `ATMOS`, `ATMOS_ASAN`,
`ATMOS_CFLAGS`, `ASAN`, `SKIP`, `UPDATE`.

Scripted input (`fl_script`, `flare.h:474-520`). One command per
line, at most 255 bytes; lines starting with `#` and empty lines
are skipped; a line is due when its frame is `<= FL_FRAME`, and is
delivered before `:frame` of that frame:

    <frame> move <x> <y>      :mouse.motion, sets the mouse position
    <frame> down <b>          :mouse.dn at the scripted position
    <frame> up <b>            :mouse.up
    <frame> key <name>        :key.dn; name is an SDL scancode name
    <frame> keyup <name>      :key.up
    <frame> quit              :quit, and the loop ends

- A scripted command does both things a real event does: it
  updates the polled state (`fl_input_key`, `fl_input_mouse`) and
  emits the event. No `SDL_PushEvent`.
- Scripted mouse coordinates are render coordinates (not scaled);
  real ones are window coordinates times `FL_SCALE` (960/720).
- The name is read with `%63s`: a scancode name with a space
  (`Left Shift`, `Page Down`) cannot be scripted. The name goes
  through `SDL_GetScancodeFromName`, and is emitted as written.
- The first line of the `.in` files of `tst/orig` is `# env:
  VAR=.. VAR=..`: `tools/compare.sh:22` passes it to `env`.

Screenshots: `SDL_SaveBMP` of the screen surface (the 1706x960
ARGB8888 software render, before the texture and the window), once,
in the iteration where `FL_FRAME == n` after the increment: after
the `:draw` that follows `:frame [n-1]`. `n` must be `<=
FLARE_FRAMES`. The tests compare the `md5sum` of the file
(`tst/run.sh:56,62,68,77`), so the bytes of the BMP writer of SDL
are part of the expected output; `tools/compare-shot.sh` compares
BMPs with the patched original by `cmp`.

Trace: a text file, one line per `fl.trace(s)`: `"<FL_FRAME>
<s>\n"`, flushed per line (`flare.h:122`). The layer writes
nothing in it by itself; the game writes `spawn`, `state`, `hit`,
`map`, `event`, `hero`, `ent`, `rng`... lines (`src/play.atm:24-72`)
in the format of the patched original (`doc/fidelity.md`).

Runner `tst/run.sh` (99 lines): runs with the dummy drivers, writes
each output to `out/<name>.out` and compares with
`tst/golden/<name>.out` by `cmp` (`update` stores). 9 tests:

| Test | How | Golden lines |
|------|-----|-------------:|
| `ini`, `parse`, `power` | stdout+stderr of `tst/<t>.atm` with `FLARE_FRAMES=1 FLARE_MUTE=1`, minus the `flare: frames` line | 14, 7, 2 |
| `engine` | 30 frames, seed 1, trace to stdout, `tst/engine.in`, shot at 20; output + md5 of the BMP | 15 |
| `anim` | 70 frames, trace to stdout, shot at 40 | 87 |
| `font` | 2 frames, shot at 1 | 12 |
| `map` | two maps, 248 frames each, shot at 247 | 6 |
| `runs` | `tools/compare.sh` on the 30 runs of `tst/runs.txt`: each plays `main.atm` with `tst/orig/<n>.in` and `cmp`s its trace with `tst/orig/<n>.trace` (the trace of the original C++ game); prints `same <n> (<lines>)` | 30 |
| `data` | INI and animation dumps of two mod sets: counts and md5 | 4 |

`tst/orig` holds 30 `.in` with 30 `.trace`. Only `engine` runs with
audio (dummy driver, not muted) and is the only test of key and
mouse events.

## 6. Resources

| Kind | Atmos value | C storage | Cache | Freed |
|------|-------------|-----------|-------|-------|
| image | index (number), -1 on failure | `FlImg FL_IMGS[4096]`: path, raw, `SDL_Surface*`, w, h (`flare.h:133-142`) | by (path, raw), linear `strcmp` search; a failed load keeps its slot and returns -1 again without retrying | never |
| font | index, -1 on failure | `TTF_Font* FL_FONTS[64]` (`flare.h:218`) | none: each `fl.font` opens another font; a (path, size, style) is one font | never |
| sound | index, -1 on failure or no audio | `FlSnd FL_SNDS[1024]`: path, `Mix_Chunk*` (`flare.h:279`) | by path; failures keep their slot | never |
| music | none (a path) | one global `Mix_Music* FL_MUS` | no | on the next `fl.music`, `fl.music_stop`, and at exit |
| text | none | a surface per `fl.text` call, rendered and freed in the call | no cache of rendered texts | in the call |

- No native values (`a_nat`), no finalizers, no `pin`: a handle is
  a plain number that the game stores in tables (`font.styles@id`,
  `hero.steps`, the frames of `anim`), and passes back to C as an
  `int` inside tile and renderable structs (`FlTile.img`,
  `FlRen.img`).
- Tables are fixed; when full, loads return -1 silently.
- Load errors of images and fonts print `flare : image : <path> :
  <error>` to stderr (`flare.h:164`, `229`); sounds are silent.
- The map and tileset (game side) are single global instances,
  replaced by `fl.map_new` / `fl.tset_reset`.

## 7. Rendering path

- **Software surfaces only.** Every draw is a `SDL_BlitSurface` or
  `SDL_FillRect` onto `FL_SCREEN`, an ARGB8888 surface of
  1706x960 (`flare.h:565`). The renderer is used for one thing:
  once per frame the pixels go to a streaming ARGB8888 texture
  (`SDL_UpdateTexture`) and `SDL_RenderCopy` stretches it to the
  whole 1280x720 window. No `SDL_RenderCopy` of images, no
  `SDL_RenderSetLogicalSize`, no scale quality hint, no
  `SDL_RenderDraw*`. This copies `SDLSoftwareRenderDevice` of the
  original.
- **Logical size**: window fixed at 1280x720; render height fixed
  at 960; width `(int)(1280 * 960/720.f) = 1706`. Mouse positions
  are multiplied by `FL_SCALE = 960/720` and truncated
  (`flare.h:595`). The sizes are constants of `main`; `FL_W`/`FL_H`
  feed the isometric math (`map.h:333-349`, `447-489`) and
  `src/ai.atm:51`.
- **Two image formats.** Normal images are converted to ARGB8888;
  `raw` images (the sheets of animations, `src/anim.atm:213`) keep
  what `IMG_Load` returns (ABGR8888 for a PNG with alpha). SDL
  blends semi-transparent pixels of the two differently, by 1 to 9
  levels (`doc/fidelity.md:153-159`); the port keeps both to match
  the original pixel by pixel.
- **Tinting and blending** are per draw, set on the source surface
  right before each blit (`flare.h:197-199`): blend mode (BLEND or
  ADD), color mod (0xRRGGBB), alpha mod. The surface keeps the last
  values. No scaling, rotation or flip: destination size equals
  source size.
- **Fill** has no blending: `SDL_FillRect` writes the mapped RGBA,
  alpha included (`flare.h:208`). The screen is cleared to
  (0,0,0,255) before `:draw`; the map then fills its background.
- **Text**: UTF-8, in two qualities chosen per call: blended
  (`TTF_RenderUTF8_Blended`, anti-aliased, 32 bits) or solid
  (`TTF_RenderUTF8_Solid`, 8-bit palette with a color key). The
  surface is blitted **twice** at the same place, as
  `SDLFontEngine::renderInternal` ("blending the text with itself
  makes it clearer", `flare.h:249-272`). Justification (left,
  right, center) is computed in C from `TTF_SizeUTF8`. Styles are
  set at load (`TTF_SetFontStyle`). The quality (`blend`), the
  shadow and the colors come from `engine/font_settings.txt` in
  the game (`src/font.atm:40-89`).
- **Draw order** is the order of calls; the game's only `:draw`
  work is to queue objects (`fl.ren`) and call `fl.map_render`,
  which sorts and draws everything in C.
- **Pixel exactness depends on**: the software blitters of SDL2
  (version, CPU paths) for both source formats; SDL_image and its
  PNG decoder; SDL_ttf and FreeType (glyphs, `TTF_SizeUTF8`,
  `TTF_FontLineSkip` are in `tst/golden/engine.out` and
  `font.out`); the double blit of texts; fills without blending;
  the exact render size 1706x960 and the 32-bit float math of
  `map.h`; the BMP writer of SDL (md5 of the file). It does not
  depend on the renderer, the driver, or the window scaling: the
  shot is taken from the surface.

## 8. Differences from `lang/lib/sdl.atm`

| Topic | `lib/sdl.atm` | Flare |
|-------|---------------|-------|
| Window | created by the program: `sdl.window [title,width,height]` | created in `main` before the program, fixed 1280x720 |
| Draw target | the `SDL_Renderer` directly | a software surface, copied to a texture and scaled |
| Logical size | none (window pixels) | 1706x960 render, mouse scaled |
| Images | `SDL_Texture` as a native value with a finalizer (`a_nat`, kind `sdl.texture`); no cache | `SDL_Surface` behind an index; cache by path; never freed; two pixel formats |
| Image draw | `sdl.copy(tex, crop, rect)` with rect tables `[x,y,w,h]`, scaling by the destination | positional numbers, no scaling; alpha, color mod, additive blend per draw |
| Color | a current color (`sdl.color`) for fill and text, RGB | a color argument per call; fill is RGBA with no blending |
| Fonts | native value with a finalizer; no style | index; style bits; never closed |
| Text | blended only, centered at a position, via a texture | blended or solid, left/right/center, blitted twice, on the surface; width and height queries |
| Sound | `sdl.play(path)`: load and play, cache of 64, no volume | `fl.snd` then `fl.play(i, vol)`; cache of 1024; 128 channels; mute |
| Music | none | `fl.music`, `fl.music_stop` (unused by the game) |
| Event tags | `:sdl.key.dn`, `:sdl.key.up`, `:sdl.quit`, `:sdl.draw` | no prefix; plus `:mouse.*` and `:frame` |
| Event payload | `[name=..]`; a bare tag when there is none | positional `@0..@2`; always a tagged table |
| Key names | `SDL_GetKeyName` of the keysym (layout dependent) | `SDL_GetScancodeName` (physical key) |
| Mouse | none | motion, buttons, polled position |
| Polled input | none | action table with press/lock, bound to scancodes in C |
| Time | emits the elapsed time in µs each frame (real, or fixed in test mode): `await 1s` works | emits no time; `:frame [n]` at a fixed logic rate |
| Frame cap | `SDL_Delay(16)` flat | `SDL_Delay` of what is left of 16 ms |
| Frame counter | from 1, local to `main` | from 0, global, readable (`fl.frame`) |
| Test variables | `SDL_ATM_FRAMES=n:ms`, `SDL_ATM_KEYS=f:dn:A,...`, `SDL_ATM_SHOT=f:x.png,...` | `FLARE_FRAMES`, `FLARE_FAST`, `FLARE_INPUT` (a file, keys and mouse), `FLARE_SHOT=n:file` (one), `FLARE_SEED`, `FLARE_TRACE`, `FLARE_MUTE` |
| Scripted keys | emit the event only | emit the event and update the polled state |
| Screenshot | PNG, `SDL_RenderReadPixels` of the renderer, many | BMP of the surface, one |
| Extras | `sdl.pct_to_pos`, `sdl.rect_vs_rect` | random generator, trace, directory listing, `f32` |
| Shutdown | same sequence | same, plus the `flare: frames` line and `fl_music_stop` |

Common to both: `SDL_Init` with the video-only retry, the same
`Mix_OpenAudio` parameters, `TTF_Init`, the `atm_init` /
`atm_main` / `atm_emit` / `atm_stop` / `atm_quit` skeleton, clear
before draw and present after, no repeat on key down.

## 9. Oddities and risks for a shared environment

1. **Software surfaces are required, not incidental.** The tests
   compare md5 of screenshots, and `tools/compare-shot.sh` compares
   with the original pixel by pixel. A texture/renderer path will
   not reproduce the blits (in particular the ARGB vs raw ABGR
   blending difference, the doubled text, solid text).
2. **C code of the game draws.** `map.h` calls `fl_img_draw` and
   `fl_fill` with image **indices** stored in its own structs, and
   reads `FL_W`/`FL_H`. It needs, from C: a draw of an image handle
   with clip, alpha, color mod and blend; a fill; the render size.
   With native boxed images, C would hold handles without a
   reference.
3. **The render loop is in C for speed and order.**
   `fl_map_render` walks all layers and interleaves tiles and
   sorted objects (`map.h:443-675`), hundreds of blits per frame;
   objects are queued from Atmos (`fl.ren`, up to 4096 per list).
4. **Global state everywhere**, all `static` in one header: window,
   surface, image/font/sound tables, RNG, trace, input state, map,
   tileset, camera, renderables, path buffer (`FL_PATH`), move
   result (`FL_MOVE_X/Y`). Atmos literals read and write some of
   them directly (`FL_BG`, `FL_SHAKE_TIMER`, `FL_CAM`, `FL_LOCK`,
   `FL_PRESSING`, `FL_PATH`, `FL_MAP_W/H`, `FL_SPEED_MULT`,
   `FL_RND_CALLS`, `FL_TRACE`: `engine.atm:33-304`).
5. **The header order matters**: the game headers sit in the middle
   of `flare.h` and the layer's `main` comes after them. A shared
   environment included before the game needs the game C to come
   later, in a prelude of the game, seeing the environment's C
   names.
6. **Polled, action-based input in the platform.** The game awaits
   no key or mouse event; it needs press / lock / release-next-frame
   semantics (`InputState` of Flare) with bindings hardcoded by
   scancode in C (`flare.h:366-384`), updated before the events of
   the frame are emitted and also by scripted input. This state
   could be rebuilt in the game from `:key.*`/`:mouse.*`, but the
   order (reset at frame start, then events, then `:frame`) is
   what the traces depend on.
7. **Scancode names**, not key names, in events and scripts; names
   with spaces cannot be scripted.
8. **No time, fixed step.** Logic is one step per `:frame`; there
   is no dt and no clock. An environment that passes real time
   must still give exactly one logic step per frame in test mode,
   and frame numbers from 0 (the trace prints them).
9. **Frame numbering in traces and shots**: the trace prefix is
   the global `FL_FRAME` (0 during the main chunk and during
   `:frame [0]`); scripted lines fire before `:frame` of their
   frame; `FLARE_SHOT=n` is after n frames. The 30 stored traces of
   the original fix these conventions.
10. **The RNG is shared** between Atmos (`fl.rand`), native literals
    of the game (`fl_rand()` in float expressions) and the game C
    (camera shake, random neighbor). The sequence and the count of
    draws per frame are compared with the original (`FLARE_RNG`).
    It must stay one generator reachable from C.
11. **`:draw` after quit**: the last iteration still emits `:draw`
    and presents; `:quit` is not emitted when `FLARE_FRAMES` ends
    the run. Nothing awaits `:quit`.
12. **Draw order relies on task order at `:draw`**: `MapRun` queues
    enemies (`src/play.atm:246`) and `Play` queues the hero, renders
    and clears (`src/play.atm:325-333`); `Play`'s loop is declared
    last but the comment says the maps "add theirs before the next
    draw", so what is drawn depends on the order in which the
    awaiting tasks wake.
13. **Indices instead of resources**: nothing is ever freed, the
    tables are fixed (4096 images, 64 fonts, 1024 sounds), failures
    are cached, `-1` is a valid argument everywhere (draws of an
    invalid index do nothing). The game relies on `-1` rather than
    `nil` (`src/font.atm:57`: `if f >= 0`).
14. **Fixed window and render size** in `main`; the program cannot
    choose them, and `fl.W`/`fl.H` are read when the table `fl` is
    built (after `main` set them).
15. **stderr/stdout are part of test outputs**: the `flare : image
    : ...` error line and `flare: frames N` are in
    `tst/golden/engine.out`; the trace to stdout (`-`) interleaves
    with `print`.
16. **Audio in tests**: `engine` runs with the dummy audio driver
    and expects `fl.snd` to return 0 (loaded) and -1 for a missing
    file; all other runs use `FLARE_MUTE`, where `fl.snd` is -1 and
    `fl.play` does nothing.
17. **Build**: needs `-I<root>` and to run from the root; `-O2` by
    default; `-lm`. The game also has its own prelude C
    (`src/parse.atm:15`) with the same `fl_` prefix.
18. **Unused surface of the layer**: `fl.music`, `fl.music_stop`,
    `fl.pressing`, `fl.locked`, `fl.FPS` (nowhere); `fl.draw`,
    `fl.part`, `fl.fill`, `fl.size`, `fl.W/H`, `fl.frame`, `Frames`,
    and all key/mouse events (tests only). 17 of the `Input`
    actions in `Input` and all key bindings other than the
    arrows/WASD and the mouse buttons are never read by the game.
19. **The cap is 16 ms**, not 1000/60: about 62.5 frames per second
    when not in `FLARE_FAST`.
