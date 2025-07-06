#ifndef MIDI_H
#define MIDI_H

#include <stdint.h>

enum {
  MIDI_NOTE_OFF = 0x80,
  MIDI_NOTE_ON = 0x90,
  MIDI_AFTERTOUCH = 0XA0,
  MIDI_CONTROL_CHANGE = 0XB0,
  MIDI_PROGRAM_CHANGE = 0XC0,
  MIDI_CHANNEL_PRESSURE = 0XD0,
  MIDI_PITCH_BEND = 0XE0,
  MIDI_SYSEX = 0XF0,
  MIDI_SYSEX_END = 0XF7
};

typedef struct {
  uint8_t status;
  uint8_t data[2];
} midi_message;

typedef struct {
  uint8_t status;
  uint8_t previous;
} midi_parser;

/**
 * Incrementally parses the bytes of a MIDI message.
 */
midi_message midi_parse(midi_parser *parser, uint8_t b);

#endif
