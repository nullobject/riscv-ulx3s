#include <string.h>

#include "fifo.h"

void fifo_init(fifo *q, size_t count, size_t size) {
  q->head = 0;
  q->tail = 0;
  q->count = count;
  q->size = size;
  q->data = malloc(count * size);
}

void *fifo_read(fifo *q) {
  if (q->tail == q->head) {
    return NULL;
  }
  void *p = q->data + (q->tail * q->size);
  q->tail = (q->tail + 1) % q->count;
  return p;
}

int fifo_write(fifo *q, const void *value) {
  if (((q->head + 1) % q->count) == q->tail) {
    return -1;
  }
  void *p = q->data + (q->head * q->size);
  q->head = (q->head + 1) % q->count;
  memcpy(p, value, q->size);
  return 0;
}
