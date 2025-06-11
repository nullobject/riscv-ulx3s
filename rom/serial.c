#include <stdint.h>

volatile uint8_t *LED = (uint8_t *)0x3000;
volatile uint8_t *UART = (uint8_t *)0x4000;

void irq() { *LED = *UART; }

void delay(uint32_t d) {
  for (uint32_t i = 0; i < d; i++) {
    asm("nop");
  }
}

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
