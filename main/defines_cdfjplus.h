/*****************************************************************************
File: defines_cdfjplus.h
Description: CDFJ Plus C Bankswitching Utilities
Chris Walton, Fred Quimby, Darrell Spice Jr, John Champeau
(C) Copyright 2020
******************************************************************************/

#ifndef __CDFJPLUSDEFINES_H
#define __CDFJPLUSDEFINES_H

// Raw queue pointers
void* DDR = (void*)0x40000800;
#define RAM ((unsigned char*)DDR)
#define RAM_2B ((unsigned short int*)DDR)
#define RAM_4B ((unsigned int*)DDR)

#define ROM ((unsigned char*)0)
#define ROM_2B ((unsigned short int*)0)
#define ROM_4B ((unsigned int*)0)

// CDFJ+ DataStream Pointers
#define DS0PTR		0
#define DS1PTR		1
#define DS2PTR		2
#define DS3PTR		3
#define DS4PTR		4
#define DS5PTR		5
#define DS6PTR		6
#define DS7PTR		7
#define DS8PTR		8
#define DS9PTR		9
#define DS10PTR		10
#define DS11PTR		11
#define DS12PTR		12
#define DS13PTR		13
#define DS14PTR		14
#define DS15PTR		15
#define DS16PTR		16`
#define DS17PTR		17
#define DS18PTR		18
#define DS19PTR		19
#define DS20PTR		20
#define DS21PTR		21
#define DS22PTR		22
#define DS23PTR		23
#define DS24PTR		24
#define DS25PTR		25
#define DS26PTR		26
#define DS27PTR		27
#define DS28PTR		28
#define DS29PTR		29
#define DS30PTR		30
#define DS31PTR		31
#define DSCOMM_PTR	32
#define DSJMP1PTR	33
#define DSJMP2PTR	34
#define AMPLITUDE_PTR	35

// Queue variables
unsigned int* const _QPTR=(unsigned int*)0x40000098;
unsigned int* const _QINC=(unsigned int*)0x40000124;
unsigned int* const _WAVEFORM=(unsigned int*)0x400001B0;

// Set fetcher pointer (offset from start of display data)
static void setPointer(const int fetcher, const unsigned int offset) {
  _QPTR[fetcher] = offset << 16;
}



/* Timer 1 */
#define T1IR            (*((volatile unsigned long *) 0xE0008000))
#define T1TCR           (*((volatile unsigned long *) 0xE0008004))
#define T1TC            (*((volatile unsigned long *) 0xE0008008))
#define T1PR            (*((volatile unsigned long *) 0xE000800C))
#define T1PC            (*((volatile unsigned long *) 0xE0008010))
#define T1MCR           (*((volatile unsigned long *) 0xE0008014))
#define T1MR0           (*((volatile unsigned long *) 0xE0008018))
#define T1MR1           (*((volatile unsigned long *) 0xE000801C))
#define T1MR2           (*((volatile unsigned long *) 0xE0008020))
#define T1MR3           (*((volatile unsigned long *) 0xE0008024))
#define T1CCR           (*((volatile unsigned long *) 0xE0008028))
#define T1CR0           (*((volatile unsigned long *) 0xE000802C))
#define T1CR1           (*((volatile unsigned long *) 0xE0008030))
#define T1CR2           (*((volatile unsigned long *) 0xE0008034))
#define T1CR3           (*((volatile unsigned long *) 0xE0008038))
#define T1EMR           (*((volatile unsigned long *) 0xE000803C))
#define T1CTCR          (*((volatile unsigned long *) 0xE0008070))

#define APBDIV          (*((volatile unsigned long *) 0xE01FC100))


// @@@@@@@@@@@@@@@@ this had been commented out in my originals - on testing it does NOT seem to work @@@@@@@@@@@@@
/*	
// Set fetcher pointer and fraction
static void setPointerFrac(const int fetcher, const unsigned int offset,
                           const unsigned int frac) {
  _QPTR[fetcher] = (offset << 16) | (frac << 8);
} */
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 


// Set fetcher increment
static void setIncrement(const int fetcher,
                         const unsigned char whole, const unsigned char frac) {
  _QINC[fetcher] = ((whole << 8) | frac);
}

#ifndef CDFJ_NO_MUSIC

// Set waveform (32-byte offset in display data RAM)
static void setWaveform(int wave, unsigned char offset) {
  _WAVEFORM[wave] = _WAV_BASE + (offset << 5);
//  _WAVEFORM[wave] = 0x40000800 + (offset << 5);
}

// Set DA sample address
static void setSamplePtr(unsigned int address) {
  _WAVEFORM[0] = address;
}

