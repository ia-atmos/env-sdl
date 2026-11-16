# env-sdl

An [SDL2][sdl] environment for [Atmos][atmos]: the window, the input, the
images, the text, the sound, and the time, with a test mode with no screen.

- [`sdl.atm`](sdl.atm): the environment (its header documents the events
  and the functions, which are in the table `sdl`).
- `atmos-sdl`: the Atmos compiler dedicated to SDL, built by `make`.
- [`tst/`](tst/): the tests (`make tests`).
- [`exs/rocks/`](exs/rocks/): a spaceship shooter for 2 players.
- [`doc/`](doc/): the documents of the design.

[sdl]:   https://www.libsdl.org/
[atmos]: https://github.com/ia-atmos/lang

# Run

```
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev
git clone https://github.com/ia-atmos/lang
make -C lang
make ATMOS=lang             # builds ./atmos-sdl
cd exs/rocks/
../../atmos-sdl main.atm
```

`atmos-sdl` is the Atmos compiler with `sdl.atm` included before every
program and the SDL libraries linked: a program is only its own code.
It keeps depending on the checkout of the compiler, on a C compiler, and on
the SDL2 packages above.

```
sdl.window [title="Hello", width=320, height=240]
spawn {
    loop on :draw {
        sdl.fill(0xFF0000FF, 110, 70, 100, 100)
    }
}
await :key.dn
```

A program that starts with `include "sdl.atm"` also works, with
`atmos-sdl` or with the plain compiler and the libraries in
`ATMOS_LDFLAGS`.

# Tests

```
make tests                  # or: tst/run.sh [name ...]
ATMOS_ASAN=1 make tests     # with the address sanitizer
```

The tests run with no screen (`SDL_VIDEODRIVER=dummy`), with a fixed number
of frames and scripted input, and compare traces and screenshots:

```
SDL_ATM_FRAMES=n:ms         runs `n` frames of `ms` milliseconds, then quits
SDL_ATM_KEYS=f:dn:A,...     presses (`dn`) or releases (`up`) keys at frames
SDL_ATM_MOUSE=f:mv:x:y,f:dn:x:y:b,f:up:x:y:b    moves the mouse, or a button
SDL_ATM_SHOT=f:x.png,...    saves the screen at frames
SDL_ATM_MUTE=1              opens no audio device
```

# Status

This repository is being written. It starts as `lib/sdl.atm` of the
compiler, and grows to serve the games ported over SDL2. The plan is in
[`.claude/plans/`](.claude/plans/).
