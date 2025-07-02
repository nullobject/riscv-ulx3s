#include "hal.h"

volatile uint16_t *VRAM = (uint16_t *)0x8000;
volatile uint8_t *LED = (uint8_t *)0x9000;
volatile uint8_t *UART0 = (uint8_t *)0xA000;
volatile uint8_t *UART1 = (uint8_t *)0xA004;
volatile uint16_t *ENCODERS = (uint16_t *)0xB000;
volatile uint32_t *PRNG = (uint32_t *)0xC000;

const char HEX_DIGITS[] = "0123456789ABCDEF";

void delay(uint32_t d) {
  for (uint32_t i = 0; i < d; i++) {
    asm("nop");
  }
}

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

void write_uint16(uint16_t n, uint16_t flags, uint8_t col, uint8_t row) {
  uint8_t j = (row << 5) + col;
  VRAM[j++] = '$';
  for (int i = 3; i >= 0; i--) {
    char c = HEX_DIGITS[(n >> (i << 2)) & 0x0F];
    VRAM[j++] = (flags << 12) | c;
  }
}

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
