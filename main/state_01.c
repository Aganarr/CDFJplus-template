// Each game state's .c file must also be placed
// into the SRC= of makefile

// Each state must include its own .h file
#include "state_01.h"

/**************************** State 01 ****************************/
// test game state 01 - digital sample sound mode
void S01_VBlank(void)
{
    RAM[_buffer0] -= 1;
    for (int i = 1; i <= 191; i++)
    {
        RAM[_buffer0 + i] = RAM[_buffer0 + i - 1] - 1;
    }
    setPointer(DS0PTR, _buffer0);
    setPointer(DSJMP1PTR, _jump_table_1);
}

void S01_Over(void)
{
    if (p0_l) // left to change to TIA sound mode
    {
        game_state = STATE_TIA_SOUND;
        kernel = KERNEL_TIA_SOUND;
        sound_mode = _SND_MODE_TIA;
        SilenceWaves();
    }

    if (p0_r) // right to change to DPC sound mode
    {
        kernel = KERNEL_SAMPLE_SOUND;
        game_state = STATE_DPC_SOUND;
        sound_mode = _SND_MODE_DPC;
        SilenceWaves();
    }

    if (p0_u) // up for sample play from ROM
    {
        playRomSample(0, 1600);
    }

    if (p0_d) // down for sample play from buffer
    {
        playSample(0, 800);
    }
}
