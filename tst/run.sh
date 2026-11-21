#!/bin/sh
# Runs the tests of the environment, with no screen and no sound.
#
#   tst/run.sh [name ...]
#
# With no names, runs every tst/*.atm, and then every example
# exs/*/main.atm, as the test with the name of its directory, and every
# exs/d/test-x.atm, as the test `d.x` (a test of the example that
# includes its main.atm). Requires `../atmos-sdl` (see the
# Makefile at the root). Set ATMOS_ASAN=1 to run under the address
# sanitizer.
#
# A test is a program `tst/x.atm`. Its lines that start with `;; env:`
# give the variables of the test mode:
#
#   ;; env: SDL_ATM_FRAMES=10:16 SDL_ATM_KEYS="2:dn:Left Shift"
#
# and a line that starts with `;; args:` gives the arguments of the
# program, and `;; flags:` the options of the compiler (as `--test`, or
# `-t` of a compiler before its long options). They are read by the
# shell. With either, the test runs with no dummy drivers
# of SDL: the environment must open no window that shows and no audio.
#
# The program runs in its own directory.
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
    set -- $(ls *.atm | sed 's/\.atm$//') \
           $(ls ../exs/*/main.atm | sed 's|^\.\./exs/||; s|/main\.atm$||') \
           $(ls ../exs/*/test-*.atm 2>/dev/null | sed 's|^\.\./exs/||; s|/test-|.|; s|\.atm$||')
fi

TST="$PWD"

fail=0
for t in "$@"; do
    t="${t%.atm}"
    rm -f "out/$t.out" "out/$t.err" "out/$t"-*.png
    if [ -e "$t.atm" ]; then
        dir=.
        src="$t.atm"
    elif [ "${t#*.}" != "$t" ]; then
        dir="../exs/${t%%.*}"
        src="test-${t#*.}.atm"
    else
        dir="../exs/$t"
        src=main.atm
    fi
    vars=$(sed -n 's/^;; env: *//p' "$dir/$src" | tr '\n' ' ')
    args=$(sed -n 's/^;; args: *//p' "$dir/$src" | tr '\n' ' ')
    flags=$(sed -n 's/^;; flags: *//p' "$dir/$src" | tr '\n' ' ')
    drivers="SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy"
    case " $flags " in
        *" -t "*|*" --test "*) drivers="-u SDL_VIDEODRIVER -u SDL_AUDIODRIVER" ;;
    esac
    (
        cd "$dir" &&
        eval "env $drivers $vars \
            \"\$TST/../atmos-sdl\" $flags $src $args"
    ) > "out/$t.out" 2> "out/$t.err"
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
