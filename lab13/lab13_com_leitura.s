.section .bss
.align 4
isr_stack: # Final da pilha das ISRs
.skip 1024 # Aloca 1024 bytes para a pilha
isr_stack_end: # Base da pilha das ISRs
_system_time: .skip 4

.section .text
.globl _start
.globl _system_time
.globl play_note

# 0xFFFF0100 - 0xFFFF0300 - general_purpose_timer.js
.set GPT_READ, 0xFFFF0100  # byte  - Storing “1” triggers the GPT device to start reading the current system time. The register is set to 0 when the reading is completed
.set GPT_TIME, 0xFFFF0104  # word  - Stores the time (in milliseconds) at the moment of the last reading by the GPT
.set GPT_INT, 0xFFFF0108   # word  - Storing v > 0 programs the GPT to generate an external interruption after v milliseconds. It also sets this register to 0 after v milliseconds (immediately before generating the interruption)
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
    # Registrar a ISR
    la t0, main_isr # Carrega o endereço da main_isr
    csrw mtvec, t0 # em mtvec
    # Configura mscratch com o topo da pilha das ISRs
    la t0, isr_stack_end # t0 <= base da pilha
    csrw mscratch, t0 # mscratch <= t0
    # Habilita Interrupções Externas
    csrr t1, mie # Seta o bit 11 (MEIE)
    li t2, 0x800 # do registrador mie
    or t1, t1, t2
    csrw mie, t1
    # Habilita Interrupções Global
    csrr t1, mstatus # Seta o bit 3 (MIE)
    ori t1, t1, 0x8 # do registrador mstatus
    csrw mstatus, t1
    # initialize GPT
    li t0, 100
    li t1, GPT_INT
    sw t0, (t1) # sets interruption interval to 100 ms
    #jal main_isr
    jal main # plays music

main_isr:
    # Salvar o contexto
    csrrw sp, mscratch, sp  # Troca sp com mscratch
    addi sp, sp, -16        # Aloca espaço na pilha da ISRs
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    # Trata a interrupção
    li t0, 100
    li t1, GPT_INT
    sw t0, (t1) # set interruption interval as 100 ms
    li t0, GPT_READ
    li t1, 1
    sb t1, (t0)
    1:
        lbu t1, (t0)
        bnez t1, 1b
    li t0, GPT_TIME
    lw t0, (t0)
    sw t0, _system_time, t1
    # Recupera o contexto
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16         # Desaloca espaço da pilha da ISR
    csrrw sp, mscratch, sp  # Troca sp com mscratch novamente
    mret # Retorna da interrupção