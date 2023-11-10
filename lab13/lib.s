.bss
stack: .skip 128
_system_time: .skip 4

.text
.globl _start
.globl _system_time
.globl play_note

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

# void play_note(int ch, int inst, int note, int vel, int dur);
play_note:
    li t0, MIDI_INST
    sh a1, (t0) # instrument
    li t0, MIDI_NOTE
    sb a2, (t0) # note
    li t0, MIDI_VEL
    sb a3, (t0) # velocity
    li t0, MIDI_DUR
    sh a4, (t0) # duration
    li t0, MIDI_CH
    sb a0, (t0) # start playing on ch
    ret

_start:   
    csrr t0, mstatus
    ori t0, t0, 0x8
    csrw mstatus, t0
    # initialize the stack
    la sp, stack
    addi sp, sp, 128
    # Registrar a ISR
    la t0, main_isr # Grava o endereço da ISR principal
    csrw mtvec, t0 # no registrador mtvec
    # initalize _system_time
    la t0, _system_time
    li t1, 0
    sw t1, (t0) # initialize as zero
    # initialize GPT
    li t0, 100
    li t1, GPT_INT
    sw t0, (t1) # set interruption interval as 100 ms
    li t1, GPT_READ
    sw t0, (t1) # triggers the GPT to start
    jal main # plays music
    li a0, 0
    jal exit # exit with code 0

# Terminate calling process
# Parameters: a0 - status code
# No return value
exit:
    li a7, 93    # syscall exit (93)
    ecall

main_isr:
    # Salvar o contexto
    csrrw sp, mscratch, sp  # Troca sp com mscratch
    addi sp, sp, -128        # Aloca espaço na pilha da ISR
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw a2, 8(sp)
    sw a3, 12(sp)
    sw a4, 16(sp)
    sw a5, 20(sp)
    sw a6, 24(sp)
    sw a7, 28(sp)
    sw s0, 32(sp)
    sw s1, 36(sp)
    sw s3, 40(sp)
    sw s4, 44(sp)
    sw s5, 48(sp)
    sw s6, 52(sp)
    sw s7, 56(sp)
    sw s8, 60(sp)
    sw s9, 64(sp)
    sw s10, 68(sp)
    sw s11, 72(sp)
    sw t0, 76(sp)
    sw t1, 80(sp)
    sw t2, 84(sp)
    sw t3, 88(sp)
    sw t4, 92(sp)
    sw t5, 96(sp)
    sw t6, 100(sp)
    sw gp, 104(sp)
    sw tp, 108(sp)
    sw s2, 112(sp)

    # Trata a interrupção
    li t0, GPT_TIME
    lw t0, (t0) # t0 <= time passed since last reading
    la t1, _system_time
    lw t2, (t1) # t2 <= system time up until last reading
    add t2, t2, t0 # t2 <= current system time
    sw t2, (t1) # store t2 into _system_time

    # Recupera o contexto
    lw a0, 0(sp)
    lw a1, 4(sp)
    lw a2, 8(sp)
    lw a3, 12(sp)
    lw a4, 16(sp)
    lw a5, 20(sp)
    lw a6, 24(sp)
    lw a7, 28(sp)
    lw s0, 32(sp)
    lw s1, 36(sp)
    lw s3, 40(sp)
    lw s4, 44(sp)
    lw s5, 48(sp)
    lw s6, 52(sp)
    lw s7, 56(sp)
    lw s8, 60(sp)
    lw s9, 64(sp)
    lw s10, 68(sp)
    lw s11, 72(sp)
    lw t0, 76(sp)
    lw t1, 80(sp)
    lw t2, 84(sp)
    lw t3, 88(sp)
    lw t4, 92(sp)
    lw t5, 96(sp)
    lw t6, 100(sp)
    lw gp, 104(sp)
    lw tp, 108(sp)
    lw s2, 112(sp)
    addi sp, sp, 128         # Desaloca espaço da pilha da ISR
    csrrw sp, mscratch, sp  # Troca sp com mscratch novamente
    mret # Retorna da interrupção