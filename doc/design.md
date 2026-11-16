# Design of the interface (a proposal)

**Status: approved by the author on 2026-11-16** (section 12), and
being built (E3). It comes from [`inventory.md`](inventory.md); the numbers
in parentheses refer to its sections.

## 1. The shape

Two levels, in one file `sdl.atm`:

1. **The table `sdl`**, for Atmos: the window, the images, the
   shapes, the text, the sound, and the state of the input.
2. **A door in C**, documented: a few functions of the prelude that
   give, to the C of a game, the renderer, the screen, and what is
   behind an image. Pingus, Flare, and Tux draw from C of their own
   (5, 10); today each reaches into the globals of its layer.

The loop, the events, and the test mode are of the environment, as
today. What is of a game stays in the game, over these two levels.

The smallest set that serves the three is small, because the three
overlap little (24 of 83 functions of SDL, 1). The proposal is to make
the common part well, and not to absorb the model of each game.

## 2. The window

```
sdl.window [title=, width=, height=, logical=[w,h], fps=, software=]
sdl.display [fullscreen=, width=, height=, grab=, cursor=]
```

- **From the program, as `sdl.atm` today.** The three games create
  the window in `main` (2): the three change, by one line each.
- `logical`: the size that the program draws in, scaled to the window
  (Flare, Tux; Pingus sets it later).
- `fps`: the cap (40, 60, 62.5 in the games; 4). Default 60.
- `software`: the screen is a surface, see 4.
- `sdl.display`: for Pingus only, but of the platform.

## 3. The events and the frame

The names wait for the author (item A2 of `TODO.md`). With the
vocabulary of `pico.atm`, which the compiler session recommended:

| Event | Fields | Today |
|---|---|---|
| `:quit` | | the same |
| `:key.dn`, `:key.up` | `key`: the name of the key | `name` |
| `:mouse.motion` | `x`, `y` | none |
| `:mouse.button.dn`, `.up` | `x`, `y`, `button` | none |
| `:frame` | `n` (from 1), `ms` | none |
| `:draw` | | the same |

A frame, in this order (the order of the three, 4):

1. the events of SDL, then the scripted input;
2. the time, once, as the clock of Atmos (`await 1s` works);
3. `:frame [n, ms]`, for what runs once per frame;
4. the clear, `:draw`, the screenshot, the present, the delay.

- **The time is the real elapsed time**, and a fixed one in the test
  mode. Pingus is like this. Tux asked for it.
- **SNKRX** passes a nominal 1/60 s and scales the time of Atmos
  (`eng.slow`). Proposal: `sdl.clock(f)`, a factor on the time of
  step 2 (0 stops it); `:frame` keeps the real time. Its nominal
  time is the fixed time of the test mode, set also when not testing
  (`fps=60, fixed=true` in `sdl.window`).
- **Flare** passes no time. It awaits `:frame` only, so the time of
  step 2 should not reach it; to verify with its 30 traces. Its
  frames count from 0: it subtracts 1.
- **Polled state**: `sdl.mouse()` -> `x, y`, and `sdl.key(name)` ->
  pressed. The actions and locks of Flare stay in Flare, over these.
- `:draw` is emitted only with a window (as today).

## 4. Images and drawing

```
sdl.image(path)                         ;; an image, or nil
sdl.size(img)                           ;; w, h
sdl.draw(img, x, y)
sdl.part(img, sx,sy,sw,sh, x,y [, alpha])
sdl.scale(img, sx,sy,sw,sh, x,y,w,h [, alpha])
sdl.fill(rgba, x,y,w,h)
sdl.rect(rgba, x,y,w,h)
sdl.line(rgba, x1,y1,x2,y2)
```

- **Plain numbers as arguments, no tables.** The three games do so;
  a table per call costs (0.5 us measured by the other ports). It
  changes `sdl.copy(tex, crop, rect)` and `sdl.fill(rect)` of today:
  Rocks changes.
- **The color goes in each call**, as `0xRRGGBBAA` (Pingus, Flare).
  `sdl.color` of today goes away. SNKRX keeps its own encoding inside
  its level.
- **An image holds a surface, and a texture made at its first draw.**
  It is what Pingus does. It serves the two paths:
  - *renderer* (default): `SDL_RenderCopy` of the texture (Pingus,
    Tux, Rocks);
  - *software* (`software=true`): the screen is one surface of the
    logical size; a draw is `SDL_BlitSurface`, a fill is
    `SDL_FillRect`; one texture update per frame (Flare).
  The functions are the same in both. A game chooses one path, at the
  window, and its pixels follow.
- **Not in the common part**: rotation, flips, tint, blend modes at
  the draw. Tux wants them with the renderer (`SDL_RenderCopyEx`,
  color and alpha modulation): proposed as one more function,
  `sdl.draw_ex`, in E3, when Tux gets there. The 8 modifiers of
  Pingus are applied at the load, on the surface: they stay in
  Pingus, over the door in C.

## 5. Text

```
sdl.font(path, size)                    ;; a font, or nil
sdl.text(fnt, s, x, y, rgba [, align])  ;; align: :left, :center, :right
sdl.text_size(fnt, s)                   ;; w, h
```

- TTF and UTF-8 (`TTF_RenderUTF8_Blended`), for Flare, Tux, Rocks.
- **The bitmap fonts of Pingus and the atlas of SNKRX stay in their
  games**: they are made to copy the pixels of the originals.

## 6. Sound

