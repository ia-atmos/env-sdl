# Requests of `sdl-tux`

Received from the session `sdl-tux` (`ia-atmos/sdl-tux`, the port of
SuperTux v0.7.0) on 2026-11-14. Input for `doc/inventory.md` (E1) and
for the design (E2). Tux has no platform layer of its own. It works
with no screen until the environment has what it can build on; it
asked to be told when, and at which commit.

In its order of need:

1. **Test mode with no screen**: N frames then exit; scripted keys by
   frame (`frame:dn|up:key`); a screenshot at a frame; mute; no frame
   cap. The variables may be those of the environment (`SDL_ATM_*`).
2. **The frame as an event with the real elapsed time**, and nothing
   else done with the time. The game steps its logic in fixed ticks
   of 15 ms with an accumulator (0 to 4 ticks per frame) and emits
   its own `:tick`. In the test mode, a frame must be able to be
   exactly one tick (a fixed dt of 15 ms).
3. **Keys**: `:key.dn`, `:key.up`, with a name. No mouse and no
   controller in the first version.
4. **Images**: load PNG; draw a region (source rectangle) at a
   position, with horizontal and vertical flip, scale, rotation,
   alpha, and a color to modulate. Blend modes later (additive).
5. **Many draws per frame**: 2000 to 4000 region draws (40x25 tiles
   of 32 px, two to four layers), plus sprites. A call from Atmos per
   tile is too slow, so the tiles are drawn in C of the game. It
   needs **a C-level door**: from the C of the game, the
   `SDL_Renderer*` of the environment and the `SDL_Texture*` behind
   an image handle, as a documented function or macro of the prelude.
6. **Filled rectangles with alpha**; a vertical gradient (may be of
   the game, over the C door).
7. **Text**: TTF fonts, UTF-8, with a color; the width and height of
   a text.
8. **Sound**: wav and ogg, several at once, with a volume. Music in
   ogg that loops between two points (`loop-begin`, `loop-at`, in
   seconds), fade out, and a change of music.
9. **A logical size** of 1280x800, scaled to the window.

Not needed: mouse; software surfaces (it compares screenshots with a
tolerance); render targets (until lights, in a second version).

## Notes for the design

- Item 5 is a question for E2 and for the other three games too: a
  documented C interface of the prelude, besides the Atmos one.
- Item 2 touches the open decision on the events of a frame
  (`TODO.md`, A2): Tux wants one frame event with the elapsed time,
  and a fixed dt in the test mode.
