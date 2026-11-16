# env-sdl

An [SDL2][sdl] environment for [Atmos][atmos]: the window, the input, the
images, the text, the sound, and the time, with a test mode with no screen.

- [`sdl.atm`](sdl.atm): the environment, with its functions in the
  table `sdl`.
- [`doc/api.md`](doc/api.md): the reference.
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

A game gets the environment as a checkout of this repository at a fixed
commit, and starts with `include "sdl.atm"`, with the plain compiler and
the libraries in `ATMOS_LDFLAGS` (see [`doc/api.md`](doc/api.md)).

# Tests

```
make tests                  # or: tst/run.sh [name ...]
ATMOS_ASAN=1 make tests     # with the address sanitizer
```

The tests run with no screen (`SDL_VIDEODRIVER=dummy`), with a fixed
number of frames and scripted input, and compare their traces and their
screenshots, pixel by pixel. The test mode is in
[`doc/api.md`](doc/api.md#the-test-mode).

# Status

The environment of the three games ported over SDL2 (Pingus, SNKRX,
Flare), and of SuperTux. It started as `lib/sdl.atm` of the compiler.
The plan and what is pending are in [`.claude/plans/`](.claude/plans/).
