.bss
buffer: .skip 0x14  # buffer (20 bytes)
coordinates: .skip 0x8 # 2 words for storing the inputted coordinates (8 bytes)
time: .skip 0x10    # 4 words for storing the inputted times (16 bytes)

.text
.globl _start
.set str_len, 20

read:
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, buffer #  buffer to write the data
    li a2, str_len # size
    li a7, 63 # syscall read (63)
    ecall
    ret

write:
    mv s5, a0
    mv s6, a1
    mv s7, a2
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, buffer       # buffer
    li a2, str_len           # size
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

# converts from string to integer, and stores it in sqrts
# parameters: a0 - index of the number that is being converted (starting from 0)
atoi:
    mv s0, a0
    li s1, 0              # initalize result as 0
    li t1, 10             # base 10
    li t3, 4              # counter to break loop when it reaches 0
    la t5, buffer    # t5 stores the address of the 1st digit of the number
    li t0, 5
    mul t0, s0, t0        # t0 = s0 * 5
    add t5, t5, t0        # shifts t5 to the start of the number
    1:
        lbu t2, (t5)      # t2 stores the digit
        beqz t3, 1f       # if counter == 0 then end loop
        addi t2, t2, -48  # t2 = t2 - '0'
        mul s1, s1, t1    # multiply result by 10
        add s1, s1, t2    # add digit
        addi t5, t5, 1    # next digit
        addi t3, t3, -1   # update counter
        j 1b
    1:
        la t2, time      # t2 stores the memory word in which the number will be stored
        slli t1, s0, 2    # t1 = s0 * 4
        add t2, t2, t1    # t2 = t2 + t1
        sw s1, (t2)       # stores the number in t2
        mv a0, s0
        ret

signed_atoi:
    mv s0, a0
    li s1, 0    # initalize result as 0
    li t1, 10   # base 10
    li t3, 4    # counter to break loop when it reaches 0
    la t5, buffer   # t5 stores the address of the 1st digit of the number
    li t0, 5
    mul t0, s0, t0  # t0 = s0 * 5
    add t5, t5, t0  # shifts t5 to the start of the number
    li t2, '-'
    lb t4, (t5)
    li t0, 1    # sign = 1
    bne t4, t2, positive    # jump to positive if number is positive
    li t0, -1   # sign = -1
    positive:
    addi t5, t5, 1  # shifts 1 byte
    1:
        lbu t2, (t5)      # t2 stores the digit
        beqz t3, 1f       # if counter == 0 then end loop
        addi t2, t2, -48  # t2 = t2 - '0'
        mul s1, s1, t1    # multiply result by 10
        add s1, s1, t2    # add digit
        addi t5, t5, 1    # next digit
        addi t3, t3, -1   # update counter
        j 1b
    1:
        la t2, coordinates  # t2 stores the memory word in which the number will be stored
        slli t1, s0, 2      # t1 = s0 * 4
        add t2, t2, t1      # t2 = t2 + t1
        mul s1, s1, t0      # multiply by the sign
        sw s1, (t2)         # stores the number in t2
        mv a0, s0
        ret

# estimates the square root using the babylonian method and stores it in sqrts
# parameters: a0 - index of the number whose square root is being estimated (starting from 0)
babylonian_sqrt:
    # k = y/2, k' = (k + y/k)/2
    mv s0, a0
    la t0, time           # t0 stores the first number's address
    slli t1, s0, 2        # t1 = s0 * 4
    add t0, t0, t1        # t0 is now the address of the desired number
    lw t5, (t0)           # t5 stores the number (y)
    li t1, 21             # counter
    srli t4, t5, 1        # t4 is the initial guess k = y/2
    1:
        beqz t1, 1f       # if counter == 0 then end loop
        addi t1, t1, -1   # update counter
        div t3, t5, t4    # t3 = y/k
        add t3, t3, t4    # t3 += k
        srli t3, t3, 1    # t3 /= 2
        mv t4, t3         # t4 = t3 is the new approximation k'
        j 1b
    1:
        la t0, coordinates
        addi t0, t0, 4
        sw t4, (t0)       # stores the sqrt in coordinates[1]
        mv a0, s0
        jal write
        ret

