#include <stdint.h>

// #define LED ((uint8_t *)0x3000)
volatile uint8_t *LED = (uint8_t *)0x3000;

void delay(uint32_t d) {
  for (uint32_t i = 0; i < d; i++) {
    asm("nop");
  }
}

int __attribute__((noreturn)) main() {
  while (1) {
    *LED = 0xFF;
    delay(131072);
    *LED = 0x00;
    delay(131072);
  }
}
