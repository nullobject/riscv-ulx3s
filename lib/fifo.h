#ifndef FIFO_H
#define FIFO_H

#include <stdlib.h>

typedef struct {
  size_t head;
  size_t tail;
  size_t count;
  size_t size;
  void *data;
} fifo;

/**
 * Initializes the given FIFO.
 */
void fifo_init(fifo *q, size_t count, size_t size);

/**
 * Reads an element from the given FIFO.
 */
void *fifo_read(fifo *queue);

/**
 * Writes an element to the given FIFO.
 */
int fifo_write(fifo *queue, const void *value);

#endif