# converts integer to string, and stores it in the buffer
# parameters: a0 - index of the number that is being converted (starting from 0)
itoa:
    mv s0, a0
    la t0, coordinates    # t0 stores the first number's address
    la t1, buffer         # t1 stores the string's address
    slli t2, s0, 2
    add t0, t0, t2        # t0 is now the address of the desired number
    li t2, 6
    mul t2, s0, t2        # t2 = s0 * 6
    add t1, t1, t2        # t1 is now the address to the start of the number in the string
    lw s1, (t0)           # s1 stores the number
    li t2, 4              # counter
    li t3, 10             # base 10
    bgez s1, positive2     # if number >= 0, jumps to positive
    not s1, s1            # invert bits
    addi s1, s1, 1        # add 1 (2's complement)
    li t4, '-'
    sb t4, (t1)
    addi t1, t1, 1
    j 1f
    positive2:
    li t4, '+'
    sb t4, (t1)
    addi t1, t1, 1
    1:
        beqz t2, 1f       # if counter == 0 then end loop
        addi t2, t2, -1   # update counter
        rem a2, s1, t3    # a2 stores the remnant of the division
        addi a2, a2, '0'  # conversion to ASCII digit
        add t4, t1, t2    # t4 is the address in which the digit should be stored
        sb a2, (t4)       # stores the digit
        divu s1, s1, t3   # removes the last digit of the number
        j 1b              # loop
    1:
        mv a0, s0
        ret

_start:
    # processing input's 1st line
    jal read
    li a0, 0
    jal signed_atoi
    li a0, 1
    jal signed_atoi

    # processing input's 2nd line
    jal read
    li a0, 0    # counter
    li a1, 4    # loop end condition
    1:
        beq a0, a1, 1f    # if a0 == 4 then end loop
        jal atoi
        addi a0, a0, 1
        j 1b
    1:
    
    # computing distance from each satellite
    li a0, 0
    li a1, 3
    la t0, time         # time address
    addi t1, t0, 12     # t1 is Tr (time of intersection of the waves)
    1:
        beq a0, a1, 1f  # if a0 == 3 then end loop
        lw t2, (t0)     # t2 is the current number (Tx - timestamp from satellite x)
        sub t2, t1, t2  # subtract Tr to get time traveled by wave
        li t3, 3
        mul t2, t2, t3  # multiply by 3 meters
        li t3, 10
        sub t2, t2, t3  # multiply by 0.1 nanosseconds^(-1)
        sw t2, (t0)     # here, t2 holds dx (distance from sattelite x)
        addi t0, t0, 4  # t0 points to next number
        addi a0, a0, 1
        j 1b
    1:

    # computing y
    la t0, time
    li t1, 0 # holds the value of y
    lw t2, (t0) # t2 is dA
    mul t2, t2, t2 # dA squared
    add t1, t1, t2 # y = dA^2
    addi t0, t0, 4
    lw t2, (t0) # t2 is now dB
    mul t2, t2, t2 # dB squared
    sub t1, t1, t2 # y = dA^2 - dB^2
    la t0, coordinates
    lw t2, (t0) # t2 is YB - vertical position of satellite B
    mul t3, t2, t2 # t3 = YB^2
    add t1, t1, t3 # y = dA^2 + YB^2 - dB^2
    sub t1, t1, t2 # y = (dA^2 + YB^2 - dB^2) / YB
    srai t1, t1, 1 # y = (dA^2 + YB^2 - dB^2) / 2YB
    addi t0, t0, 4
    sw t1, (t0)    # stores y in coordinates[1]

    # computing x
    la t0, time
    li t3, 0 # holds what's inside the sqrt
    lw t2, (t0)
    mul t2, t2, t2 # t2 = dA^2
    add t3, t3, t2
    mul t2, t1, t1 # t2 = y^2
    sub t3, t3, t2
    sw t3, (t0)
    li a0, 0
    jal babylonian_sqrt

    li a1, 2
    1:
        beq a0, a1, 1f
        jal itoa
        addi a0, a0, 1
        j 1b
    1:
    jal write
    jal exit
    