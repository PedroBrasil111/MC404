.bss
buffer: .skip 0x14    # buffer (20 bytes)
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
        addi s2, s2, 10
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
babylonian_sqrt:
    # k = y/2, k' = (k + y/k)/2
    mv s0, a0
    la t0, time           # t0 stores the first number's address
    slli t1, s0, 2        # t1 = s0 * 4
    add t0, t0, t1        # t0 is now the address of the desired number
    lw t5, (t0)           # t5 stores the number (y)
    li t1, 10             # counter
    srli t4, t5, 1        # t4 is the initial guess k = y/2
    # loops t1 times
    1:
        beqz t1, 1f       # if counter == 0 then end loop
        addi t1, t1, -1   # update counter
        div t3, t5, t4    # t3 = y/k
        add t3, t3, t4    # t3 += k
        srli t3, t3, 1    # t3 /= 2
        mv t4, t3         # t4 = t3 is the new approximation k'
        j 1b
    1:
        sw t4, (t0)       # stores the sqrt
        mv a0, s0
        ret

_start:
    jal read

    la a0, time
    jal atoi

    la a0, time
    jal itoa

    jal write
    jal exit
