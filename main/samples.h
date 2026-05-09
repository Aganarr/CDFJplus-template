#ifndef SAMPLES_H
#define SAMPLES_H

#include "main.h"

typedef struct
{
    const unsigned char *data;
    unsigned short size;
} Sample;

extern const Sample samples[];

typedef struct
{
    unsigned short data;
    short size;
} RomSample;

extern const RomSample rom_samples[];

#endif