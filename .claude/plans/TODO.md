# TODO

Everything that is pending in `env-sdl`. Plan: `261113-env-sdl.md`.

## A. Decisions waiting for the author

Asked one at a time, each with the recommended option.

1. **One file at the root** (asked 2026-11-13): `sdl.atm`, functions in
   one table `sdl`, as `raylib.atm` and `pico.atm`; starts as
   `lib/sdl.atm` of the compiler. Recommended: yes.
2. **Prefix of the event names** (not asked yet): keep `:sdl.` as
   `lib/sdl.atm` and Pingus (`:sdl.key.dn`, `:sdl.mouse.dn`,
   `:sdl.draw`), tags written in one place. Recommended: keep.
3. **One test mode for the three games** (not asked yet):
   `SDL_ATM_FRAMES`, `_KEYS`, `_SHOT`, plus the mouse of Pingus.
   Recommended: yes.
4. **`lib/sdl.atm` leaves the compiler** (not asked yet), when this
   repository has it and its tests; `exs/rocks/` needs a home.
   Recommended: yes, Rocks as an example here.
5. **How a game gets the environment** (not asked yet): a checkout at
   a fixed commit, made by the setup script of the game.
   Recommended: yes.

## B. Work known and not done

- E0: readme, `sdl.atm` from the compiler, runner of tests, first
  tests, Rocks running over it (waits for A1).
- E1: `doc/inventory.md` for the three layers (does not wait).
- E2..E7: see the plan.
- **A fourth client, SuperTux** (`ia-atmos/sdl-tux`, session
  `sdl-tux`, session_011eECoijTqoBzMrEaknmW9P; plan in `ia-atmos/lang`,
  `.claude/plans/261113-sdl-tux.md`), told by the compiler session on
  2026-11-13. It has no layer of its own: it starts over this
  environment from its third milestone on. Expected needs: tilemaps
  drawn fast, sprites, fonts, sounds, a test mode with scripted input
  by tick. Count it in `doc/inventory.md` (E1) as a future client and
  in the design (E2).

## C. Reported or decided, not acknowledged

- (nothing)
