.bss
buffer: .skip 0x14    # buffer (20 bytes)
coordinates: .skip 0x8 # 2 words for storing the inputted coordinates (8 bytes)
time: .skip 0x10    # 4 words for storing the inputted times (16 bytes)
my_coordinates: .skip 0x8 # output

.text
.globl _start

read:
    li a0, 0      # file descriptor = 0 (stdin)
    la a1, buffer #  buffer to write the data
    li a2, 20     # size
    li a7, 63     # syscall read (63)
    ecall
    ret

write:
    mv s5, a0
    mv s6, a1
    mv s7, a2
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, buffer       # buffer
    li a2, 12           # size
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
# parameters:
atoi:
    la s0, buffer   # s0 is the address of the buffer
    mv s1, a0       # s1 is the address of the word vector
    li s2, 0        # s2 is the number being calculated
    li t0, 1        # t0 is the sign of the number
    j loop          # jumps to loop
    new_number:
    mul s2, s2, t0  # multiply by sign
    sw s2, (s1)     # store number
    addi s1, s1, 4  # update address
    li s2, 0        # reset number
    li t0, 1        # reset sign
    li t2, '\n'
    beq t1, t2, end
    j loop
    negative:
    li t0, -1
    # loops for each digit in the buffer
    loop:
        lbu t1, (s0)        # t1 is the current digit being analised
        addi s0, s0, 1      # update address
        li t2, '\n'         # stop condition
        beq t1, t2, new_number
        li t2, ' '
        beq t1, t2, new_number
        li t2, '-'
        beq t1, t2, negative
        li t2, '+'
        beq t1, t2, loop
        addi t1, t1, -48    # t1 = t1 - '0' is the integer value of the digit
        li t2, 10
        mul s2, s2, t2      # s2 *= 10
        add s2, s2, t1      # add digit to s2
        j loop
    end:
    ret

# converts integer to string, and stores it in the buffer
# parameters: a0 -- address of the word vector, a1 -- number of words
itoa:
    la s0, buffer  # s0 is the address of the buffer
    mv s1, a0      # s1 is the address of the word vector
    mv t1, a1      # counter for loop 1
    # loops for each number in the word vector
    1:
        beqz t1, 1f  # if counter == 0 then end loop
        lw s2, (s1)  # s2 is the number being converted
        li t2, 4     # counter for loop 2
        bgez s2, positive
        # number is negative:
        li t5, -1
        mul s2, s2, t5
        li t0, '-'
        sb t0, (s0)
        j 2f
        positive:
        li t0, '+'
        sb t0, (s0)
        # loops to convert number
        2:
            beqz t2, 2f       # if counter == 0 then end loop
            li t3, 10
            rem s3, s2, t3    # s3 = s2 % 10 (last digit)
            addi s3, s3, '0'  # conversion to ASCII digit
            add t4, s0, t2    # t4 is the address in which the digit should be stored
            sb s3, (t4)       # stores the digit
            divu s2, s2, t3   # removes the last digit of the number
            addi t2, t2, -1   # update counter
            j 2b              # loop
        2:
        li t0, ' '
        addi s0, s0, 5
        sb t0, (s0)
        addi s0, s0, 1
        addi s1, s1, 4
        addi t1, t1, -1 # update counter
        j 1b
    1:
    addi s0, s0, -1
    li t0, '\n'
    sb t0, (s0)
    ret

# estimates the square root using the babylonian method and stores it in sqrts
# parameters: a0 - index of the number whose square root is being estimated (starting from 0)
# returns: a1 - the sqrt approximation
babylonian_sqrt:
    # k = y/2, k' = (k + y/k)/2
    mv t0, a0       # t0 stores the number (y)
    srli t1, t0, 1  # t1 is the initial guess k = y/2
    li t2, 21       # counter
    # loops 21 times for better approximation
    1:
        beqz t2, 1f     # if counter == 0 then end loop
        addi t2, t2, -1 # update counter
        div t3, t0, t1  # t3 = y/k
        add t3, t3, t1  # t3 = y/k + k
        srli t3, t3, 1  # t3 = (y/k + k)/2
        mv t1, t3       # t1 = t3 is the new approximation k'
        j 1b
    1:
    mv a1, t1
    ret

compute_square_distances:
    la s0, time
    lw t0, 12(s0)   # t0 = T_R
    li t1, 3        # counter
    1:
        beqz t1, 1f     # end loop
        lw t2, (s0)     # t2 = T_i
        sub t2, t0, t2  # t2 = T_R - T_i
        li t3, 3
        mul t2, t2, t3
        li t3, 10
        div t2, t2, t3  # t2 = D_i
        mul t2, t2, t2  # t2 = D_i^2
        sw t2, (s0)
        addi s0, s0, 4
        addi t1, t1, -1 # update counter
        j 1b
    1:
    ret

absolute_value:
    bgtz a0, 1f       # if positive, do nothing
    sub a0, zero, a0  # if negative, multiply by -1
    1:
    mv a1, a0
    ret

compute_coordinates:
    la s0, time
    la s1, coordinates
    la s2, my_coordinates

    # computing y (a2)
    lw t2, (s0)     # t2 = dA^2
    mv a2, t2
    lw t2, 4(s0)    # t2 = dB^2
    sub a2, a2, t2  # a2 = dA^2 - dB^2
    lw t2, (s1)     # t2 = Y_B
    mul t3, t2, t2  # t3 = Y_B^2
    add a2, a2, t3  # a2 = dA^2 - dB^2 + Y_B^2
    div a2, a2, t2  # a2 = (dA^2 - dB^2 + Y_B^2)/Y_B
    srai a2, a2, 1  # divide by 2
    sw a2, 4(s2)

    # computing x (a3)
    mul a2, a2, a2       # a2 = y^2
    lw t2, (s0)          # t2 = dA^2
    sub a0, t2, a2       # a0 = dA^2 - y^2
    mv t6, ra
    jal babylonian_sqrt  # a1 = x = sqrt(a0)
    mv ra, t6
    mv a3, a1            # a3 = x

    # computing if it's x or -x by checking which makes the difference
    # dC^2 - y^2 - (x-X_C)^2 closer to zero in absolute value
    lw t2, 8(s0)      # t2 = dC^2
    sub t2, t2, a2    # t2 -= y^2
    lw t1, 4(s1)      # t1 = X_C
    sub t1, a3, t1    # t1 = x - X_C
    mul t1, t1, t1
    sub t2, t2, t1    # t2 is the difference for positive x
    mv a0, t2
    mv t6, ra
    jal absolute_value
    mv ra, t6
    mv t2, a1         # t2 is now the absolute value
    lw t1, 4(s1)      # t1 = X_C
    sub t1, zero, t1  # t1 = - X_C
    sub t1, t1, a3    # t1 = - x - X_C
    mul t1, t1, t1
    sub t1, t1, t1    # t1 is the difference for negative x
    mv a0, t1
    mv t6, ra
    jal absolute_value
    mv ra, t6
    mv t1, a1         # t1 is now the absolute value
    mv t0, a3         # t0 = x
    bgt t1, t2, 1f    # if positive x, do nothing
    # negative x
    sub t0, zero, t0
    1:
    sw t0, (s2)       # store x
    ret

_start:
    jal read
    la a0, coordinates
    jal atoi

    jal read
    la a0, time
    jal atoi

    jal compute_square_distances
    jal compute_coordinates

    la a0, my_coordinates
    li a1, 2
    jal itoa

    jal write

    jal exit
