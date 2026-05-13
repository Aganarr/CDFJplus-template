// Each game state's .c file must also be placed
// into the SRC= of makefile

// Each state must include its own .h file
#include "state_02.h"

/**************************** State 02 ****************************/
// test game state 02 - DPC+ sound mode
void S02_Init(void)
{
    kernel = KERNEL_SAMPLE_SOUND;
    sound_mode = _SND_MODE_DPC;
#if (_ENABLE_WAV_SOUND == 1)
    SilenceWaves();
#endif
}

void S02_VBlank(void)
{
    RAM[_buffer0 + 191] -= 1;
    for (int i = 190; i >= 0; i--)
    {
        RAM[_buffer0 + i] = RAM[_buffer0 + i + 1] - 1;
    }
    setPointer(DS0PTR, _buffer0);
    setPointer(DSJMP1PTR, _jump_table_1);
}

void S02_Over(void)
{

    if (p0_l) // left to change to digital sample sound mode
    {
        change_state = STATE_01_SAMPLE_SOUND;
    }

#if (_ENABLE_WAV_SOUND == 1)
    if (p0_u) // up to play wave channel 0
    {
        setWaveform(0, WAV_TRIANGLE);
        setNote(0, getPitch(58));
    }
    if (p0_r) // right to play wave channel 1
    {
        setWaveform(1, WAV_SQUARE);
        setNote(1, getPitch(60));
    }
    if (p0_d) // down to play wave channel 2
    {
        setWaveform(2, WAV_SAW);
        setNote(2, getPitch(62));
    }
    if (p0_b) // p0 button to silence all wave channels
    {
        SilenceWaves();
    }
#endif
}