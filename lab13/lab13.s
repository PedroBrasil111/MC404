.section .bss
.align 4
isr_stack:             # ISR stack's top address (1024 bytes)
.skip 1024
isr_stack_end:         # ISR stack's base address
_system_time: .skip 4  # word - stores current system time

.section .text
.globl _start
.globl _system_time
.globl play_note

# General Purpose Timer (GPT) - 0xFFFF0100 - 0xFFFF0300
.set GPT_READ, 0xFFFF0100  # byte  - storing “1” triggers the GPT device to start reading the
                           # current system time. The register is set to 0 when the reading is completed
.set GPT_TIME, 0xFFFF0104  # word  - stores the time (in milliseconds) at the moment of the
                           # last reading by the GPT
.set GPT_INT, 0xFFFF0108   # word  - storing v > 0 programs the GPT to generate an external interruption
                           # after v milliseconds. It also sets this register to 0 after v milliseconds
                           # (immediately before generating the interruption)
#  MIDI Synthesizer - 0xFFFF0300 - 0xFFFF0500
.set MIDI_CH, 0xFFFF0300   # byte  - storing ch ≥ 0 triggers the synthesizer to start playing a MIDI note
                           # in the channel ch
.set MIDI_INST, 0xFFFF0302 # short - instrument ID
.set MIDI_NOTE, 0xFFFF0304 # byte  - note
.set MIDI_VEL, 0xFFFF0305  # byte  - note velocity
.set MIDI_DUR, 0xFFFF0306  # short - note duration

# C signature: play_note(int ch, int inst, int note, int vel, int dur)
play_note:
    li t0, MIDI_INST
    sh a1, (t0)       # store instrument
    li t0, MIDI_NOTE
    sb a2, (t0)       # store note
    li t0, MIDI_VEL
    sb a3, (t0)       # store velocity
    li t0, MIDI_DUR
    sh a4, (t0)       # store duration
    li t0, MIDI_CH
    sb a0, (t0)       # start playing on ch
    ret

_start:
    # registering the ISR
    la t0, isr
    csrw mtvec, t0        # loads the ISR's address into mtvec
    # initializing mscratch with the ISR's stack
    la t0, isr_stack_end  # t0 <= stack's base
    csrw mscratch, t0     # mscratch <= t0
    # initializing _system_time
    la t0, _system_time
    li t1, 0
    sw t1, (t0)           # initializes as 0
    # initalizing the GPT
    li t0, 100
    li t1, GPT_INT
    sw t0, (t1)           # sets next interrupt to happen in 100 ms
    # enabling external interrupts
    li t0, 0x800
    csrs mie, t0          # sets mie.MEIE (bit 11) as 1
    # enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0      # sets mstatus.MIE (bit 3) as 1
    # playing song
    jal main

isr:
    # storing registers
    csrrw sp, mscratch, sp  # switches sp and mscratch
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    # setting next interrupt
    li t0, 100
    li t1, GPT_INT
    sw t0, (t1)             # sets next interrupt to happen in 100 ms
    # adding 100 ms to system time
    la t1, _system_time
    lw t0, (t1)
    addi t0, t0, 100
    sw t0, (t1)
    # restoring registers
    lw t0, 0(sp)
    lw t1, 4(sp)
    addi sp, sp, 16
    csrrw sp, mscratch, sp  # switches sp and mscratch again
    mret                    # returns from interrupt