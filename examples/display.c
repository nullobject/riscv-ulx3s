#include <stdint.h>

#include "../lib/fifo.h"
#include "../lib/hal.h"
#include "../lib/midi.h"

const char TOP_BAR[] = {196, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 197, 197,
                        197, 197, 197, 197, 197, 197, 197, 197, 197, 212, 0};

const char BOT_BAR[] = {204, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 205, 205,
                        205, 205, 205, 205, 205, 205, 205, 205, 205, 220, 0};

midi_parser p = {0};
fifo q;

// TODO: Check which UART1 caused the interrupt
void irq() {
  midi_message msg = midi_parse(&p, *UART1);
  if (msg.status) {
    fifo_write(&q, &msg);
  }
}

int __attribute__((noreturn)) main() {
  fifo_init(&q, 8, sizeof(midi_message));
  clear_text();

  write_text(TOP_BAR, TEXT_NORMAL, 0, 0);
  write_text(BOT_BAR, TEXT_NORMAL, 0, 7);

  write_text("        VALUE1  VALUE2          ", TEXT_NORMAL, 0, 2);

  ENCODERS[0] = *PRNG;
  ENCODERS[1] = *PRNG;
  ENCODERS[2] = *PRNG;
  ENCODERS[3] = *PRNG;
  ENCODERS[4] = *PRNG;
  ENCODERS[5] = *PRNG;
  ENCODERS[6] = *PRNG;
  ENCODERS[7] = *PRNG;

  while (1) {
    midi_message *c = fifo_read(&q);
    if (c) {
      if (c->status == MIDI_NOTE_OFF) {
        write_text("NOTEOFF ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
        write_uint16(c->data[1], TEXT_NORMAL, 16, 3);
      } else if (c->status == MIDI_NOTE_ON) {
        write_text("NOTEON  ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
        write_uint16(c->data[1], TEXT_NORMAL, 16, 3);
      } else if (c->status == MIDI_AFTERTOUCH) {
        write_text("AFTER   ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
        write_uint16(c->data[1], TEXT_NORMAL, 16, 3);
      } else if (c->status == MIDI_CONTROL_CHANGE) {
        write_text("CTRL    ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
        write_uint16(c->data[1], TEXT_NORMAL, 16, 3);
      } else if (c->status == MIDI_PROGRAM_CHANGE) {
        write_text("PROG    ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
      } else if (c->status == MIDI_CHANNEL_PRESSURE) {
        write_text("PRESS   ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
      } else if (c->status == MIDI_PITCH_BEND) {
        write_text("BEND    ", TEXT_NORMAL, 0, 2);
        write_uint16(c->data[0], TEXT_NORMAL, 8, 3);
        write_uint16(c->data[1], TEXT_NORMAL, 16, 3);
      } else {
        write_text("ERROR", TEXT_NORMAL, 0, 2);
      }
    }
  }
}
