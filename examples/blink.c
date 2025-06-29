#include <stdint.h>

#include "../lib/hal.h"

void irq() { /* do nothing */ }

int __attribute__((noreturn)) main() {
  while (1) {
    *LED = 0xFF;
    delay(131072);
    *LED = 0x00;
    delay(131072);
  }
}
