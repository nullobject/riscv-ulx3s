#include <stdbool.h>
#include <stdint.h>

volatile uint16_t *VRAM = (uint16_t *)0x2000;
volatile uint8_t *LED = (uint8_t *)0x3000;
volatile uint16_t *KNOBS = (uint16_t *)0x5000;
volatile uint32_t *PRNG = (uint32_t *)0x6000;

const char HEX_DIGITS[] = "0123456789ABCDEF";

const char TOP_BAR[] = {196, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 212, 0};

const char BOT_BAR[] = {204, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 220, 0};

// Text flags
#define TEXT_NORMAL 0
#define TEXT_INVERT 8

void irq() { /* do nothing */ }

void clear_text() {
  for (int i = 0; i < 256; i++) {
    VRAM[i] = 0;
  }
}

void write_text(const char *s, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t i = (row << 5) + col;
  while (*s) {
    char c = *s++;
    VRAM[i++] = (flags << 12) | c;
  }
}

void write_uint16(uint32_t n, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t j = (row << 5) + col;
  VRAM[j++] = '$';
  for (int i = 3; i >= 0; i--) {
    char c = HEX_DIGITS[(n >> (i << 2)) & 0x0F];
    VRAM[j++] = (flags << 12) | c;
  }
}

// void write_int16(int16_t n, uint16_t flags, uint8_t col, uint8_t row) {
//   char buffer[8];
//   char *p = buffer;
//   uint16_t value = n < 0 ? -n : n;
//   uint16_t j = (row << 5) + col;
//
//   // Add digits
//   while (value || p == buffer) {
//     int16_t rem = value % 10;
//     value /= 10;
//     *p++ = rem + '0';
//   }
//
//   // Add sign for negative numbers
//   if (n < 0) {
//     *p++ = '-';
//   }
//
//   // Write buffer to VRAM and pad with spaces
//   for (int i = 0; i < 8; i++) {
//     CHAR_RAM[j++] = p > buffer ? *--p : ' ';
//   }
// }

int __attribute__((noreturn)) main() {
  clear_text();

  write_text(TOP_BAR, TEXT_NORMAL, 0, 0);
  write_text(BOT_BAR, TEXT_NORMAL, 0, 7);

  write_text("FREQ    RES     ENV     MODE    ", TEXT_NORMAL, 0, 2);
  write_text("ATK     DEC     SUS     REL     ", TEXT_NORMAL, 0, 5);

  KNOBS[0] = *PRNG;
  KNOBS[1] = *PRNG;
  KNOBS[2] = *PRNG;
  KNOBS[3] = *PRNG;
  KNOBS[4] = *PRNG;
  KNOBS[5] = *PRNG;
  KNOBS[6] = *PRNG;
  KNOBS[7] = *PRNG;

  while (1) {
    write_uint16(KNOBS[0], TEXT_NORMAL, 0, 3);
    write_uint16(KNOBS[1], TEXT_NORMAL, 8, 3);
    write_uint16(KNOBS[2], TEXT_NORMAL, 16, 3);
    write_uint16(KNOBS[3], TEXT_NORMAL, 24, 3);
    write_uint16(KNOBS[4], TEXT_NORMAL, 0, 6);
    write_uint16(KNOBS[5], TEXT_NORMAL, 8, 6);
    write_uint16(KNOBS[6], TEXT_NORMAL, 16, 6);
    write_uint16(KNOBS[7], TEXT_NORMAL, 24, 6);
  }
}
