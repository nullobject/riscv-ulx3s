#include <stdint.h>

#include "../lib/hal.h"

void irq() { *LED = *UART; }

void cout(char *a) {
  while (*a) {
    *UART = *a++;
  }
}

int __attribute__((noreturn)) main() {
  char *line = "HELLO WORLD!\n\r";
  *LED = 0x00;

  while (1) {
    cout(line);
    delay(65535);
  }
}
