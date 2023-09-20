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


# Encodes the inputted sequence of 4 bits using Hamming code.
# We'll name the original bits sequentially: d1, d2, d3 and d4,
# and the parity bits as: p1, p2 and p3.
# Has no return nor paramaters
encode:
    la a1, output
    la t0, input
    # each register ti stores the digit di (starting from 1)
    lbu t1, 0(t0)
    sb t1, 2(a1)    # d1 is the 3rd digit of the encoded string
    lbu t2, 1(t0)
    sb t2, 4(a1)    # d2 is the 5th
    lbu t3, 2(t0)
    sb t3, 5(a1)    # d3 is the 6th
    lbu t4, 3(t0)
    sb t4, 6(a1)    # d4 is the 7th
    # since these are ASCII values, we take only the least significant bit (0 or 1)
    andi t1, t1, 0x1
    andi t2, t2, 0x1
    andi t3, t3, 0x1
    andi t4, t4, 0x1
    # computing p1 (1st verification digit)
    xor t0, t1, t2
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 0(a1)     # p1 is the 1st digit
    # computing p2
    xor t0, t1, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 1(a1)     # p2 is the 2nd digit
    # computing p3
    xor t0, t2, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    sb t0, 3(a1)     # p3 is the 4th digit
    # storing '\n' after the bits for formatting
    li t0, '\n'
    sb t0, 7(a1)
    ret

# Decodes the inputted sequence of 7 bits that has been encoded with Hamming code.
# We'll name the original bits sequentially: d1, d2, d3 and d4,
# and the parity bits as: p1, p2 and p3.
# Has no return nor paramaters
decode:
    la a1, output
    addi a1, a1, 8   # 1st position of the decoded string that will be output
    la a0, input
    addi a0, a0, 5   # 1st position of inputted encoded string
    # each register ti stores the digit di (starting from 1)
    lbu t1, 2(a0)
    sb t1, 0(a1)     # stores t1 as the 1st digit of output
    lbu t2, 4(a0)
    sb t2, 1(a1)     # stores t2 as the 2nd
    lbu t3, 5(a0)
    sb t3, 2(a1)     # stores t3 as the 3rd
    lbu t4, 6(a0)
    sb t4, 3(a1)     # stores t4 as the 4th
    li t0, '\n'      # stores '\n' for formatting
    sb t0, 4(a1)
    # using AND and mask to get the last bit of each digit (0 or 1)
    andi t1, t1, 0x1
    andi t2, t2, 0x1
    andi t3, t3, 0x1
    andi t4, t4, 0x1
    # computing p1
    xor t0, t1, t2
    xor t0, t0, t4
    addi t0, t0, '0'
    lb s0, 0(a0)      # s0 is p1 as given in the encoded input
    bne t0, s0, fail  # if p1 is different from the one from the input, jump to fail
    # computing p2
    xor t0, t1, t3
    xor t0, t0, t4
    addi t0, t0, '0'
    lb s0, 1(a0)      # s0 is p2 as given in the encoded input
    bne t0, s0, fail  # if they're different, jump to fail
    # computing p3
    xor t0, t2, t3
    xor t0, t0, t4
    addi t0, t0, '0' 
    lb s0, 3(a0)      # s0 is p3 as given in the encoded input
    bne t0, s0, fail  # if they're different, jump to fail
    # if all parity bits are correct, store '0' (indicates no error) and '\n' then return
    li t1, '0'
    sb t1, 5(a1)
    li t1, '\n'
    sb t1, 6(a1)
    ret
    # else, store '1' (indicates error) and '\n' then return
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

