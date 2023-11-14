.text
.globl _start

.set NULL, 0

.set WRITE_REG_PORT, 0xFFFF0100
.set WRITE_REG_DATA, 0xFFFF0101
.set READ_REG_PORT, 0xFFFF0102
.set READ_REG_DATA, 0xFFFF0103

# reads one byte and returns it
read_byte:
    li t0, READ_REG_PORT
    li t1, 1
    sb t1, (t0) # triggers read
    # loops until reading is complete
    1:
        lbu t1, (t0) # load byte at reg port
        bnez t1, 1b # if it's not zero, loop
    1:
    li t0, READ_REG_DATA
    lbu a0, (t0) # loads byte onto a0
    ret

# receives byte on a0
write_byte:
    li t0, WRITE_REG_DATA
    sb a0, (t0) # store byte
    li t0, WRITE_REG_PORT
    li t1, 1
    sb t1, (t0) # trigger write
    # loops until writing is complete
    1:
        lbu t1, (t0) # load byte at reg port
        bnez t1, 1b # if it's not zero, loop
    1:
    ret

# receives string on a0
# writes until reaching '\n'
write:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # writing string
    mv s1, a0
    li s2, '\n'
1:
    lbu a0, (s1) # load byte
    beq a0, s2, 1f # if it's a line break, end loop
    jal write_byte
    addi s1, s1, 1 # move s1 to the address of the next byte
    j 1b
1:
    mv a0, s2
    jal write_byte # write line break
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Parameters: a0 - string address
# Return value: a0 - operation result
perform_arithmetic_operation:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    #
    mv s1, a0 # s1 <= string address
    jal atoi
    mv s2, a0 # s2 is now the 1st number
    mv t0, s1
    li t1, ' '
1: # loops until reaching space
    lbu t2, (t0)
    addi t0, t0, 1
    bne t2, t1, 1b
    # loop end
    lbu s3, (t0) # s3 <= operation
    addi a0, t0, 2 # a0 points to the 2nd number
    jal atoi # a0 is now the 2nd number
    li t0, '-'
    beq s3, t0, subtract
    li t0, '*'
    beq s3, t0, multiply
    li t0, '/'
    beq s3, t0, divide
    # add
    add a0, s2, a0
    j end_op
    subtract:
    sub a0, s2, a0
    j end_op
    multiply:
    mul a0, s2, a0
    j end_op
    divide:
    div a0, s2, a0
    j end_op
    end_op:
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

