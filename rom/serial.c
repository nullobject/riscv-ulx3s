#include <stdint.h>

#define RDRF 0
#define TDRE 1

volatile uint8_t *UART_CTRL = (uint8_t *)0x4000;
volatile uint8_t *UART_DATA = (uint8_t *)0x4004;

void delay(uint32_t d) {
  for (uint32_t i = 0; i < d; i++) {
    asm("nop");
  }
}

void serial_init(void) {
  *UART_CTRL = 3; // reset UART
  delay(10);
  *UART_CTRL = 0x95; // RTS enabled 9600
}

void cout(char *a) {
  for (; *a != 0; a++) {
    while ((*UART_CTRL & (1 << TDRE)) == 0) {
      // wait
    }
    *UART_DATA = *a;
  }
}

int __attribute__((noreturn)) main() {
  char *line = "HELLO WORLD!\n\r";
  char c = 0;

  serial_init();

  while (1) {
    line[0] = '0' + (7 & c++);
    cout(line);
    delay(65535);
  }
}
