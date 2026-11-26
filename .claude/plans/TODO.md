# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

Items are `#N` (the author's standing rule of 2026-11-18): a number is
unique in this session, never reused nor changed; from another session
an item is `env-sdl#N`. The identifiers used before (`A1`..`A5`,
`E0`..`E7`) stay valid for what was written with them.

## Index

States: **open** (waits for the author), **work** (known, not started,
no decision needed), **waits** (waits for another session), **told**
(reported, not acknowledged), **done**, **closed**.

| # | Item | State |
|---|------|-------|
| 1 | E5: SNKRX over the environment | done (2026-11-21), acknowledged |
| 2 | E6: Flare over the environment | done (2026-11-25): on its main (`sdl-flare` `8748120`, the author's `sdl-flare#11a`), pinned at `79940a9`, all identical |
| 3 | E7: what was learned | done (2026-11-25): `doc/learned.md`, acknowledged |
| 4 | `sdl.atm` over `atmos.env [step, quit, mode]` | work, not asked; no environment has moved to it yet |
| 5 | Screenshots with text depend on the version of FreeType | work |
| 6 | `sdl.draw_ex`: flips, rotation, tint (Tux) | done (2026-11-20) |
| 7 | Loop points of a music (Tux) | done (2026-11-20) |
| 8 | Blend modes at the draw (Flare) | done (2026-11-20), in `sdl.draw_ex` |
| 9 | `doc/inventory/pingus.md` out of date | done (2026-11-20): marked as a picture of E1 |
| 10 | `:step [us]`, the scaled time once per frame (SNKRX) | closed (2026-11-21): #10a confirmed by the author, no `:step` here |
| 11 | A test of the pause of Rocks | done (2026-11-20): `exs/rocks/test-pause.atm` |
| 12 | The order of a frame of `sdl.atm` is the order of all environments | closed (2026-11-21): acknowledged |
| 13 | No window and no audio under `--test` (test blocks), and `sdl.test` | done, confirmed by the author (2026-11-21) |
| 14 | `sdl.atm` under the numeric options of the compiler | done (2026-11-20) |
| 15 | The rename of the numeric options (`A_CLOCK_US`, `ATMOS_FLOAT/INTEGER/CLOCK`) | done (2026-11-20), works before and after the merge of `float` |
| 16 | `sdl.window [clear=false]`, asked by SNKRX | done (2026-11-21) |
| 17 | The test flag is `--test`: switch `tst/minus-t.atm` from `-t` when the compiler has it | waits: `atmos-cli` (its #2, branch `cli`) |
| 18 | The kinds of native values are `char[]`, not string literals (broke under LTO) | done (2026-11-25), a defect fix under #95 |
| 19 | From Flare: `sdl_sfc` converts in the software path; the mouse scaled by SDL (`SDL_RenderSetLogicalSize`) there too | done (2026-11-25) |
| 20 | From Flare: fonts with a TTF style, Solid or Blended (it keeps them in C) | work, if asked |
| 21 | Excerpt, idiomatic: the pause of Rocks (`exs/rocks/main.atm:124-136`) | shown 2026-11-26 |
| 22 | Excerpt, bad: `sdl.draw_ex` (`sdl.atm:1200-1213`) | shown 2026-11-26 |

## A. Decisions waiting for the author

(none)

## B. Work known and not done

- **#1 E5: SNKRX over the environment**, with its session, after its
  baseline (`2bddee7` or later) and its migration to the rules of
  `pin`. SNKRX keeps its drawing (canvases, geometry, shadow) in its
  own C over the door; it needs `passes=[:draw, :overlay]`,
  `sdl_on_flush`, `fixed=true`, and `sdl.clock`, all built. Not told
  to start yet.
- **#2 E6: Flare over the environment**: the software path,
  `sdl.image(path, raw)`, `code` in the key events; its `FLARE_INPUT`
  needs a converter to `SDL_ATM_*` (no scripted quit exists).
- **#3 E7**: what the layers had in common, what each game changed,
  the cost (lines, speed). Pingus: `engine/pingus.h` 930 -> 591 lines.
- **#4** Environments may register with `atmos.env [step, quit,
  mode]` (`lang` `81986e7`, manual "Environments"). Moving `sdl.atm`
  to it is not asked yet (`atmos-envs`, 2026-11-17).
- **#5** The expected images with text (`tst/text-2.png`,
  `tst/software-2.png`, `tst/rocks-*.png`) are from SDL2_ttf 2.22 of
  Ubuntu 24.04. Settle when another setup runs the tests (a
  tolerance, or a fixed setup).
- **#6, #7** Not built in E3, for when Tux needs them: a draw with
  flips, rotation, and tint (`SDL_RenderCopyEx`, color and alpha
  modulation); a music that loops between two points. Tux was told.
- **#8** Blend modes at the draw: Flare draws additively over the
  door in C today; only if it asks.
- **#9** `doc/inventory/pingus.md` (read at `45ea8be`) is out of date
  in `res_desc`, `LANG`, and `Sprite`, and Pingus has moved since.
  Either update it or mark it as a picture of the layer before the
  move.
- **#10** SNKRX may ask for `:step [us]` (the scaled time of the
  frame, once per frame), if the author decides its finding 8
  (physics stepped once per frame). Not to build before that.
- **#11** The pause of Rocks has no test (it was run by hand); it
  needs a second run of the game, with other expected images.

- **#13** Pingus pilots a test as a `test` block (`atmos-lang#76`)
  instead of variables; it may ask how the environment avoids opening
  a window under `-t` (`atmos-envs` A3). Nothing to do until it asks.

- **#14 (done)** Under the numeric options of `lang` `692af43`
  (`ATMOS_REAL=float`, `ATMOS_INT=32`, `ATMOS_TIME=ms`): the clock was
  emitted in microseconds whatever the unit; now in the unit of the
  build, with the rest carried. Rocks divided clocks by `1000000`; now
  by `1s`. All tests pass under each option and all together, except
  `tst/clock` under `ms`, whose trace is of the default unit (the
  clock goes in whole milliseconds there). Tux builds under
  `ATMOS_REAL=float` (`atmos-lang` told). Which options an
  environment supports is open with the author (`atmos-float#14`).

- **#13 (done, confirmed by the author on 2026-11-21, who named the
  flag `--test`)**: under `--test` (`-t` today), a
  `test` block of `sdl.atm` sets `SDL_TEST`: the window uses the dummy
  driver (unless `SDL_VIDEODRIVER` names another), the audio is not
  opened, `sdl.testing()` is true; `sdl.test.key/mouse/clear/shot`.
  The video and the audio are now opened when used (the window, the
  first sound), not at the start. As proposed in `atmos-envs#3b`,
  which waits for the author; reversible. Checked: the 26 tests here,
  `tst/minus-t.atm` with no dummy drivers, the suite of Pingus, and its
  `bomber-test.atm` with no dummy drivers.

- **#10 (closed: #10a, confirmed by the author on 2026-11-21)**: the
  recommendation: the environment emits no `:step`; if the author says
  yes to SNKRX's finding 8, SNKRX emits its own step from `:frame`
  (`e.us` times its factor, with its own carry). Nothing built; told
  to SNKRX. Undo: build `:step [us]` after the clock (#10b).

- **#1 (E5 done)**: SNKRX moved over `94cb414` (`sdl-snkrx`
  `8d2f653`): 39 of its 40 tests identical, traces and screenshots; the
  40th prints the new names of the events, by design. Its `eng.h` went
  from 1213 to 1040 lines; it keeps its drawing, its sounds and its
  physics, over the door. Its cost: 18.07 s against 16.62 s on its
  stress scenario, 0.82 s of it the clear before the passes, which
  `sdl.window [clear=false]` (#16) now skips. Not checked here (its
  suite needs Box2D).

## C. Reported or decided, not acknowledged

(none: the author acknowledged #12 and confirmed #13 and #10a on
2026-11-21; the history is in `git log` of this file.)

## Standing recommendations of the author

- At each big step (a milestone, a feature that changes what is on
  screen), show him a few screenshots in the report (2026-11-26, said
  in `pico-1oom`, relayed by `atmos`).
- For each group of changes, show him one pair of Atmos excerpts from
  that work: one idiomatic, one bad (awkward, verbose, a workaround),
  short, with file and line (2026-11-26, said in `atmos`).
  Each excerpt has a number `#N` in the index, and a bad one says why
  and what would make it better (2026-11-26, his additions).
- Read `ia-atmos/lang` `.claude/plans/IDIOMS.md` before writing Atmos
  (2026-11-26, `atmos#29`): the rules that came out of his reviews,
  each with a before and an after. A general rule that comes out of
  his review of an excerpt here goes to `atmos`, with its source
  `env-sdl#N`.

## D. Sessions to talk to

- Coordination, status, and questions for the author: `atmos`,
  session_011eECohhJbc4GMpAj3yyeEo (since 2026-11-24,
  `atmos-lang#119`).
- The compiler: `atmos-lang` (formerly `ceu-atmos`),
  session_011eECogKVQ7ZzmWCoMST2wK: measurements on the ports, merges
  into `main` of `lang`, and everything but `pin`.
- The rules of `pin`: `atmos-pin`, session_011eECogSDhkVfyt7qme5DLh
  (the author's decision, 2026-11-18), with a small program.
- The games: `pingus` session_011eECoent86e4ta3otsCoEa, `snxkx`
  session_011eECohRKf757Ydp2i9w7Ng, `flare`
  session_011eECoegYsZr7nSPxcugGtt, `sdl-tux`
  session_011eECoijTqoBzMrEaknmW9P.
- The other environments: `env-ray` session_011eECohyySVpgZiuUF17qc2,
  `env-pico` session_011eECoikzsmBiPNXNF7ffpf; `atmos-envs`, where
  the author discusses all of them, session_011eECofYWTNPACTtUjHN4p6.

## E. Done

- E0 (2026-11-14), E1 (2026-11-14), E2 (approved 2026-11-16), E3
  (2026-11-16), E4 Pingus (2026-11-17). Details in the plan and in
  `git log`.
