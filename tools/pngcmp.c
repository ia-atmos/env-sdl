// Compares two images, pixel by pixel.
//
//      pngcmp a.png b.png
//
// Exits with 0 if they have the same size and the same pixels, and with 1
// otherwise, after saying where the first difference is.

#include <stdio.h>
#include <string.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>

static SDL_Surface* load (const char* path) {
    SDL_Surface* raw = IMG_Load(path);
    if (raw == NULL) {
        fprintf(stderr, "pngcmp : %s\n", IMG_GetError());
        return NULL;
    }
    SDL_Surface* sfc = SDL_ConvertSurfaceFormat(raw, SDL_PIXELFORMAT_RGBA32, 0);
    SDL_FreeSurface(raw);
    return sfc;
}

int main (int argc, char** argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: pngcmp a.png b.png\n");
        return 2;
    }
    SDL_Surface* a = load(argv[1]);
    SDL_Surface* b = load(argv[2]);
    if (a==NULL || b==NULL) {
        return 2;
    }
    if (a->w!=b->w || a->h!=b->h) {
        printf("pngcmp : sizes differ : %dx%d vs %dx%d\n", a->w, a->h, b->w, b->h);
        return 1;
    }
    int n = 0;
    for (int y=0; y<a->h; y++) {
        Uint8* pa = (Uint8*)a->pixels + y*a->pitch;
        Uint8* pb = (Uint8*)b->pixels + y*b->pitch;
        for (int x=0; x<a->w; x++) {
            if (memcmp(pa+4*x, pb+4*x, 4) != 0) {
                if (n == 0) {
                    printf("pngcmp : pixel (%d,%d) differs : "
                        "%02x%02x%02x%02x vs %02x%02x%02x%02x\n", x, y,
                        pa[4*x], pa[4*x+1], pa[4*x+2], pa[4*x+3],
                        pb[4*x], pb[4*x+1], pb[4*x+2], pb[4*x+3]);
                }
                n++;
            }
        }
    }
    if (n > 0) {
        printf("pngcmp : %d pixels differ\n", n);
    }
    return (n == 0) ? 0 : 1;
}
