#include <stdint.h>

#define RDRF 0
#define TDRE 1

volatile uint8_t *UART_DATA = (uint8_t *)0x4000;

void delay(uint32_t d) {
  for (uint32_t i = 0; i < d; i++) {
    asm("nop");
  }
}

void cout(char *a) {
  for (; *a != 0; a++) {
    *UART_DATA = *a;
  }
}

int __attribute__((noreturn)) main() {
  char *line = "HELLO WORLD!\n\r";
  char c = 0;

  while (1) {
    line[0] = '0' + (7 & c++);
    cout(line);
    delay(65535);
  }
}
