.globl head_node
.globl _start

.bss
buffer: .skip 7    # number between -10000 and 10000 in ascii (unsigned bytes)
number: .skip 4    # signed word

.data
head_node:
.word 10
.word -4
.word node_1
.skip 10
node_1:
.word 56
.word 78
.word node_2
.skip 5
node_3:
.word -100
.word -43
.word 0
node_2:
.word -654
.word 590
.word node_3


.text
read:
    li a0, 0         # file descriptor = 0 (stdin)
    la a1, buffer    # buffer to write the data
    li a2, 8         # size
    li a7, 63        # syscall read (63)
    ecall
    ret

# a0 - size
write:
    mv a2, a0        # size
    la a1, buffer
    li a0, 1         # file descriptor = 1 (stdout)
    li a7, 64        # syscall write (64)
    ecall
    ret

exit:
    li a0, 0
    li a7, 93
    ecall

# paramaters: a0 - address of the string, a1 - address where the number will be stored
# returns address where the conversion stopped
atoi:
    li t1, 10     # base 10
    li a2, 0      # holds number being computed
    li a3, 0      # indicates whether number is negative (1) or positive (0)
    lbu t2, (a0)
    li t0, '-'
    bne t2, t0, pos # if 1st digit isn't '-' the number is positive
    li a3, 1      # negative
    addi a0, a0, 1 # skip the minus sign
    pos:
    li t3, '9'    # 1st stop condition
    li t0, '0'    # 2nd stop condition
    1:
        lbu t2, (a0)         # get current digit
        bgt t2, t3, 1f       # if digit > '9' then end loop
        blt t2, t0, 1f       # if digit < '0' then end loop
        addi t2, t2, -'0'    # convert to number
        mul a2, a2, t1       # multiply by 10
        add a2, a2, t2       # add digit
        addi a0, a0, 1
        j 1b
    1:
    li t0, 1
    bne a3, t0, pos2
    sub a2, x0, a2
    pos2:
    sw a2, (a1)    # storing the number
    ret

# parameters: a0 - number
# returns the number length
itoa:
    addi sp, sp, -1
    li t0, '\n' # stack line break (last byte)
    sb t0, (sp)
    li a1, 0    # indicates whether number is negative (1) or positive (0)
    bgez a0, positive_num
    li a1, 1
    sub a0, x0, a0 # a0 is the absolute value of the number
    positive_num:
    li t1, 10 # base 10
    1:
        rem t0, a0, t1 # t0 is the last digit of a0
        addi t0, t0, '0' # turn into ascii character
        addi sp, sp, -1 # update sp
        sb t0, (sp) # stack digit
        divu a0, a0, t1 # divide number by 10 (remove last digit)
        beqz a0, 1f # if it's equal to zero, there's no more digits to stack
        j 1b
    1:
    beqz a1, positive_num_2
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp) # stack minus sign if number is negative
    positive_num_2:
    # popping the digits from the stack and storing in the buffer
    li t0, '\n'
    li a0, 1
    la a1, buffer
    1:
        lbu t1, (sp) # t1 <= digit
        addi sp, sp, 1 # update sp
        sb t1, (a1)
        addi a1, a1, 1
        addi a0, a0, 1
        beq t1, t0, 1f # if digit == line break then end
        j 1b
    1:
    ret

# parameters: a0 - number
find_node:
    la a1, head_node
    li a2, 0 # node index
    1:
        beqz a1, 1f          # stop if a1 == NULL
        lw t0, (a1)          # t0 <= VAL1
        lw t1, 4(a1)         # t1 <= VAL2
        add t0, t0, t1       # t0 <= VAL1 + VAL2
        beq t0, a0, found    # t0 == number then done
        addi a2, a2, 1       # next node
        lw a1, 8(a1)         # points to next node
        j 1b
    1:
    li a0, -1    # index -1 if the sum wasn't found
    ret
    found:
    mv a0, a2
    ret

_start:
    jal read
    la a0, buffer
    la a1, number
    jal atoi
    lw a0, number
    jal find_node
    jal itoa
    jal write
    jal exit