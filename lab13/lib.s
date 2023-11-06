.bss

.text
.globl _start

.set NULL, 0
# 0xFFFF0100 - 0xFFFF0300 - general_purpose_timer.js
.set GPT_READ, 0xFFFF0100  # byte  - Storing “1” triggers the GPT device to start reading the current system time. The register is set to 0 when the reading is completed
.set GPT_TIME, 0xFFFF0100  # word  - Stores the time (in milliseconds) at the moment of the last reading by the GPT
.set GPT_INT, 0xFFFF0100   # word  - Storing v > 0 programs the GPT to generate an external interruption after v milliseconds. It also sets this register to 0 after v milliseconds (immediately before generating the interruption)
# 0xFFFF0300 - 0xFFFF0500 - midi_synthesizer.js
.set MIDI_CH, 0xFFFF0300   # byte  - Storing ch ≥ 0 triggers the synthesizer to start playing a MIDI note in the channel ch
.set MIDI_INST, 0xFFFF0302 # short - Instrument ID
.set MIDI_NOTE, 0xFFFF0304 # byte  - Note
.set MIDI_VEL, 0xFFFF0305  # byte  - Note velocity
.set MIDI_DUR, 0xFFFF0306  # short - Note duration

