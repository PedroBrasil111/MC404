.bss
str_address: .skip 0x14  # buffer (20 bytes)
sqrts: .skip 0x10        # 4 words for storing the inputted numbers (16 bytes)

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

# converts from string to integer, and stores it in sqrts
# parameters: a0 - index of the number that is being converted (starting from 0)
atoi:
    mv s0, a0
    li s1, 0              # initalize result as 0
    li t1, 10             # base 10
    li t3, 4              # counter to break loop when it reaches 0
    la t5, str_address    # t5 stores the address of the 1st digit of the number
    li t0, 5
    mul t0, s0, t0        # t0 = s0 * 5
    add t5, t5, t0        # shifts t5 to the start of the number
    1:
        lb t2, (t5)       # t2 stores the digit
        beqz t3, 1f       # if counter == 0 then end loop
        addi t2, t2, -48  # t2 = t2 - '0'
        mul s1, s1, t1    # multiply result by 10
        add s1, s1, t2    # add digit
        addi t5, t5, 1    # next digit
        addi t3, t3, -1   # update counter
        j 1b
    1:
        la t2, sqrts      # t2 stores the memory word in which the number will be stored
        slli t1, s0, 2    # t1 = s0 * 4
        add t2, t2, t1    # t2 = t2 + t1
        sw s1, (t2)       # stores the number in t2
        mv a0, s0
        ret

# converts integer to string, and stores it in the buffer
# parameters: a0 - index of the number that is being converted (starting from 0)
itoa:
    mv s0, a0
    la t0, sqrts          # t0 stores the first number's address
    la t1, str_address    # t1 stores the string's address
    slli t2, s0, 2
    add t0, t0, t2        # t0 is now the address of the desired number
    li t2, 5
    mul t2, s0, t2        # t2 = s0 * 5
    add t1, t1, t2        # t1 is now the address to the start of the number in the string
    lw s1, (t0)           # s1 stores the number
    li t2, 4              # counter
    li t3, 10             # base 10
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

# estimates the square root using the babylonian method and stores it in sqrts
# parameters: a0 - index of the number whose square root is being estimated (starting from 0)
babylonian_sqrt:
    # k = y/2, k' = (k + y/k)/2
    mv s0, a0
    la t0, sqrts          # t0 stores the first number's address
    slli t1, s0, 2        # t1 = s0 * 4
    add t0, t0, t1        # t0 is now the address of the desired number
    lw t5, (t0)           # t5 stores the number (y)
    li t1, 10             # counter
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
        sw t4, (t0)       # stores the sqrt
        mv a0, s0
        ret

_start:
    jal read
    li a0, 0              # counter
    li a1, 4              # loop end condition
    1:
        beq a0, a1, 1f    # if a0 == a1 then end loop
        jal atoi
        jal babylonian_sqrt
        jal ibtoa
        addi a0, a0, 1
        j 1b
    1:
    jal write
    jal exit
