#include <stdint.h>

volatile uint8_t *LED = (uint8_t *)0x2000;

void start();

int __attribute__((noreturn)) main() {
  asm("call start");
  __builtin_unreachable();
}

void delay(int d) {
  for (int i = 0; i < d; i++) {
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
  }
}

void start() {
  while (1) {
    *LED = 0xFF;
    delay(65535);
    *LED = 0x00;
    delay(65535);
  }
}
