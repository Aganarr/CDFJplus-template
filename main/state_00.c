// Each game state's .c file must also be placed
// into the SRC= of makefile

// Each state must include its own .h file
#include "state_00.h"

/**************************** State 00 ****************************/
// test game state 00 - TIA sound mode and SaveKey
void S00_VBlank(void)
{
    RAM[_buffer0] = frame;
    for (int i = 1; i <= 191; i++)
    {
        RAM[_buffer0 + i] = RAM[_buffer0 + i - 1] + 1;
    }
    for (int i = 0; i <= 191; i++)
    {
        RAM[_buffer0 + i] = convertColor(RAM[_buffer0 + i]);
    }
    setPointer(DS0PTR, _buffer0);
}

void S00_Over(void)
{
#if (_ENABLE_WAV_SOUND == 1)
    if (p0_r) // right to change to digital sample sound mode
    {
        kernel = KERNEL_SAMPLE_SOUND;
        game_state = STATE_SAMPLE_SOUND;
        sound_mode = _SND_MODE_SAMPLE;
    }
#endif

#if (_ENABLE_SAVEKEY == 1)
    if (p0_u) // up to write a single byte to EEPROM offset 6
    {
        RAM[_save_data + 6] = 5;
        SaveKeyWrite(save_key_address + 6, 6, 1);
    }

    if (p0_d) // down to write a pair of bytes to EEPROM offset 1
    {
        RAM[_save_data + 1] = 7;
        RAM[_save_data + 2] = 26;
        SaveKeyWrite(save_key_address + 1, 1, 2);
    }

    if (p0_b) // p0 button to read entire 64 byte block
    {
        SaveKeyRead(save_key_address, 0, 64);
    }
#endif
}