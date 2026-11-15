# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

## A. Decisions waiting for the author

Asked one at a time, each with the recommended option.

0. **The design, `doc/design.md` (E2)**, shown on 2026-11-14. E3 does
   not start before he sees it. Inside it, besides A2 and A3:
   resources as native values and not indices (recommended: native
   values; the three games change); SNKRX keeps its drawing in the
   game, over a door in C (recommended: yes); the prefix `sdl_atm_`
   for the names of the prelude (recommended: yes).

2. **Names and fields of the events** (the author's, asked by the
   compiler session as its item 46, not by this one): `:key.dn` with
   `key=` or `name=`; `:mouse.mv`, `:mouse.motion`, or
   `:mouse.button.dn`; a frame as the time and `:draw`, `:frame` and
   `:draw`, or `:tick` and `:draw`. Recommended (by the compiler
   session): the vocabulary of `pico.atm`: `:quit`; `:key.dn`,
   `:key.up` with `key`; `:mouse.motion`, `:mouse.button.dn`,
   `:mouse.button.up` with `x`, `y`, `button`; `:frame` then `:draw`.
   Until answered: tags and fields in one place of the file.
3. **One test mode for the three games**:
   `SDL_ATM_FRAMES`, `_KEYS`, `_SHOT`, plus the mouse of Pingus.
   Recommended: yes, with `SDL_ATM_MOUSE`, `SDL_ATM_MUTE`, and `@file`
   for long scripts (`doc/design.md`, 9). Asked on 2026-11-14.
4. **`lib/sdl.atm` leaves the compiler** (not asked yet), when this
   repository has it and its tests; `exs/rocks/` needs a home.
   Recommended: yes, Rocks as an example here.
5. **How a game gets the environment** (not asked yet): a checkout at
   a fixed commit, made by the setup script of the game, which
   builds `atmos-sdl` from it; the game compiles with `atmos-sdl`.
   Recommended: yes.

## B. Work known and not done

- E3..E7: see the plan.
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
