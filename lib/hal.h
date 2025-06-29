#ifndef HAL_H
#define HAL_H

#include <stdint.h>

// Text flags
#define TEXT_NORMAL 0
#define TEXT_INVERT 8

extern volatile uint16_t *VRAM;
extern volatile uint8_t *LED;
extern volatile uint8_t *UART;
extern volatile uint16_t *ENCODERS;
extern volatile uint32_t *PRNG;

/**
 * Interrupt request handler.
 */
void irq();

/**
 * Delays by the given number of NOPs.
 */
void delay(uint32_t d);

/**
 * Clear the VRAM.
 */
void clear_text();

/**
 * Write a string to VRAM at the given column and row.
 */
void write_text(const char *s, uint16_t flags, uint8_t col, uint8_t row);

/**
 * Write a 16-bit unsigned integer to VRAM at the given column and row.
 */
void write_uint16(uint16_t n, uint16_t flags, uint8_t col, uint8_t row);

/**
 * Write a 16-bit signed integer to VRAM at the given column and row.
 */
void write_int16(int16_t n, uint16_t flags, uint8_t col, uint8_t row);

#endif
