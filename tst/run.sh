#!/bin/sh
# Runs the tests of the environment, with no screen and no sound.
#
#   tst/run.sh [name ...]
#
# With no names, runs every tst/*.atm. Requires `../atmos-sdl` (see the
# Makefile at the root). Set ATMOS_ASAN=1 to run under the address
# sanitizer.
#
# A test is a program `tst/x.atm`. Its lines that start with `;; env:`
# give the variables of the test mode:
#
#   ;; env: SDL_ATM_FRAMES=10:16 SDL_ATM_KEYS=2:dn:A
#
# The program runs in `tst/`.
# Its standard output is its trace: it must be equal to `tst/x.out`.
# Each image `tst/x-*.png` must be equal, pixel by pixel, to the
# `tst/out/x-*.png` that the program saves. A test must also exit with 0.
#
# Set SDL_ATM_ACCEPT=1 to write the traces and the images of the tests
# as the expected ones, after looking at them.

cd "$(dirname "$(realpath "$0")")" || exit 1

if [ ! -x ../atmos-sdl ]; then
    echo "tst/run.sh : ../atmos-sdl not found : run make ATMOS=/path/to/lang" >&2
    exit 1
fi

mkdir -p out
if [ ! -x out/pngcmp ] || [ ../tools/pngcmp.c -nt out/pngcmp ]; then
    ${CC:-cc} -O1 ../tools/pngcmp.c -lSDL2 -lSDL2_image -o out/pngcmp || exit 1
fi

# ATMOS_ASAN=1: ignores the leaks of the libraries under SDL
if [ -n "$ATMOS_ASAN" ] && [ -z "$LSAN_OPTIONS" ]; then
    export LSAN_OPTIONS="suppressions=$PWD/lsan.supp:print_suppressions=0"
fi

if [ $# -eq 0 ]; then
    set -- $(ls *.atm | sed 's/\.atm$//')
fi

fail=0
for t in "$@"; do
    t="${t%.atm}"
    rm -f "out/$t.out" "out/$t.err" "out/$t"-*.png
    vars=$(sed -n 's/^;; env: *//p' "$t.atm" | tr '\n' ' ')
    env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy $vars \
        ../atmos-sdl "$t.atm" > "out/$t.out" 2> "out/$t.err"
    code=$?
    if [ -n "$SDL_ATM_ACCEPT" ] && [ $code -eq 0 ]; then
        cp "out/$t.out" "$t.out"
        for f in "out/$t"-*.png; do
            [ -e "$f" ] && cp "$f" .
        done
    fi
    why=""
    if [ $code -ne 0 ]; then
        why="exit $code (see tst/out/$t.err)"
    elif ! cmp -s "out/$t.out" "$t.out"; then
        why="trace differs (diff tst/$t.out tst/out/$t.out)"
    else
        for f in "$t"-*.png; do
            [ -e "$f" ] || continue
            if [ ! -e "out/$f" ]; then
                why="image not saved : $f"
            elif ! out/pngcmp "$f" "out/$f" > "out/$f.cmp"; then
                why="image differs : $f ($(head -n 1 "out/$f.cmp"))"
            fi
        done
        for f in "out/$t"-*.png; do
            [ -e "$f" ] || continue
            [ -e "$(basename "$f")" ] || why="image not expected : $f"
        done
    fi
    if [ -z "$why" ]; then
        echo "OK   $t"
    else
        echo "FAIL $t    $why"
        fail=1
    fi
done

if [ $fail -eq 0 ]; then
    echo "All tests passed!"
fi
exit $fail
