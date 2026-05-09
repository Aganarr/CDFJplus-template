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

/******************************* Variables *******************************/

// stay ARM-side
unsigned int rand = 10531789;          // 32 bit LFSR random number
unsigned int frame = 0;                // frame counter
unsigned short game_state = 0;         // internal ARM game state
short sample_size = 0;                 // current digital sample size (bytes)
bool save_key_detected = false;        // save key present flag
unsigned char tv_type = _TV_TYPE_60HZ; // detected TV type

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
static void UpperVBlank();
static void LowerVBlank();

static void HandleControls();

/******************************* External Functions *******************************/

// function defines from ASM_routines.s
// these use ASM with unrolled loops to make them FAST
// use/remove as desired
extern void ClearChannel(void *ptr);
extern void MemCopy32(void *ptr1, const void *ptr2, unsigned int count);
extern void Random(unsigned int count);

/******************************* Entry Point *******************************/
int main()
{

    switch (RAM[_C_routine])
    {
    case _ARM_INIT:
        Initialize();
        break;
    case _ARM_UPPER_VBLANK:
        UpperVBlank();
        break;
    case _ARM_LOWER_VBLANK:
        LowerVBlank();
        break;
    default:
        break;
    }

    frame += 1; // this must be after routine dispatch and within main call

    return 0;
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

        MemCopy32((void *)_WAV_BASE, waveforms, WAVEFORM_SIZE / 4); // waveforms to DD memory

        //  set up demo jump table 1 for kernel_01
        for (int i = 0; i <= 190; i++)
        {
            RAM_2B[(_jump_table_1 / 2) + i] = _kernel_01_loop;
        }
        RAM_2B[(_jump_table_1 / 2) + 191] = _kernel_01_done;

        RAM[_kernel] = kernel;
        RAM[_sound_mode] = sound_mode;
        setPointer(DS31PTR, _kernel); // pass initial state to Atari

        SilenceWaves(); // init DPC waveforms

        break;

    case 1:
        tv_type = _TV_TYPE_60HZ; // force NTSC frame for autodetect purposes

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
            int freq;
            unsigned char fmt;
        } frameTimes[] = {{
                              NTSC_70MHZ,
                              _TV_TYPE_60HZ,
                          },
                          {
                              PAL_70MHZ,
                              _TV_TYPE_50HZ,
                          },
                          {
                              NTSC_60MHZ,
                              _TV_TYPE_60HZ,
                          },
                          {
                              PAL_60MHZ,
                              _TV_TYPE_50HZ,
                          }};

        int max_diff = INT_MAX;
        for (unsigned int i = 0; i < sizeof(frameTimes) / sizeof(struct tv_types); i++)
        {
            int diff = TV_detect_timer - frameTimes[i].freq;
            if (diff < 0)
                diff = -diff;

            if (diff < max_diff)
            {
                max_diff = diff;
                tv_type = frameTimes[i].fmt;
            }
        }

        RAM[_C_routine] = tv_type; // pass tv_type as a 'one time' through _C_routine
        setPointer(31, _C_routine);

        break;

    default:
        break;
    }
}

// upper VBlank dispatcher - includes sample end handler
static void UpperVBlank()
{
    switch (game_state)
    {
    case 0:
        S00_Upper();
        break;
    case 1:
        S01_Upper();
        break;
    case 2:
        S02_Upper();
        break;
    case 3:

        break;
    case 4:

        break;
    case 5:

        break;
    default:
        break;
    }

    if (sound_mode == _SND_MODE_SAMPLE)
    {
        unsigned int size = (getWavePtr(0) >> 13);
        if (size > (sample_size - 64))
        {
            setNote(0, 0);
        }
    }
}

// lower VBlank dispatcher - includes control handler and communication to Atari
static void LowerVBlank()
{
    save_key_detected = (RAM[_SK_DETECT]);

    HandleControls();

    switch (game_state)
    {
    case 0:
        S00_Lower();
        break;
    case 1:
        S01_Lower();
        break;
    case 2:
        S02_Lower();
        break;
    case 3:

        break;
    case 4:

        break;
    case 5:

        break;
    default:
        break;
    }

    Random(1);

    RAM[_kernel] = kernel;
    RAM[_sound_mode] = sound_mode;
    setPointer(DS31PTR, _kernel);
}

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

// Write to SaveKey
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
