#include <stdint.h>

#include "../lib/hal.h"
#include "../lib/midi.h"

const char TOP_BAR[] = {196, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 212, 0};

const char BOT_BAR[] = {204, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 220, 0};

midi_parser *p = {0};

void irq() {
  midi_message m = midi_parse(p, *UART1);
  if (m.status) {
    *LED = ~*LED;
  }
}

int __attribute__((noreturn)) main() {
  clear_text();

  write_text(TOP_BAR, TEXT_NORMAL, 0, 0);
  write_text(BOT_BAR, TEXT_NORMAL, 0, 7);

  write_text("FREQ    RES     ENV     MODE    ", TEXT_NORMAL, 0, 2);
  write_text("ATK     DEC     SUS     REL     ", TEXT_NORMAL, 0, 5);

  ENCODERS[0] = *PRNG;
  ENCODERS[1] = *PRNG;
  ENCODERS[2] = *PRNG;
  ENCODERS[3] = *PRNG;
  ENCODERS[4] = *PRNG;
  ENCODERS[5] = *PRNG;
  ENCODERS[6] = *PRNG;
  ENCODERS[7] = *PRNG;

  while (1) {
    write_int16(ENCODERS[0] - 32768, TEXT_NORMAL, 0, 3);
    write_uint16(ENCODERS[1], TEXT_NORMAL, 8, 3);
    write_uint16(ENCODERS[2], TEXT_NORMAL, 16, 3);
    write_uint16(ENCODERS[3], TEXT_NORMAL, 24, 3);
    write_uint16(ENCODERS[4], TEXT_NORMAL, 0, 6);
    write_uint16(ENCODERS[5], TEXT_NORMAL, 8, 6);
    write_uint16(ENCODERS[6], TEXT_NORMAL, 16, 6);
    write_uint16(ENCODERS[7], TEXT_NORMAL, 24, 6);
  }
}