// Set note frequency
static void setNote(int note, unsigned int freq) {
  unsigned int setNoteFn = 0x00000751;
  asm volatile(
    "mov r2, %0\n\t"
    "mov r3, %1\n\t"
    "mov r4, %2\n\t"
    "mov lr, pc\n\t"
    "bx  r4\n\r"
    : : "r" (note), "r" (freq), "r" (setNoteFn)
    : "r2", "r3", "r4", "lr", "cc");
}

// Reset waveform
static void resetWave(int wave) {
  unsigned int resetWaveFn = 0x00000755;
  asm volatile(
    "mov r2, %0\n\t"
    "mov r4, %1\n\t"
    "mov lr, pc\n\t"
    "bx r4\n\r"
    : : "r" (wave), "r" (resetWaveFn)
    : "r2", "r4", "lr", "cc");
}

// Get waveform pointer
static unsigned int getWavePtr(int wave) {
  unsigned int getWavePtrFn = 0x00000759;
  unsigned int ptr;
  asm volatile(
    "mov r2, %1\n\t"
    "mov r4, %2\n\t"
    "mov lr, pc\n\t"
    "bx r4\n\t"
    "mov %0, r2\n\r"
    : "=r" (ptr) : "r" (wave), "r" (getWavePtrFn)
    : "r2", "r4", "lr", "cc");
  return ptr;
}

// Set waveform size:
// 20 = 4096 bytes
// 21 = 2048 bytes (DEFAULT)
// 22 = 1024 bytes
// 23 = 512 bytes
// 24 = 256 bytes
// 25 = 128 bytes
// 26 = 64 bytes
// 27 = 32 bytes
// 28 = 16 bytes
// 29 = 8 bytes
// 30 = 4 bytes
// 31 = 2 bytes
static void setWaveSize(int wave, unsigned int size) {
  unsigned int setWaveSizeFn = 0x0000075d;
  if (size < 20 || size > 31) return;
  asm volatile(
    "mov r2, %0\n\t"
    "mov r3, %1\n\t"
    "mov r4, %2\n\t"
    "mov lr, pc\n\t"
    "bx r4\n\r"
    : : "r" (wave), "r" (size), "r" (setWaveSizeFn)
    : "r2", "r3", "r4", "r5", "lr", "cc");
}

#endif

#ifndef CDFJ_NO_PITCH_TABLE

// Pitch table
const unsigned int _pitchTable[12] = {
  476196134, // C6s   77
  504512230, // D6    78
  534512088, // D6s   79
  566295831, // E6    80
  599969533, // F6    81
  635645578, // F6s   82
  673443031, // G6    83
  713488038, // G6s   84
  755914244, // A7    85
  800863244, // A7s   86
  848485051, // B7    87
  898938597  // C7    88
};

// Calculate frequency for note
static unsigned int getPitch(unsigned int note)
{
  // on the fly frequency calculations.  Saves from having to store
  // 88 values in both ROM and RAM. Note will be 1-88: 1=A0, 88=C7
  int scale = 0;
  while (note < 77) {
    scale++;
    note += 12;
  }
  return (_pitchTable[note-77]) >> scale;
}

#endif

#ifndef CDFJ_NO_RANDOM32

// Generate random number
static unsigned int getRandom32() {
  // using a 32-bit Galois LFSR as a psuedo random number generator.
  // http://en.wikipedia.org/wiki/Linear_feedback_shift_register#Galois_LFSRs
  static unsigned int random = 0x02468ace;
  return random = (random >> 1) ^ (unsigned int)(-(random & 1u) & 0xd0000001u);
}

#endif

#ifndef CDFJ_NO_MEMCOPY

// Set memory area to fill value
static void myMemset(unsigned char* destination, unsigned int fill, unsigned int count) {
  unsigned int i;
  for (i=0; i<count; ++i) {
    destination[i] = fill;
  }
}

// Copy memory from source to destination
static void myMemcpy(unsigned char* destination, unsigned char* source, unsigned int count) {
  unsigned int i;
  for(i = 0; i < count; ++i) {
    destination[i] = source[i];
  }
}

// Set memory area to fill value
// in theory 4x faster than myMemset(), but data must be WORD (4 byte) aligned
static void myMemsetInt(unsigned int* destination, unsigned int fill, unsigned int count) {
  unsigned int i;
  for (i = 0; i < count; ++i) {
    destination[i] = fill;
  }
}

// Copy memory from source to destination
// in theory 4x faster than myMemset(), but data must be WORD (4 byte) aligned
#ifdef CDFJ_MEMCPY_INT
static void myMemcpyInt(unsigned int* destination, unsigned int* source, unsigned int count) {
  unsigned int i;
  for(i = 0; i < count; ++i) {
    destination[i] = source[i];
  }
}
#endif
#endif
#endif

