#ifndef MIDI_H
#define MIDI_H

#include <stdint.h>

#define MIDI_NOTE_OFF 0x80
#define MIDI_NOTE_ON 0x90
#define MIDI_POLY_PRESSURE 0XA0
#define MIDI_CONTROL_CHANGE 0XB0
#define MIDI_PROGRAM_CHANGE 0XC0
#define MIDI_CHANNEL_PRESSURE 0XD0
#define MIDI_PITCH_WHEEL 0XE0

typedef struct {
  uint8_t status;
  uint8_t data[2];
} midi_message;

typedef struct {
  uint8_t status;
  uint8_t previous;
} midi_parser;

/**
 * Parse a MIDI message.
 */
midi_message midi_parse(midi_parser *parser, uint8_t b);

#endif
