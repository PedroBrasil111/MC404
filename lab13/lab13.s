.bss
.align 4
isr_stack:             # ISR stack's top address (1024 bytes)
.skip 1024
isr_stack_end:         # ISR stack's base address
_system_time: .skip 4  # unsigned word - stores current system time

.text
.globl _system_time

# General Purpose Timer (GPT) - 0xFFFF0100 - 0xFFFF0300
.set GPT_CONTROL_REG_PORT, 0xFFFF0100      # unsigned byte
.set SYSTIME_DATA_REG_PORT, 0xFFFF0104     # unsigned word 
.set GPT_INTERRUPT_DATA_PORT, 0xFFFF0108   # unsigned word

# C signature: play_note(int ch, int inst, int note, int vel, int dur)
.globl play_note
play_note:
    li t0, MIDI_INST
    sh a1, (t0)       # Stores instrument
    li t0, MIDI_NOTE
    sb a2, (t0)       # Stores note
    li t0, MIDI_VEL
    sb a3, (t0)       # Stores velocity
    li t0, MIDI_DUR
    sh a4, (t0)       # Stores duration
    li t0, MIDI_CH
    sb a0, (t0)       # Starts playing note on ch
    ret

.globl _start
_start:
    # Registering the ISR
    la t0, isr
    csrw mtvec, t0        # Loads the ISR's address into mtvec
    # Initializing mscratch with the ISR's stack
    la t0, isr_stack_end  # t0 <= stack's base
    csrw mscratch, t0     # mscratch <= t0
    # Initializing _system_time
    la t0, _system_time
    li t1, 0
    sw t1, (t0)           # Initializes as 0
    # Enabling external interrupts
    li t0, 0x800
    csrs mie, t0          # Sets mie.MEIE (bit 11) as 1
    # Enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0      # Sets mstatus.MIE (bit 3) as 1
    # Initalizing the GPT
    li t0, 100
    li t1, GPT_INTERRUPT_DATA_PORT
    sw t0, (t1)           # Sets next interrupt to happen in 100 ms
    # Playing song
    jal main

isr:
    # Storing registers
    csrrw sp, mscratch, sp  # Switches sp and mscratch
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    # Adding 100 ms to system time
    la t1, _system_time
    lw t0, (t1)
    addi t0, t0, 100
    sw t0, (t1)
    # Setting next interrupt
    li t0, 100
    li t1, GPT_INTERRUPT_DATA_PORT
    sw t0, (t1)             # Sets next interrupt to happen in 100 ms
    # Loading registers
    lw t0, 0(sp)
    lw t1, 4(sp)
    addi sp, sp, 16
    csrrw sp, mscratch, sp  # Switches sp and mscratch again
    mret                    # Returns from interrupt