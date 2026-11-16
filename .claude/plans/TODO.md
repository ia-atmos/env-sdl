# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

## A. Decisions waiting for the author

Asked one at a time, each with the recommended option.

(none: everything asked was answered on 2026-11-16)

## B. Work known and not done

- **E3, in course.** Done: the events of the design (`key`, the
  mouse, `:frame [n,ms]`), `sdl.mouse()`, `SDL_ATM_MOUSE`,
  `SDL_ATM_MUTE` (12 tests). To do, in this order: plain numbers as
  arguments and the color in each call (`sdl.draw`, `sdl.part`,
  `sdl.scale`, `sdl.fill`, `sdl.rect`, `sdl.line`; Rocks changes);
  `sdl.text` with a color and an alignment, `sdl.text_size`;
  `sdl.sound`, `sdl.play` with a volume, `sdl.music`, `sdl.volume`;
  `sdl.window` with `logical`, `fps`, `software`; `sdl.display`;
  `sdl.key(name)`, `sdl.clock(f)`; the door in C; `@file` in the test variables;
  `doc/api.md`.
- **Pingus, SNKRX, and Flare answered** (2026-11-16):
  `doc/requests/answers.md`, with what changes in the design
  (`:frame` in microseconds, the scancode in the key events, a raw
  image format for the software path, no `.bmp`, a fixed rate from the program, the carry
  of `sdl.clock`, a callback of flush in C, the second pass of
  drawing of SNKRX, still open). Baselines: Pingus `cc5fe72`, SNKRX
  `2bddee7` or later. `inventory/pingus.md` is out of date in three
  spots of `engine.atm`.
- E4..E7: see the plan.
- **A fourth client, SuperTux** (`ia-atmos/sdl-tux`, session
  `sdl-tux`, session_011eECoijTqoBzMrEaknmW9P; plan in `ia-atmos/lang`,
  `.claude/plans/261113-sdl-tux.md`), told by the compiler session on
  2026-11-13. It has no layer of its own: it starts over this
  environment from its third milestone on. Expected needs: tilemaps
  drawn fast, sprites, fonts, sounds, a test mode with scripted input
  by tick. Its requests, received on 2026-11-14, are in
  `doc/requests/sdl-tux.md`; tell it when E0/E3 has what it can build
  on, and at which commit. Count it in `doc/inventory.md` (E1) as a future client and
  in the design (E2).
- **Compiler changes to mind** (`ia-atmos/lang` `3cc4855`, told on
  2026-11-14): `skip` is a statement and a reserved name; a `spawn`
  that dies with its block is a compile error. The second fires in
  the code of Pingus (one place) and SNKRX (three), not in their
  layers: their sessions fix it, so the traces of those games change
  before the move. Take the baseline of E4 and E5 after that.
- A test of the pause of Rocks (the path is not covered; it changes
  the expected images, so it needs a second run of the game).

## C. Reported or decided, not acknowledged

- **E0 is done** (2026-11-14): `sdl.atm` from the compiler, `make`
  builds `atmos-sdl`, `tst/run.sh` with 8 tests (also with
  `ATMOS_ASAN=1`), readme.
- **Decided by the author on 2026-11-16**: the design of
  `doc/design.md` goes ahead; resources are native values; SNKRX
  keeps its drawing in the game; one test mode (`SDL_ATM_*`); the
  vocabulary of events of `pico.atm`; a game gets the environment as
  a checkout at a fixed commit and uses `include`, with the plain
  compiler: **it does not need `atmos-sdl`**.
- **Also decided on 2026-11-16**: the C names of the prelude keep
  the prefix `sdl_` ("sdl_ só está bom"); Rocks lives here and not in
  the compiler ("O jogo não deveria estar em lang"). Told to the
  compiler session, which removed `lib/sdl.atm` and `exs/rocks/` from
  `ia-atmos/lang`.
- **`atmos-sdl` is kept in this repository** (build, tests, Rocks,
  readme), as the wish relayed on 2026-11-14 for every environment.
  Read his "does not need atmos-sdl" as about the games. Told to
  him; he may say otherwise.
- **Migrated to the new rules of `pin`** (2026-11-15, `20f974f`,
  `c18a419`; compiler at `09a7885`). Asked by the compiler session as
  approved by the author; not heard from him here. 16 lines to `pin`,
  4 rewrites in Rocks, the 8 tests identical. Reported to the
  compiler session, with a defect of its own Rocks (the pause).
  For the design: functions should return plain numbers, not small
  tables, which a caller would have to `pin`.
- **E1 is done** (2026-11-14): `doc/inventory.md`, over
  `doc/inventory/{pingus,snkrx,flare}.md`. The layers were read, not
  run. Main findings: a small common part; a door in C is needed
  (Pingus, Flare, Tux); SNKRX needs a different model of drawing; the
  games use indices never freed, `sdl.atm` native values; the games
  compare screenshots as files, byte for byte.
- **Rocks was copied here**, as `exs/rocks/`, to be the test of E0
  (it takes a seed as its argument, to be deterministic). This goes
  ahead of decision A4 only as a copy: `lib/sdl.atm` and `exs/rocks/`
  of the compiler are untouched.
- **`:draw` is only emitted when there is a window**, as in
  `lib/sdl.atm`. Kept for now; to settle in E2.
- **The screenshot of a text depends on the version of FreeType**
  (`tst/text-2.png`, `tst/rocks-*.png`): the expected images are from
  SDL2_ttf 2.22 of Ubuntu 24.04. To settle in E2 (a tolerance, or a
  fixed setup).
- **Events have no prefix** (`:key.dn`, `:draw`, not `:sdl.key.dn`).
  Relayed by the compiler session on 2026-11-13: the author decided
  it for all environments in the session of pico ("Unprefixed is
  ok"); plan updated there (`eefb2dc`). Not heard from the author in
  this session, and not found in the part of the pico transcript
  read from here (newest 100 events only). Adopted; told to the
  author, who may object.
