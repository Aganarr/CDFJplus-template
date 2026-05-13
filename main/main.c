/******************************************************************************
CDFJ+ Project Framework
Gamax Software 2026 - Craig Daniels
******************************************************************************/

// #define CDFJ_NO_MUSIC
// #define CDFJ_NO_PITCH_TABLE
#define CDFJ_NO_RANDOM32
// #define CDFJ_NO_MEMCOPY

#include "main.h"

/******************************* Constants/Defines *******************************/

/******************************* Data/Includes *******************************/

#if (_ENABLE_WAV_SOUND == 1)
// 32 byte DPC+ "waveforms" - each range from 1 to 5 with 3 being "center" of waveform
const unsigned char waveforms[] __attribute__((aligned(4))) = {
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 0- wave silence
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, // 1- square
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 4, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, // 2- triangle
    5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, // 3- saw
    3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, // 4- sin
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 5- user waveform 1
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 6- user waveform 2
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  // 7- user waveform 3
};
#define WAVEFORM_SIZE sizeof(waveforms)
#endif

/******************************* Variables *******************************/

// stay ARM-side
unsigned int rand = 10531789;                     // 32 bit LFSR random number
unsigned int frame = 0;                           // frame counter
unsigned short game_state = SHRT_MAX;             // internal ARM game state - do not change this during frame
unsigned short change_state = STATE_00_TIA_SOUND; // desired game state - alter this during frame
short sample_size = 0;                            // current digital sample size (bytes)

#if (_ENABLE_SAVEKEY == 1)
bool save_key_detected = false; // save key present flag
#endif

unsigned char tv_type = _TV_TYPE_60HZ; // code detected TV frequency type
unsigned char tv_color = NTSC;         // user driven TV color

unsigned char TranslatePalColor[] = {0x00, 0x20, 0x20, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0xD0, 0xB0, 0x90, 0x50, 0x70, 0x30, 0x20, 0x40};
unsigned char TranslateSecamColor[] = {0x0, 0xE, 0xC, 0x4, 0x4, 0x6, 0x6, 0x2, 0x2, 0x2, 0x8, 0x8, 0x8, 0x8, 0xC, 0xC};

// to Atari-side
unsigned char kernel = 0;                 // drawing kernel used/passed Atari-side
unsigned char sound_mode = _SND_MODE_TIA; // sound mode used/passed Atari-side
unsigned short save_key_address = 0x2600; // replace with whatever address desired

bool input_flag[15] = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false};
unsigned char input_wait[12] = {14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14};
unsigned char input_repeat[12] = {7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7};
unsigned short input_counter[12] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
unsigned short input_target[12];

/******************************* Framework Functions *******************************/
static void Initialize();
static void VBlank();
static void Overscan();

static void StateChange();

static void HandleControls();

/******************************* External Functions *******************************/

// function defines from ASM_routines.s
// these use ASM with unrolled loops to make them FAST
// use/remove as desired
extern void ClearChannel(void *ptr);
extern void MemCopy32(void *ptr1, const void *ptr2, unsigned int count);
extern void Random(unsigned int count);

// ARM Main handler function names
void (*const VectorMain[])() = {Initialize, VBlank, Overscan};
// Add ARM Init handler function names here - in final game these should change to reflect names of game states
void (*const VectorInit[])() = {S00_Init, S01_Init, S02_Init};
// Add ARM VBlank handler function names here - in final game these should change to reflect names of game states
void (*const VectorVBlank[])() = {S00_VBlank, S01_VBlank, S02_VBlank};
// Add ARM Overscan handler function names here - in final game these should change to reflect names of game states
void (*const VectorOverscan[])() = {S00_Over, S01_Over, S02_Over};

/******************************* Entry Point *******************************/
int main()
{
    (*VectorMain[RAM[_C_routine]])();
    return 0;
}

static void StateChange()
{
    if (game_state != change_state)
    {
        game_state = change_state;
        (*VectorInit[game_state])();
    }

    RAM[_kernel] = kernel;
    RAM[_sound_mode] = sound_mode;
    setPointer(DS31PTR, _kernel);
}

