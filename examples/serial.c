#include <stdint.h>

#include "../lib/hal.h"

void irq() { *LED = *UART0; }

void cout(char *a) {
  while (*a) {
    *UART0 = *a++;
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