```
sdl.sound(path)                         ;; a sound, or nil
sdl.play(snd [, vol])                   ;; -> a channel
sdl.music(path [, loops])
sdl.music_stop([fade_ms])
sdl.volume(sounds, music)               ;; 0..1 each
```

- It serves Pingus and Flare as they are, and Rocks.
- **The pitch and the instances of SNKRX stay in SNKRX**, over the
  door in C (it resamples chunks by hand). The loop points of the
  music of Tux: in E3, with Tux.
- `SDL_ATM_MUTE` opens no audio device.

## 7. Resources

- **Native values**, as `sdl.atm` today: an image, a font, and a
  sound are released with their block (`pin`) or their last
  reference; a failure is `nil`.
- The three games use integer indices that are never freed, with a
  cache by path (8). **They change**: the index becomes the value,
  and the cache becomes a table of the game (`CACHE[path]`), which
  keeps the reference. Nothing else moves, since the games never
  free.
- Why not indices in the environment: fixed tables that overflow in
  silence, and nothing ever released. It would be right for the three
  games and wrong for a new program.
- The C of a game keeps pointers that it takes at the door; the game
  keeps the value alive.

## 8. The door in C

Names of the prelude, with a prefix of the environment:

```
SDL_Window*   sdl_win  (void);
SDL_Renderer* sdl_ren  (void);
SDL_Surface*  sdl_scr  (void);      // the screen, in the software path
void          sdl_dim  (int* w, int* h);   // the logical size
SDL_Surface*  sdl_sfc  (AVal img);  // NULL if not an image
SDL_Texture*  sdl_tex  (AVal img);  // made at the first use
AVal          sdl_img  (SDL_Surface* sfc); // an image from a surface
int           sdl_frame   (void);
int           sdl_testing (void);
```

- With these, the ground map of Pingus, the tiles of Flare and of
  Tux, and the whole drawing of SNKRX are C of the game.
- The names keep the prefix `sdl_` (decided by the author).

## 9. The test mode

```
SDL_ATM_FRAMES=n:ms             n frames of ms milliseconds, then the end
SDL_ATM_KEYS=f:dn:A,...         keys at frames
SDL_ATM_MOUSE=f:mv:x:y,f:dn:x:y:b,f:up:x:y:b
SDL_ATM_SHOT=f:file,...         the screen at frames; .png or .bmp
SDL_ATM_MUTE=1                  no audio device
```

- One set for the games (item A3 of `TODO.md`, to confirm). A value
  that starts with `@` is a file with one entry per line, for the
  long scripts (Flare, SNKRX).
- Frames count from 1. Fixed frames do not sleep.
- A screenshot is written with the writer of SDL of its extension,
  so that a game that compares files, byte for byte (9), keeps doing
  it. To verify with each game: the same bytes as today.
- What is not here: the traces, the seeds, the profile. They are of
  the games.

## 10. Who changes

| | Pingus | SNKRX | Flare |
|---|---|---|---|
| Window | from the program | from the program | from the program |
| Events | the prefix goes away; `name` -> `key`; `.mouse.dn` -> `.mouse.button.dn` | `:mouse.mv` -> `:mouse.motion`, buttons; `:tick` -> `:frame` | `:mouse.dn` -> `.button.dn`; key fields; `:frame` from 1 |
| Resources | indices -> values, cache in Atmos | the same | the same |
| Stays in the game, in C over the door | ground maps, mover, minimap, bitmap fonts, the 8 modifiers | canvases, geometry, transforms, shadow, atlas fonts, pitch | map, tiles, queue of objects, collision, paths, random |
| Test scripts | `PINGUS_*` -> `SDL_ATM_*` | `SNX_*` -> `SDL_ATM_*`; input by frame | `FLARE_*` -> `SDL_ATM_*`; input as `@file` in the new format |

## 11. SNKRX: said before forcing it

The plan asked to say it if a game needs a different model. **SNKRX
does** (5): deferred triangles, canvases as render targets, a stack
of transforms, a shadow composed by hand, a tessellation that copies
LÖVE. Nothing of it is used by another game.

Proposal: **it stays in SNKRX**, as its own level in C over the door
(the renderer). The environment gives SNKRX the window, the loop, the
events, the clock with its factor, the sounds as chunks, and the test
mode: the smaller part of its layer (not measured). The alternative,
a second level `sdl.canvas` in the environment, puts most of the
1414 lines of `eng.h` here, to serve one game and to copy LÖVE pixel
by pixel.

## 12. Decided by the author (2026-11-16)

1. Resources are native values (7).
2. SNKRX keeps its drawing (11).
3. The events have the vocabulary of `pico.atm` (3).
4. One test mode (9).
5. A game gets the environment as a checkout at a fixed commit, and
   brings it with `include "sdl.atm"`, with the plain compiler and
   the libraries in `ATMOS_LDFLAGS`. It does not need `atmos-sdl`,
   which stays as the compiler of the examples and of the tests of
   this repository.

6. The names of the prelude keep the prefix `sdl_` (8).
7. Rocks lives in this repository, as `exs/rocks/`; `lib/sdl.atm`
   and `exs/rocks/` left the compiler.

Added after the migration to the new rules of `pin`: a function of
the environment returns plain numbers (`val x, y = sdl.mouse()`), and
never a small table, which the caller would have to `pin`. So
`sdl.pct_to_pos` of today goes away, or returns two numbers.

To verify with the sessions of the games, each with its own tests:
the software path against the screenshots of Flare; the texture path
against those of Pingus; the time of step 2 against the traces of
Flare; the bytes of the screenshots.
