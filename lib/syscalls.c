#include <errno.h>
#include <stddef.h>
#include <sys/stat.h>
#include <unistd.h>

#include "hal.h"

extern char _end;
extern char _stack_start;

void *_sbrk(ptrdiff_t incr) {
  static char *heap_end = &_end;
  char *prev_heap_end = heap_end;

  // Check if heap would collide with stack
  if (heap_end + incr > &_stack_start) {
    errno = ENOMEM;
    return (void *)-1;
  }

  heap_end += incr;
  return prev_heap_end;
}

int _close(int file) { return -1; }

int _fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

int _isatty(int file) { return 1; }

int _lseek(int file, int ptr, int dir) { return 0; }

void _exit(int code) {
  while (1) {
    // NOP
  }
}

int _kill(int pid, int sig) { return -1; }

int _getpid(void) { return 1; }

int _write(int file, char *ptr, int len) {
  if (file != STDOUT_FILENO && file != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }

  for (int i = 0; i < len; i++) {
    *UART0 = ptr[i];
  }

  return len;
}

int _read(int file, char *ptr, int len) {
  if (file != STDIN_FILENO) {
    errno = EBADF;
    return -1;
  }

  int i;
  for (i = 0; i < len; i++) {
    ptr[i] = *UART0;
    if (ptr[i] == '\r' || ptr[i] == '\n') {
      i++;
      break;
    }
  }
  return i;
}