static void Initialize()
{
    static unsigned int TV_detect_timer;

    switch (frame)
    {
    case 0:
        myMemsetInt((void *)_DD_BASE, 0, _DISPLAY_SIZE32); // updates 4 bytes at a time for the entire DD area

        for (int i = 0; i < 34; i++)
            setIncrement(i, 1, 0); // increments to 1

#if (_ENABLE_WAV_SOUND == 1)
        MemCopy32((void *)_WAV_BASE, waveforms, WAVEFORM_SIZE / 4); // waveforms to DD memory
#endif

        //  set up demo jump table 1 for kernel_01
        for (int i = 0; i <= 190; i++)
        {
            RAM_2B[(_jump_table_1 / 2) + i] = _kernel_01_loop;
        }
        RAM_2B[(_jump_table_1 / 2) + 191] = _kernel_01_done;

        StateChange();

#if (_ENABLE_WAV_SOUND == 1)
        SilenceWaves(); // init DPC waveforms
#endif

        break;
#if (_ENABLE_TV_DETECT == 1)
    case 1:
        tv_type = _TV_TYPE_60HZ; // force NTSC frame and color
        tv_color = NTSC;         // for autodetect purposes

        T1TC = 0;
        T1TCR = 1;

        break;
    case _DETECT_FRAME_COUNT + 1:
        TV_detect_timer = T1TC;

#define NTSC_70MHZ (1168170 * _DETECT_FRAME_COUNT)
#define PAL_70MHZ (1178932 * _DETECT_FRAME_COUNT)
#define NTSC_60MHZ (1001289 * _DETECT_FRAME_COUNT)
#define PAL_60MHZ (1010506 * _DETECT_FRAME_COUNT)

        static const struct tv_types
        {
            int cycleCount;
            unsigned char type;
            unsigned char color;
        } frameTimes[] = {
            {NTSC_70MHZ, _TV_TYPE_60HZ, NTSC}, {PAL_70MHZ, _TV_TYPE_50HZ, PAL}, {NTSC_60MHZ, _TV_TYPE_60HZ, NTSC}, {PAL_60MHZ, _TV_TYPE_50HZ, PAL}};

        int max_diff = INT_MAX;
        for (unsigned int i = 0; i < sizeof(frameTimes) / sizeof(struct tv_types); i++)
        {
            int diff = TV_detect_timer - frameTimes[i].cycleCount;
            if (diff < 0)
                diff = -diff;

            if (diff < max_diff)
            {
                max_diff = diff;
                tv_type = frameTimes[i].type;
                tv_color = frameTimes[i].color;
            }
        }

        // tv_color = NTSC; // TV color override here

        RAM[_C_routine] = tv_type; // pass tv_type as a 'one time' through _C_routine
        setPointer(31, _C_routine);

        break;
#endif

    default:
        break;
    }

    frame += 1;
}

// VBlank dispatcher - includes sample end handler
static void VBlank()
{
    (*VectorVBlank[game_state])();

    if (sound_mode == _SND_MODE_SAMPLE)
    {
        unsigned int size = (getWavePtr(0) >> 13);
        if (size > (sample_size - 64))
        {
            setNote(0, 0);
        }
    }
}

// Overscan dispatcher - includes control handler and communication to Atari
static void Overscan()
{
#if (_ENABLE_SAVEKEY == 1)
    save_key_detected = (RAM[_SK_DETECT]);
#endif

    HandleControls();

    (*VectorOverscan[game_state])();

    Random(1);
    frame += 1;

    StateChange();
}

