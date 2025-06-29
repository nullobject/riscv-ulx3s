#include <stdbool.h>
#include <stdint.h>

volatile uint16_t *VRAM = (uint16_t *)0x2000;
volatile uint8_t *LED = (uint8_t *)0x3000;
volatile uint16_t *ENCODERS = (uint16_t *)0x5000;
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

/**
 * Clear the VRAM.
 */
void clear_text() {
  for (int i = 0; i < 256; i++) {
    VRAM[i] = 0;
  }
}

/**
 * Write a string to VRAM at the given column and row.
 */
void write_text(const char *s, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t i = (row << 5) + col;
  while (*s) {
    char c = *s++;
    VRAM[i++] = (flags << 12) | c;
  }
}

/**
 * Write a 16-bit unsigned integer to VRAM at the given column and row.
 */
void write_uint16(uint16_t n, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t j = (row << 5) + col;
  VRAM[j++] = '$';
  for (int i = 3; i >= 0; i--) {
    char c = HEX_DIGITS[(n >> (i << 2)) & 0x0F];
    VRAM[j++] = (flags << 12) | c;
  }
}

/**
 * Write a 16-bit signed integer to VRAM at the given column and row.
 */
void write_int16(int16_t n, uint16_t flags, uint8_t col, uint8_t row) {
  char buffer[8];
  char *p = buffer;
  uint16_t value = n < 0 ? -n : n;
  uint16_t j = (row << 5) + col;

  // Add digits
  while (value || p == buffer) {
    int16_t rem = value % 10;
    value /= 10;
    *p++ = rem + '0';
  }

  // Add sign for negative numbers
  if (n < 0) {
    *p++ = '-';
  }

  // Write buffer to VRAM and pad with spaces
  for (int i = 0; i < 8; i++) {
    VRAM[j++] = p > buffer ? *--p : ' ';
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
