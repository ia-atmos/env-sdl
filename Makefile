# Builds `atmos-sdl`, the Atmos compiler dedicated to SDL:
#
#   make ATMOS=/path/to/lang
#
# ATMOS is a checkout of https://github.com/ia-atmos/lang, already built
# (`make -C /path/to/lang`). The result is the executable `./atmos-sdl`,
# which compiles and runs a program with `sdl.atm` included and the SDL
# libraries linked:
#
#   cd exs/rocks/ && ../../atmos-sdl main.atm
#
# It keeps depending on that checkout (the runtime), on a C compiler, and
# on the development packages of SDL2, SDL2_image, SDL2_ttf, and
# SDL2_mixer.

ATMOS ?= ../lang
HERE  := $(abspath .)
LIBS  := -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer

.PHONY: all tests clean

all: atmos-sdl

# rebuilt when the environment or the compiler changes
atmos-sdl: sdl.atm $(wildcard $(ATMOS)/atmos)
	@test -x "$(ATMOS)/atmos" || \
	    { echo "make : compiler not found : $(ATMOS)/atmos (set ATMOS=/path/to/lang)"; exit 1; }
	$(MAKE) -C "$(abspath $(ATMOS))" env \
	    OUT="$(HERE)/atmos-sdl" \
	    ENV="$(HERE)/sdl.atm" \
	    ENV_LDFLAGS="$(LIBS)"

tests: atmos-sdl
	tst/run.sh

clean:
	rm -f atmos-sdl
	rm -rf tst/out
