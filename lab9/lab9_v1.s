.globl _start

.bss
buffer: .skip 7    # input: number between -10000 and 10000 in ascii (unsigned bytes)
sum: .skip 4       # input converted to integer (signed word)

.text
# parameters: a0 - read size, a1 - buffer where string will be stored
read:
    mv a2, a0        # size
    li a0, 0         # file descriptor = 0 (stdin)
    li a7, 63        # syscall read (63)
    ecall
    ret

# parameters: a0 - string size, a1 - buffer where string is stored
write:
    mv a2, a0        # size
    li a0, 1         # file descriptor = 1 (stdout)
    li a7, 64        # syscall write (64)
    ecall
    ret

exit:
    li a0, 0
    li a7, 93
    ecall

# paramaters: a0 - ascii number's address,
#             a1 - address where the number will be stored
# returns address where the conversion stopped
signed_atoi:
    li t1, 10          # base 10
    li a2, 0           # holds number being computed
    li a3, 0           # a3 indicates whether number is negative (1) or positive (0)
    lbu t2, (a0)       # 1st digit
    li t0, '-'
    bne t2, t0, pos    # if 1st digit isn't '-' the number is positive
    li a3, 1           # negative
    addi a0, a0, 1     # skip the minus sign
    pos:
    li t3, '9'         # 1st stop condition
    li t0, '0'         # 2nd stop condition
    1:
        lbu t2, (a0)         # get current digit
        bgt t2, t3, 1f       # if digit > '9' then end loop
        blt t2, t0, 1f       # if digit < '0' then end loop
        addi t2, t2, -'0'    # convert digit
        mul a2, a2, t1       # multiply number by 10
        add a2, a2, t2       # add digit
        addi a0, a0, 1
        j 1b
    1:
    li t0, 1
    bne a3, t0, store_num    # if a3 != 1, number is positive (just store)
    sub a2, x0, a2           # invert the number (negative)
    store_num:
    sw a2, (a1)              # store the number
    ret

# parameters: a0 - number that'll be converted,
#             a1 - store address
# returns the number length
itoa:
    addi sp, sp, -1
    li t0, '\n'       # stack line break (last byte)
    sb t0, (sp)
    li t2, 0          # indicates whether number is negative (1) or positive (0)
    bgez a0, not_negative
    li t2, 1
    sub a0, x0, a0    # a0 is the absolute value of the number
    not_negative:
    li t1, 10         # base 10
    1:
        rem t0, a0, t1      # t0 is the last digit of a0
        addi t0, t0, '0'    # turn into ascii character
        addi sp, sp, -1     # update sp
        sb t0, (sp)         # stack digit
        divu a0, a0, t1     # divide number by 10 (remove last digit)
        beqz a0, 1f         # if a0 == 0, there's no more digits to stack
        j 1b
    1:
    # treating negative case
    beqz t2, pop    # if not negative, jump to pop case
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp)     # stack minus sign if number is negative
    # popping the digits from the stack and storing in the buffer
    pop:
    li t0, '\n'     # stop condition
    li a0, 1        # string size
    1:
        lbu t1, (sp)      # pop digit
        addi sp, sp, 1    # update sp
        sb t1, (a1)       # store
        addi a1, a1, 1    # update address
        addi a0, a0, 1    # update size
        beq t1, t0, 1f    # if digit == '\n' then end
        j 1b
    1:
    ret

# parameters: a0 - sum that is being searched
find_node:
    la a1, head_node
    li a2, 0    # node index
    1:
        beqz a1, 1f          # stop if a1 == NULL
        lw t0, (a1)          # t0 <= VAL1
        lw t1, 4(a1)         # t1 <= VAL2
        add t0, t0, t1       # t0 <= VAL1 + VAL2
        beq t0, a0, found    # if t0 == sum then done
        addi a2, a2, 1       # update index
        lw a1, 8(a1)         # next node's address
        j 1b
    1:
    li a0, -1    # index -1 if the sum wasn't found
    ret
    found:
    mv a0, a2
    ret

_start:
    # reading and converting input to integer
    li a0, 7         # read size
    la a1, buffer
    jal read
    la a0, buffer
    la a1, sum
    jal signed_atoi
    # searching for node and writing
    lw a0, sum
    jal find_node    # a0 is now the node's index
    la a1, buffer
    jal itoa         # convert index to ascii, a0 is the size of the string
    la a1, buffer
    jal write
    jal exit