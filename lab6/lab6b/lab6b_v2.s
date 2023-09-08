.bss
buffer: .skip 0x14    # buffer (20 bytes)
coordinates: .skip 0x8 # 2 words for storing the inputted coordinates (8 bytes)
time: .skip 0x10    # 4 words for storing the inputted times (16 bytes)
my_coordinates: .skip 0x8 # output

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
# parameters:
atoi:
    la s0, buffer   # s0 is the address of the buffer
    mv s1, a0       # s1 is the address of the word vector
    li s2, 0        # s2 is the number being calculated
    li t0, 1        # t0 is the sign of the number
    j loop            # jumps to loop
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
        lbu t1, (s0) # t1 is the current digit being analised
        addi s0, s0, 1 # update address
        li t2, '\n' # stop condition
        beq t1, t2, new_number # if t1 == '\n' then done
        li t2, '-'
        beq t1, t2, negative
        li t2, '+'
        beq t1, t2, loop
        li t2, ' '
        beq t1, t2, new_number
        addi t1, t1, -48 # t1 = t1 - '0' is now the integer value of the digit
        li t2, 10
        mul s2, s2, t2 # s2 *= 10
        add s2, s2, t1 # add digit to s2
        j loop
    end:
        ret

# converts integer to string, and stores it in the buffer
# parameters:
itoa:
    la s0, buffer # s0 is the address of the buffer
    mv s1, a0 # s1 is the address of the word vector
    li t1, 2 # counter for loop 1
    # loops for each number in the word vector
    1:
        beqz t1, 1f             # if counter == 0 then end loop
        lw s2, (s1)             # s2 is the number being converted
        # addi s2, s2, 10         # debug
        li t2, 4                # counter for loop 2
        bgez s2, positive
        # number is negative:
        li t0, -1
        mul s2, s2, t0          # inverts the number
        li t0, '-'
        sb t0, (s0)
        j 2f
        positive:
        li t0, '+'
        sb t0, (s0)
        # loops to convert number
        2:
            beqz t2, 2f         # if counter == 0 then end loop
            li t3, 10
            rem s3, s2, t3      # s3 = s2 % 10 (ast digit)
            addi s3, s3, '0'    # conversion to ASCII digit
            add t4, s0, t2      # t4 is the address in which the digit should be stored
            sb s3, (t4)         # stores the digit
            divu s2, s2, t3     # removes the last digit of the number
            addi t2, t2, -1     # update counter
            j 2b                # loop
        2:
        li t0, ' '
        addi s0, s0, 5
        sb t0, (s0)
        addi s0, s0, 1
        addi s1, s1, 4
        addi t1, t1, -1 # update counter
        j 1b
    1:
    li t0, '\n'
    addi s0, s0, 1
    sb t0, (s0)
    ret

# estimates the square root using the babylonian method and stores it in sqrts
# parameters: a0 - index of the number whose square root is being estimated (starting from 0)
# returns: a1 - the sqrt approximation
babylonian_sqrt:
    # k = y/2, k' = (k + y/k)/2
    mv t0, a0             # t0 stores the number (y)
    srli t1, t0, 1        # t1 is the initial guess k = y/2
    li t2, 21             # counter
    # loops t2 times
    1:
        beqz t2, 1f # if counter == 0 then end loop
        addi t2, t2, -1 # update counter
        div t3, t0, t1 # t3 = y/k
        add t3, t3, t1 # t3 = y/k + k
        srli t3, t3, 1 # t3 = (y/k + k)/2
        mv t1, t3 # t1 = t3 is the new approximation k'
        j 1b
    1:
    mv a1, t1
    ret

compute_distances:



