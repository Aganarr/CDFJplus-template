#include "samples.h"

//	example code to include a file holding a digital sample
//	in the same directory as main.c
const unsigned char sample1[] __attribute__((aligned(4))) = {
#include "sd2.inc"
};
const unsigned int sample1_size = sizeof(sample1);
