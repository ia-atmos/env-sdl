# The SDL environment: reference

`sdl.atm` connects an Atmos program to SDL2: the window, the input, the
images, the text, the sound, and the time, with a test mode with no
screen. Its functions are in the table `sdl`; a program in C reaches it
through a few functions of its prelude (the door in C).

- [Use](#use)
- [The frame and the events](#the-frame-and-the-events)
- [The window](#the-window)
- [Images and shapes](#images-and-shapes)
- [Text](#text)
- [Sound](#sound)
- [Input and time](#input-and-time)
- [The test mode](#the-test-mode)
- [The door in C](#the-door-in-c)

## Use

A program includes the file, and is built with the libraries of SDL:

```
include "sdl.atm"           ;; the path from the file of the program
```

```
ATMOS_LDFLAGS="-lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer" atmos game.atm
```

A game gets the environment as a checkout of this repository at a fixed
commit. In this repository, `make ATMOS=<lang>` also builds `atmos-sdl`,
the compiler with `sdl.atm` included before every program, which the
tests and the examples use:

```
atmos-sdl game.atm
```

The development files of SDL2, SDL2_image, SDL2_ttf, and SDL2_mixer are
needed:

```
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev
```

A program:

```
sdl.window [title="Hello", width=320, height=240]
spawn {
    loop on :draw {
        sdl.fill(0xFF0000FF, 110, 70, 100, 100)
    }
}
await :key.dn
```

The environment works under the numeric options of the compiler
(`ATMOS_REAL=float`, `ATMOS_INT=32`, `ATMOS_TIME=ms`, manual
"Execution"): the clock passes in the unit of time of the build, with
the rest carried to the next frame, and `:frame` gives `us` in
microseconds always. A program that turns a clock into seconds should
divide by `1s` and not by a number (`val dt = us / 1s`).

Images, fonts, and sounds are native values. `pin` them to release them
with their block, or keep them in a pinned table:

```
pin img = sdl.image("ship.png") --> assert
pin SND = [ shot = sdl.sound("shot.wav") ]
```

A function that fails returns `nil` (a missing file), or does nothing
(a value that is not an image). Colors are numbers `0xRRGGBBAA`.
Positions and sizes are numbers, truncated to integers.

## The frame and the events

The program runs inside the loop of SDL. Each frame is, in this order:

1. the input: the events of SDL, then the scripted input of the test
   mode;
2. `:frame`, for the logic that runs once per frame;
3. the time: the clock of Atmos passes once (`await 1s`,
   `loop us on :clock`), scaled by [`sdl.clock`](#input-and-time): a
   factor set during `:frame` applies to the time of the same frame;
4. with a window: the clear (black), the passes of drawing (`:draw`),
   the [function of flush](#the-door-in-c), the screenshot, the
   present;
5. the rest of the frame, to the cap of frames per second.

The events:

| Event | Fields | When |
|---|---|---|
| `:quit` | | the window was closed; the program terminates |
| `:key.dn` | `key`, `code` | a key was pressed |
| `:key.up` | `key`, `code` | a key was released |
| `:mouse.motion` | `x`, `y` | the mouse moved |
| `:mouse.button.dn` | `x`, `y`, `button` | a button was pressed |
| `:mouse.button.up` | `x`, `y`, `button` | a button was released |
| `:frame` | `n`, `us` | once per frame |
| `:draw` | | once per frame, with a window |

- `key` is the name of the key (`'A'`, `'Return'`, `'Left Shift'`), and
  `code` the name of its scancode: the key at that place of a US
  keyboard. They differ on other layouts.
- `button`: 1 left, 2 middle, 3 right.
- `n` counts the frames from 1; `us` is the time of the frame, in
  microseconds, not scaled by `sdl.clock`.
- A key held down is not repeated.

```
loop e on :key.dn {
    print(e.key, e.code)
}
await :mouse.button.dn [button=3]
```

## The window

```
sdl.window [title=, width=, height=, logical=[w,h], fps=, fixed=,
            software=, passes=]
```

Opens the window. With no window, there is no `:draw`.

- `title`, `width`, `height`: default `'Atmos'`, 640, 480.
- `logical`: the size that the program draws in, scaled to the window.
- `fps`: the cap of frames per second, less the time spent in the frame
  (default 60; 0, no cap: frames as fast as they go). The time of a
  fixed frame with no cap is 1/60 s.
- `fixed`: if true, the time of a frame is exactly 1/fps s, and not the
  time measured: the n-th frame ends at n*1000000/fps us, so that `fps`
  frames are exactly 1 s. The test mode is always so, unless it gives
  the milliseconds of a frame.
- `software`: if true, the screen is an ARGB8888 surface of the logical
  size. An image is drawn with `SDL_BlitSurface` (`SDL_BlitScaled` if
  the sizes differ), a fill with `SDL_FillRect` (through a surface if
  it has alpha), a line a pixel at a time, and the surface is copied to
  the window at each frame. A screenshot is the surface. Otherwise, the
  renderer of SDL draws, with a texture for each image.
- `passes`: the tags of the passes of drawing, emitted in order at each
  frame (default `[:draw]`, at most 7):
  `passes=[:draw, :overlay]`.

```
sdl.display(fullscreen, w, h, grab, cursor)
```

The window in fullscreen (the desktop), or with the size `w` x `h` (if
greater than 0), the mouse grabbed in it, and the cursor shown. In the
test mode, the window keeps its size.

## Images and shapes

| Function | |
|---|---|
| `sdl.image(path [,raw])` | an image from a file, or `nil` |
| `sdl.size(img)` | its width and its height (0, 0 if not an image) |
| `sdl.draw(img, x, y)` | the whole image at a position |
| `sdl.part(img, sx,sy,sw,sh, x,y [,alpha])` | a part of an image at a position, with an alpha from 0 to 255 (default 255) |
| `sdl.scale(img, sx,sy,sw,sh, x,y,w,h [,alpha])` | a part of an image into a rectangle of another size |
| `sdl.draw_ex(img, sx,sy,sw,sh, x,y,w,h [,angle [,flip [,rgba [,blend]]]])` | a part of an image into a rectangle, rotated by `angle` degrees (clockwise, around its center), flipped (`:h`, `:v`, `:hv`), with its color and alpha modulated by `rgba` (default `0xFFFFFFFF`), and a blend mode (`:blend` default, `:add`, `:mod`, `:none`); in the software path, no rotation and no flips |
| `sdl.fill(rgba, x,y,w,h)` | a filled rectangle, blended |
| `sdl.rect(rgba, x,y,w,h)` | the outline of a rectangle |
| `sdl.line(rgba, x1,y1,x2,y2)` | a line |

An image keeps the pixels of its file in a surface. With the renderer,
a texture is made from it at its first draw. In the software path, it
is converted to ARGB8888 at its first draw, unless `raw` keeps the
format of the file: a blit with alpha gives other pixels in each
format.

```
pin ship = sdl.image("ship.png") --> assert
val w, h = sdl.size(ship)
loop on :draw {
    sdl.part(ship, 0,frame*h/4,w,h/4, x,y)
    sdl.fill(0x00000080, 0, 0, 100, 20)
}
```

## Text

| Function | |
|---|---|
| `sdl.font(path, size)` | a TrueType font, or `nil` |
| `sdl.text(fnt, s, x, y, rgba [,align])` | a text in UTF-8, with its top at `y`, and aligned at `x` by `align`: `:left` (default), `:center`, `:right` |
| `sdl.text_size(fnt, s)` | the width and the height of a text |

```
pin fnt = sdl.font("tiny.ttf", 16) --> assert
loop on :draw {
    sdl.text(fnt, "Score: 10", 320, 8, 0xFFFFFFFF, :center)
}
```

## Sound

| Function | |
|---|---|
| `sdl.sound(path)` | a sound (wav, ogg, ...), or `nil` |
| `sdl.play(snd [,vol])` | plays a sound once, with a volume from 0 to 1 (default 1) times the volume of the sounds; the channel, or -1 |
| `sdl.music(path [,loops [,from, to]])` | plays a music `loops` times (default -1, forever), in place of the current one; the same music that plays goes on; with `to` (seconds) it loops forever, going back to `from` when it passes `to` (checked once per frame); whether the file was loaded |
| `sdl.music_pos()` | the position of the music, in seconds, or -1 |
| `sdl.music_stop([fade])` | stops the music, fading out in `fade` milliseconds (default 0) |
| `sdl.volume(sounds, music)` | the volumes, from 0 to 1 |

With no audio device (`SDL_ATM_MUTE`, or none available), a sound
whose file exists is a value that plays nothing.

## Input and time

| Function | |
|---|---|
| `sdl.key(name)` | whether a key is pressed, by the name of the key or of its scancode |
| `sdl.mouse()` | the last position of the mouse |
| `sdl.clock(f)` | the clock of Atmos goes `f` times as fast as the frames (default 1; 0 stops it), carrying the remainder to the next frame; the time of `:frame` is not affected |
| `sdl.frame()` | the number of the current frame, from 1 |
| `sdl.testing()` | whether in the test mode |

```
sdl.clock(0)                ;; pauses what awaits the clock
loop e on :frame {          ;; and goes on with the frames
    if sdl.key('Left') {
        set x = x - 1
    }
}
```

## The test mode

With `SDL_VIDEODRIVER=dummy`, a program runs with no screen. The
variables:

```
SDL_ATM_FRAMES=n[:ms]       n frames (of ms milliseconds, or of 1/fps s),
                            then the end; no sleep between frames
SDL_ATM_KEYS=f:dn:A,...     presses (dn) or releases (up) a key at a
                            frame, by the name of the key
SDL_ATM_MOUSE=f:mv:x:y,f:dn:x:y:b,f:up:x:y:b
                            moves the mouse, presses or releases the
                            button b at a position, at a frame; a
                            press or a release elsewhere moves the
                            mouse there first (:mouse.motion)
SDL_ATM_SHOT=f:x.png,...    saves the screen at a frame, in PNG
SDL_ATM_MUTE=1              opens no audio device
SDL_ATM_RENDER=1            a frame with no screenshot is rendered too
```

- The frames count from 1.
- A value `@file` gives the entries in a file, separated by commas or
  new lines: `SDL_ATM_KEYS=@keys.txt`.
- A scripted key or button is a real event: the program cannot tell it
  from one of SDL.
- At the end of the frames, the main chunk is aborted: its `defer`
  blocks execute.
- A screenshot is the screen surface in the software path (at the
  logical size), and what the renderer drew otherwise (at the size of
  the window).

The tests of this repository compare the standard output of a program
(its trace) and its screenshots, pixel by pixel (`tools/pngcmp.c`):
see `tst/run.sh`.

## The door in C

For the C of a program, which draws by itself or keeps pointers of SDL.
The program keeps the values alive: a pointer taken from an image is
valid while the image is.

| | |
|---|---|
| `SDL_Window* sdl_win(void)` | the window, or `NULL` |
| `SDL_Renderer* sdl_ren(void)` | the renderer, or `NULL` |
| `SDL_Surface* sdl_scr(void)` | the screen surface in the software path, or `NULL` |
| `void sdl_size(int* w, int* h)` | the size the program draws in |
| `SDL_Surface* sdl_sfc(AVal img)` | the pixels of an image, or `NULL` |
| `SDL_Texture* sdl_tex(AVal img)` | the texture of an image (made at its first use), or `NULL` |
| `AVal sdl_new_image(SDL_Surface* sfc)` | an image that owns `sfc` (raw) |
| `void sdl_on_flush(void (*f)(int render))` | `f` runs at each frame, after the passes of drawing and before the screenshot and the present; `render` is 0 in a frame of the test mode that has no screenshot (unless `SDL_ATM_RENDER`) |
| `int SDL_FRAME`, `int SDL_TESTING` | as `sdl.frame()` and `sdl.testing()` |

The surface of an image has the format of its file until its first draw
in the software path, which converts it to ARGB8888 (unless raw).

```
```:prelude
static void tiles (AVal img, int n) {
    SDL_Texture* tex = sdl_tex(img);
    for (int i=0; i<n; i++) {
        SDL_Rect s = { 32*(i%8), 0, 32, 32 };
        SDL_Rect d = { 32*i, 0, 32, 32 };
        SDL_RenderCopy(sdl_ren(), tex, &s, &d);
    }
}
```
pin tileset = sdl.image("tiles.png") --> assert
loop on :draw {
    `tiles($tileset, 40);`
}
```

The names of the prelude have the prefixes `sdl_` and `SDL_`: a program
must not declare names with them.