compute_coordinates:
    la s0, my_coordinates
    la s1, coordinates   
    la s2, time          
    lw t0, (s2)           # t0 is T_A
    li t3, 0              # t3 is y (starts at 0)
    addi s2, s2, 12       # s2 --> 4th word in time
    lw t1, (s2)           # t1 is T_R
    # computing dA
    addi s2, s2, -12      # s2 --> 1st word in time
    sub t0, t0, t1        # t0 = T_A - T_R (delta time)
    li t2, 3
    mul t0, t0, t2        # multiply by 3 meters
    li t2, 10
    sub t0, t0, t2        # divide by 10 nanoseconds, now t0 = dA
    mul t0, t0, t0        # t0 = dA^2
    sw t0, (s2)           # now time[0] is d_A^2
    add t3, t3, t0        # y = dA^2
    # computing dB
    addi s2, s2, 4        # s2 --> 2nd word in time
    lw t0, (s2)           # t0 is T_B
    sub t0, t0, t1        # t0 = T_B - T_R (delta time)
    li t2, 3            
    mul t0, t0, t2        # multiply by 3 meters
    li t2, 10
    sub t0, t0, t2        # divide by 10 nanoseconds, now t0 = dB
    mul t0, t0, t0        # t0 = dB^2
    sw t0, (s2)           # now time[1] is d_B^2
    # computing dC
    addi s2, s2, 4        # s2 --> 3rd word in time
    lw t0, (s2)           # t0 is T_C
    sub t0, t0, t1        # t0 = T_C - T_R (delta time)
    li t2, 3
    mul t0, t0, t2        # multiply by 3 meters
    li t2, 10
    sub t0, t0, t2        # divide by 10 nanoseconds, now t0 = dC
    mul t0, t0, t0        # t0 = dC^2
    sw t0, (s2)           # now time[2] is d_C^2
    # computing y
    sub t3, t3, t0        # y = dA^2 - dB^2
    addi s1, s1, 4        # s1 --> 2nd word in coordinates (Y_B)
    lw t0, (s1)           # t0 is Y_B
    mul t0, t0, t0        # t0 is Y_B^2
    add t3, t3, t0        # y = dA^2 - dB^2 + Y_B^2
    div t3, t3, t0        # y = (dA^2 - dB^2 + Y_B^2)/Y_B
    srli t3, t3, 1        # y = (dA^2 - dB^2 + Y_B^2)/(2*Y_B)
    addi s0, s0, 4        # s0 --> 2nd word in my_coordinates
    sw t3, (s0)
    # computing x
    la s2, time
    lw t1, (s2)           # t1 = dA^2
    li t2, 0              # t2 is x^2 (starts at 0)
    add t2, t2, t1        # t2 = dA^2
    sub t2, t2, t3        # t2 = dA^2 - y^2
    mv a0, t2
    mv t6, ra
    jal babylonian_sqrt
    mv ra, t6
    mv t0, a1             # t0 is x
    # testing if x is positive or negative
    addi s0, s0, -4       # s0 --> 1st word in my_coordinates
    addi s1, s1, -4       # s1 --> 1st word in coordinates
    lw t1, (s1)           # t1 = X_C
    mul t3, t3, t3        # t3 = y^2
    addi s2, s2, 8        # s2 --> 3rd word in time
    lw t2, (s2)           # t2 = d_C^2
    # t0 = x, t1 = X_C, t2 = d_C^2, t3 = y^2
    sub t4, t0, t1 # t4 = x - X_C
    mul t4, t4, t4 # t4 = (x - X_C)^2
    add t4, t4, t3 # t4 = (x - X_C)^2 + y^2
    sub t4, t2, t4 # t4 = d_C^2 -((x - X_C)^2 + y^2)
    li t5, -1
    mul t6, t6, t5 # t6 = -x
    sub t1, t6, t1 # t1 = x - X_C
    mul t1, t1, t1 # t1 = (x - X_C)^2
    add t1, t1, t3 # t1 = (x - X_C)^2 + y^2
    sub t1, t2, t1 # t1 = d_C^2 -((x - X_C)^2 + y^2)
    
    bgtz t1, dont_invert_t1
    mul t1, t1, t5
    dont_invert_t1:
    bgtz t1, dont_invert_t4
    mul t4, t4, t5
    dont_invert_t4:
    blt t1, t4, negative_x
    # positive_x:
    sw t0, (s0)
    ret
    negative_x:
    sw t6, (s0)
    ret

_start:
    jal read

    la a0, coordinates
    jal atoi

    jal read
    la a0, time
    jal atoi

    jal compute_coordinates

    la a0, my_coordinates
    jal itoa
    jal write

    jal exit
