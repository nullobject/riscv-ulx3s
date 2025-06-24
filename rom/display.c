#include <stdint.h>

volatile uint16_t *CHAR_RAM = (uint16_t *)0x2000;
volatile uint8_t *LED = (uint8_t *)0x3000;
volatile uint16_t *KNOBS = (uint16_t *)0x5000;

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
    CHAR_RAM[i] = 0;
  }
}

void write_text(const char *s, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t i = (row << 5) + col;
  while (*s) {
    char c = *s++;
    CHAR_RAM[i++] = (flags << 12) | c;
  }
}

void write_uint16(uint16_t n, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t j = (row << 5) + col;
  CHAR_RAM[j++] = '$';
  for (int i = 3; i >= 0; i--) {
    char c = HEX_DIGITS[(n >> (i << 2)) & 0x0F];
    CHAR_RAM[j++] = (flags << 12) | c;
  }
}

int __attribute__((noreturn)) main() {
  clear_text();

  uint16_t params[] = {0x0123, 0x4567, 0x89AB, 0xCDEF,
                       0x0123, 0x4567, 0x89AB, 0xCDEF};

  write_text(TOP_BAR, TEXT_NORMAL, 0, 0);
  write_text(BOT_BAR, TEXT_NORMAL, 0, 7);

  write_text("FREQ    RES     ENV     MODE    ", TEXT_NORMAL, 0, 2);
  write_text("ATK     DEC     SUS     REL     ", TEXT_NORMAL, 0, 5);

  while (1) {
    params[0] += *KNOBS;

    write_uint16(params[0], TEXT_NORMAL, 0, 3);
    write_uint16(params[1], TEXT_NORMAL, 8, 3);
    write_uint16(params[2], TEXT_NORMAL, 16, 3);
    write_uint16(params[3], TEXT_NORMAL, 24, 3);
    write_uint16(params[4], TEXT_NORMAL, 0, 6);
    write_uint16(params[5], TEXT_NORMAL, 8, 6);
    write_uint16(params[6], TEXT_NORMAL, 16, 6);
    write_uint16(params[7], TEXT_NORMAL, 24, 6);
  }
}
