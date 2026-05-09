#ifndef MAIN_H
#define MAIN_H


#include "defines_dasm.h" // defines_dasm.h MUST come before defines_cdfjplus.h

// KEEP ABOVE 'WHITESPACE' LINE
#include "defines_cdfjplus.h" // <- contains references from defines_dasm.h
#include "tia_constants_c.h"

#include <limits.h>
#include <stdbool.h>

/**************************** External .c code headers ****************************/
#include "samples.h"
#include "state_00.h"
#include "state_01.h"
#include "state_02.h"


/******************************* Constants/Defines *******************************/
#define WAV_SILENCE 0
#define WAV_SQUARE 1
#define WAV_TRIANGLE 2
#define WAV_SAW 3
#define WAV_SIN 4
#define RAM_SAMPLE 8 // for 64k+ ROMs samples can be held in DD RAM - this assumes
// it remains directly after the waveform RAM

#ifndef __GNUC__
#define __attribute__(x)
#endif


/******************************* Structures *******************************/



/******************************* Variables *******************************/
// stay ARM-side
extern unsigned int rand;                   // 32 bit LFSR random number
extern unsigned int frame;                  // frame counter
extern unsigned short game_state;           // internal ARM game state
extern short sample_size;                   // current digital sample size (bytes)
extern bool save_key_detected;              // save key present flag
extern unsigned char tv_type;               // detected TV type

// to Atari-side
extern unsigned char kernel;                // drawing kernel used/passed Atari-side
extern unsigned char sound_mode;            // sound mode used/passed Atari-side
extern unsigned short save_key_address;     // replace with whatever address desired

// Atari input direct access variables - joysticks and RESET/SELECT are
// automatically wait/repeat handled
extern bool input_flag[15];
#define p1_u input_flag[0]
#define p1_d input_flag[1]
#define p1_l input_flag[2]
#define p1_r input_flag[3]
#define p0_u input_flag[4]
#define p0_d input_flag[5]
#define p0_l input_flag[6]
#define p0_r input_flag[7]
#define p0_b input_flag[8]
#define p1_b input_flag[9]
#define RESET_swch input_flag[10]
#define SELECT_swch input_flag[11]
#define P0_diff input_flag[12]
#define P1_diff input_flag[13]
#define CBW_swch input_flag[14]

// for each control user can assign a number of frames in between
// the first press acknowledge and the second, default 14
// use 0 to bypass the wait timer
extern unsigned char input_wait[12];
#define p1_u_wait input_wait[0]
#define p1_d_wait input_wait[1]
#define p1_l_wait input_wait[2]
#define p1_r_wait input_wait[3]
#define p0_u_wait input_wait[4]
#define p0_d_wait input_wait[5]
#define p0_l_wait input_wait[6]
#define p0_r_wait input_wait[7]
#define p0_b_wait input_wait[8]
#define p1_b_wait input_wait[9]
#define RESET_swch_wait input_wait[10]
#define SELECT_swch_wait input_wait[11]

// for each control user can assign a number of frames in between
// the second acknowledge and any after, default 7
// use 0 to bypass the repeat timer
extern unsigned char input_repeat[12];
#define p1_u_repeat input_repeat[0]
#define p1_d_repeat input_repeat[1]
#define p1_l_repeat input_repeat[2]
#define p1_r_repeat input_repeat[3]
#define p0_u_repeat input_repeat[4]
#define p0_d_repeat input_repeat[5]
#define p0_l_repeat input_repeat[6]
#define p0_r_repeat input_repeat[7]
#define p0_b_repeat input_repeat[8]
#define p1_b_repeat input_repeat[9]
#define RESET_swch_repeat input_repeat[10]
#define SELECT_swch_repeat input_repeat[11]

// internal control handling variables - no need for direct user access
extern unsigned short input_counter[12];
extern unsigned short input_target[12];


// Any additional shared user variables here



/******************************* Framefork Functions *******************************/
void SaveKeyWrite(unsigned short address, unsigned char offset, unsigned char count);
void SaveKeyRead(unsigned short address, unsigned char offset, unsigned char count);

void SilenceWaves();
void SilenceTIA();

void playSample (unsigned short sample_id, unsigned int pitch);
void playRomSample (unsigned short sample_id, unsigned int pitch);

/******************************* Shared User Functions *******************************/



#endif