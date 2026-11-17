# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

## A. Decisions waiting for the author

Asked one at a time, each with the recommended option.

(none: everything asked was answered on 2026-11-16)

## B. Work known and not done

- **E5: SNKRX over the environment**, with its session, after its
  baseline (`2bddee7` or later) and its migration to the new rules of
  `pin`, which waits for the author. Not told to start yet.
- **Not built in E3**, for when a game needs them: `sdl.draw_ex`
  (flips, rotation, tint; Tux), the loop points of a music (Tux),
  blend modes at the draw (Flare, over the door).
- **`inventory/pingus.md` is out of date** in `res_desc`, `LANG`, and
  `Sprite` (Pingus changed `engine.atm` in its migration to `pin`).
- **SNKRX may ask for a step event** (`:step [us]`, the scaled time
  of the frame, once per frame), if the author decides its finding 8
  (physics stepped once per frame). Not to build before that.
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
- **The rules of `pin` changed again on 2026-11-17** (compiler
  `0ba7afc`, `98547d3`; relayed by the compiler session as asked by
  the author): `val`/`var` may hold a fresh value again, and a `pin`
  may be reassigned. The tests here pass with `lang` `b463c23`, with
  no change. The rewrites of Rocks are kept; undoing them is the
  author's call. Pingus fails one check (`screens`) with that
  compiler, in its own code: told to Pingus and to the compiler
  session.
- **E4 is done** (2026-11-17): Pingus moved over `2723b34`
  (`sdl-pingus` `e9fd322` code, `b7e125f` tests): all its tests
  identical, normal and ASAN, its 6 golden screenshots identical by
  pixels, its 159 demo traces byte-identical (its report).
  `engine/pingus.h` went from 930 to 591 lines, the game's C only.
  Checked here: its `tst/run.sh` (37 checks) passes against
  `env-sdl` `9fea770` too; its demos were not rerun here.
- **E3 is done** (2026-11-16): `sdl.atm` grown to the design, 23 tests
  (also with `ATMOS_ASAN=1`), `doc/api.md`. What differs from the
  design is in `doc/design.md`, 13.
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
