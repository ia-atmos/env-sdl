# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

## A. Decisions waiting for the author

Asked one at a time, each with the recommended option.

(none: everything asked was answered on 2026-11-16)

## B. Work known and not done

- **E5: SNKRX over the environment**, with its session, after its
  baseline (`2bddee7` or later) and its migration to the new rules of
  `pin`, which waits for the author. Not told to start yet.
- **`atmos.env [step, quit, mode]`** (`lang` `81986e7`, manual
  "Environments"): environments may now register in Atmos. Moving
  `sdl.atm` to it is not asked yet (told by the session `envs`,
  2026-11-17).
- **The screenshots with text depend on the version of FreeType**
  (`tst/text-2.png`, `tst/software-2.png`, `tst/rocks-*.png`): the
  expected images are from SDL2_ttf 2.22 of Ubuntu 24.04. Settle when
  another setup runs the tests (a tolerance, or a fixed setup).
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

## D. Sessions to talk to

- The compiler: `atmos-lang` (formerly `ceu-atmos`),
  session_011eECogKVQ7ZzmWCoMST2wK. Everything but `pin`.
- The rules of `pin`: `atmos-pin`, session_011eECogSDhkVfyt7qme5DLh
  (the author's decision, 2026-11-18), with a small program.
- The games: `pingus` session_011eECoent86e4ta3otsCoEa, `snxkx`
  session_011eECohRKf757Ydp2i9w7Ng, `flare`
  session_011eECoegYsZr7nSPxcugGtt, `sdl-tux`
  session_011eECoijTqoBzMrEaknmW9P.
- The other environments: `env-ray` session_011eECohyySVpgZiuUF17qc2,
  `env-pico` session_011eECoikzsmBiPNXNF7ffpf; `envs`, where the
  author discusses all of them, session_011eECofYWTNPACTtUjHN4p6.

## C. Reported or decided, not acknowledged

(none: everything up to 2026-11-17 acknowledged by the author on
2026-11-18. The history is in `git log` of this file.)
