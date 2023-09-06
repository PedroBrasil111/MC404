.bss
str_address: .skip 0x14  # buffer (20 bytes)
sqrts: .skip 0x10 # 4 words (16 bytes)

.text
.globl _start
.set str_len, 20

read:
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, str_address #  buffer to write the data
    li a2, str_len # size
    li a7, 63 # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, str_address       # buffer
    li a2, str_len           # size
    li a7, 64           # syscall write (64)
    ecall
    ret

exit:
    li a0, 0
    li a7, 93
    ecall

# parameters: a0 - index of the number that is being converted (starting from 0)
atoi:
    li a1, 0 # initalize result as 0
    li t1, 10 # t1 = 10
    li t3, 4 # counter to break loop when it reaches 0
    la t5, str_address # t5 stores the address of the 1st digit of the number
    add t5, t5, a0 # t5 = t5 + a0
    1:
        lbu t2, (t5) # t2 stores the digit
        beqz t3, 1f # if t2 == ' ' then done
        addi t2, t2, -48 # t2 = t2 - '0'
        mul a1, a1, t1 # multiply result by 10
        add a1, a1, t2 # add digit
        addi t5, t5, 1 # next digit
        addi t3, t3, -1 # subtracts 1 from counter
        j 1b
    1:
        la t2, sqrts # t2 stores the memory word in which the number will be stored
        slli a0, a0, 2 # a0 = a0 * 4
        add t2, t2, a0 # t2 = t2 + a0
        sw a1, (t2) # stores the number in t2
        ret

itoa:
    la t0, sqrts # t0 stores the first number's address
    la t1, str_address # t1 stores the string address
    slli a0, a0, 2 # a0 = a0 * 4
    add t0, t0, a0 # t0 is now the address of the desired number
    lw a1, (t0) # a1 stores the number
    li t2, 4 # counter
    li t3, 10 # base 10
    1:
        beqz t2, 1f # if t2 == 0 then done
        addi t2, t2, -1 # subtracts 1 from counter
        rem a2, a1, t3 # a2 stores the remnant of the division
        addi a2, a2, '0' # conversion to ASCII digit
        add t4, t1, t2 # t4 is the address in which the digit should be stored
        sb a2, (t4) # stores the digit
        divu a1, a1, t3 # divides a1 by 10 (removes last digit)
        j 1b
    1:
        ret

babylonian_sqrt:
    la t0, sqrts # t0 stores the first number's address
    slli a0, a0, 2 # a0 = a0 * 4
    add t0, t0, a0 # t0 is now the address of the desired number
    lw a1, (t0) # a1 stores the number
    li t1, 10 # counter
    1:
        beqz t1, 1f # if t1 == 0 then done
        srli a1, a1, 2
        addi a1, a1, 1
        j 1b
    1:
        sw a1, (t0)
        ret

_start:
    jal read
    li a0, 0
    jal atoi
    li a0, 0
    jal babylonian_sqrt
    li a0, 0
    jal itoa
    jal write
    jal exit
