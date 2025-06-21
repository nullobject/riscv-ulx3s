#include <stdint.h>

volatile uint16_t *CHAR_RAM = (uint16_t *)0x2000;
volatile uint16_t *PARAM_RAM = (uint16_t *)0x2800;
volatile uint8_t *LED = (uint8_t *)0x3000;

// Address offset of the first printable ASCII character
#define ASCII_OFFSET 0x20

// Text flags
#define TEXT_NORMAL 0
#define TEXT_INVERT 8

void irq() {}

void clear_params() {
  for (int i = 0; i < 128; i++) {
    PARAM_RAM[i] = 0;
  }
}

void clear_text() {
  for (int i = 0; i < 256; i++) {
    CHAR_RAM[i] = 0;
  }
}

void write_text(char *s, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t i = (row << 5) + col;
  while (*s) {
    char c = *s++ - ASCII_OFFSET;
    CHAR_RAM[i++] = (flags << 12) | c;
  }
}

int __attribute__((noreturn)) main() {
  clear_params();
  clear_text();

  *PARAM_RAM = 0x00FF;
  *LED = *PARAM_RAM;

  write_text("FILTER (1/2)                ++++", TEXT_INVERT, 0, 0);
  write_text("FREQ    RES     ENV     MODE    ", TEXT_NORMAL, 0, 2);
  write_text("1.00    0.01    0.00    LOW PASS", TEXT_NORMAL, 0, 3);
  write_text("----    ----    ----    ----    ", TEXT_NORMAL, 0, 4);
  write_text("ATK     DEC     SUS     REL     ", TEXT_NORMAL, 0, 5);
  write_text("0.64    1.74    0.34    0.44    ", TEXT_NORMAL, 0, 6);
  write_text("----    ----    ----    ----    ", TEXT_NORMAL, 0, 7);

  while (1) {
  }
}
