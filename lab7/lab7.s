.bss
input: .skip 0xd      # input buffer (13 bytes)
output: .skip 0xf     # output buffer (15 bytes)

.text
.globl _start

read:
    li a0, 0      # file descriptor = 0 (stdin)
    la a1, input #  buffer to write the data
    li a2, 13     # size
    li a7, 63     # syscall read (63)
    ecall
    ret

write:
    mv s5, a0
    mv s6, a1
    mv s7, a2
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output       # buffer
    li a2, 15           # size
    li a7, 64           # syscall write (64)
    ecall
    mv a0, s5
    mv a1, s6
    mv a2, s7
    ret

exit:
    li a0, 0
    li a7, 93
    ecall


# a0 -- address to the start of the number being encoded
encode:
    la a1, output
    la t0, input
    lb t1, 0(t0)
    sb t1, 2(a1)
    lb t2, 1(t0)
    sb t2, 4(a1)
    lb t3, 2(t0)
    sb t3, 5(a1)
    lb t4, 3(t0)
    sb t4, 6(a1)

    andi t1, t1, 0x1
    andi t2, t2, 0x1
    andi t3, t3, 0x1
    andi t4, t4, 0x1

    xor t0, t1, t2
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 0(a1)

    xor t0, t1, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 1(a1)

    xor t0, t2, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 3(a1)

    li t0, '\n'
    sb t0, 7(a1)
    ret

decode:
    la a1, output
    addi a1, a1, 8
    la a0, input
    addi a0, a0, 5

    lb t1, 2(a0)
    sb t1, 0(a1)
    lb t2, 4(a0)
    sb t2, 1(a1)
    lb t3, 5(a0)
    sb t3, 2(a1)
    lb t4, 6(a0)
    sb t4, 3(a1)
    li t0, '\n'
    sb t0, 4(a1)

    andi t1, t1, 0x1
    andi t2, t2, 0x1
    andi t3, t3, 0x1
    andi t4, t4, 0x1

    xor t0, t1, t2
    xor t0, t0, t4
    addi t0, t0, '0'
    lb s0, 0(a0)
    bne t0, s0, fail

    xor t0, t1, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    lb s0, 1(a0)
    bne t0, s0, fail

    xor t0, t2, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    lb s0, 3(a0)
    bne t0, s0, fail

    li t1, '0'
    sb t1, 5(a1)
    li t1, '\n'
    sb t1, 6(a1)
    ret

    fail:
    li t1, '1'
    sb t1, 5(a1)
    li t1, '\n'
    sb t1, 6(a1)
    ret

_start:
    jal read
    jal encode
    jal decode
    jal write

