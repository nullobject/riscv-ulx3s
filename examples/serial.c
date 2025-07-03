#include <stdio.h>

#include "../lib/hal.h"

void irq() { *LED = *UART0; }

int __attribute__((noreturn)) main() {
  *LED = 0x00;

  while (1) {
    printf("Hello World!\n");
    delay(65535);
  }
}