/******************************* Handle Controls/Switches *******************************/
// Controller Handler - converts raw input to debounced pulsed wait and repeat timings
static void HandleControls()
{
    unsigned short SWCH_input = (unsigned short)RAM[_SWCHA];
    if ((RAM[_INPT4] & 0b10000000) != 0)
        SWCH_input |= 0x0100;
    if ((RAM[_INPT5] & 0b10000000) != 0)
        SWCH_input |= 0x0200;
    if ((RAM[_SWCHB] & 0b00000001) != 0)
        SWCH_input |= 0x0400;
    if ((RAM[_SWCHB] & 0b00000010) != 0)
        SWCH_input |= 0x0800;

    CBW_swch = ((RAM[_SWCHB] & 0b00001000) != 0);
    P0_diff = ((RAM[_SWCHB] & 0b01000000) != 0);
    P1_diff = ((RAM[_SWCHB] & 0b10000000) != 0);

    for (int i = 0; i <= 11; i++)
    {
        input_flag[i] = false;
        if ((SWCH_input & 1) == 0)
        {
            input_counter[i]++;
            if (input_counter[i] == 1)
            {
                input_flag[i] = true;
                input_target[i] = input_wait[i] + 1;
            }
            if (input_counter[i] == input_target[i])
            {
                input_flag[i] = true;
                input_target[i] = input_target[i] + input_repeat[i] + 1;
            }
        }
        else
        {
            input_counter[i] = 0;
        }
        SWCH_input = SWCH_input / 2;
    }
}

/******************************* Waveform Routines *******************************/

#if (_ENABLE_WAV_SOUND == 1)
// Used to set waveforms to all silent / no note
void SilenceWaves()
{
    setWaveform(0, WAV_SILENCE);
    setWaveform(1, WAV_SILENCE);
    setWaveform(2, WAV_SILENCE);
    setNote(0, 0);
    setNote(1, 0);
    setNote(2, 0);
}
#endif

// Used to set TIA sound to all silent / no note
void SilenceTIA()
{
    RAM[_AUDV0] = 0;
    RAM[_AUDC0] = 0;
    RAM[_AUDF0] = 0;
    RAM[_AUDV1] = 0;
    RAM[_AUDC1] = 0;
    RAM[_AUDF1] = 0;
}

/******************************* SaveKey Routines *******************************/
// Write to SaveKey

#if (_ENABLE_SAVEKEY == 1)

void SaveKeyWrite(unsigned short address, unsigned char offset, unsigned char count)
{
    RAM_2B[_save_addr_l / 2] = address;
    RAM[_save_count] = count;
    RAM[_save_offset] = offset;
    if (save_key_detected)
        RAM[_save_command] = _SAVE_KEY_WRITE;
}

// Read from SaveKey
void SaveKeyRead(unsigned short address, unsigned char offset, unsigned char count)
{
    RAM_2B[_save_addr_l / 2] = address;
    RAM[_save_count] = count;
    RAM[_save_offset] = offset;
    if (save_key_detected)
        RAM[_save_command] = _SAVE_KEY_READ;
}

#endif

/******************************* Digital Sample Routines *******************************/

#if (_ENABLE_WAV_SOUND == 1)
void playSample(unsigned short sample_id, unsigned int pitch)
{
    MemCopy32((void *)(_DD_BASE + _digital_sample), samples[sample_id].data, samples[sample_id].size / 4);

    resetWave(0);
    setNote(0, pitch);
    setWaveform(0, RAM_SAMPLE);
    sample_size = samples[sample_id].size;
}

void playRomSample(unsigned short sample_id, unsigned int pitch)
{
    resetWave(0);
    setNote(0, pitch);
    setSamplePtr(rom_samples[sample_id].data);
    sample_size = rom_samples[sample_id].size;
}
#endif

/******************************* Color Mode Conversion *******************************/
unsigned char convertColor(unsigned char color)
{
    switch (tv_color)
    {

    case SECAM:
    {
        //  color = secamConvert(color);
        unsigned char c = TranslateSecamColor[color >> 4];
        unsigned char l = color & 0xF;
        if (l >= 0xa)
        {           // if "bright"
            if (!c) // light grey -> white
                c = 0xE;
            else if (c == 2) // blue -> cyan
                c = 0xA;
        }
        if ((l >= 4) && (!c))
            c = 0xa; // med grey -> cyan
        if (l <= 2)
            c = 0; // Dark tone -> black
        color = c;
        // return c
        break;
    }

    case PAL:
        color = TranslatePalColor[color >> 4] | (color & 0xF);
        break;

    default: // anything other than PAL or SECAM just returns original color
        break;
    }

    return color;
}
