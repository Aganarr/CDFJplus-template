/*****************************************************************************
File: defines_cdfjplus.h
Description: CDFJ Plus C Bankswitching Utilities
Chris Walton, Fred Quimby, Darrell Spice Jr, John Champeau
(C) Copyright 2020
Split into separate .h and .c files by Craig Daniels - Gamax Software - 2026
******************************************************************************/

#ifndef __CDFJPLUSDEFINES_H
#define __CDFJPLUSDEFINES_H

#include "defines_dasm.h"

#include "defines_cdfjplus.h"

// Raw queue pointers
extern void* DDR;
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
extern unsigned int* const _QPTR;
extern unsigned int* const _QINC;
extern unsigned int* const _WAVEFORM;

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

void setPointer(const int fetcher, const unsigned int offset);
void setIncrement(const int fetcher, const unsigned char whole, const unsigned char frac);

#ifndef CDFJ_NO_MUSIC
void setWaveform(int wave, unsigned char offset);
void setSamplePtr(unsigned int address);
void setNote(int note, unsigned int freq);
void resetWave(int wave);
unsigned int getWavePtr(int wave);
void setWaveSize(int wave, unsigned int size);
#endif

#ifndef CDFJ_NO_PITCH_TABLE
extern const unsigned int _pitchTable[12];
unsigned int getPitch(unsigned int note);
#endif

#ifndef CDFJ_NO_RANDOM32
unsigned int getRandom32() ;
#endif

#ifndef CDFJ_NO_MEMCOPY
void myMemset(unsigned char* destination, unsigned int fill, unsigned int count) ;
void myMemcpy(unsigned char* destination, unsigned char* source, unsigned int count) ;
void myMemsetInt(unsigned int* destination, unsigned int fill, unsigned int count) ;
void myMemcpyInt(unsigned int* destination, unsigned int* source, unsigned int count) ;
#endif
#endif


