.bss
buffer: .skip 100

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

# read until '\n'
read:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # reading
    li s1, '\n' # break condition
    li s2, 0 # t3 is the string's length in ascii digits (including '\n')
    # loops until line break
    1:
        jal read_byte # byte read is stored in a0
        addi sp, sp, -1 # update sp
        sb a0, (sp) # stack digit
        addi s2, s2, 1 # increment length
        beq a0, s1, 1f # if byte is a line break, end loop
        j 1b
    1:
    debug_pqp:
    mv t0, sp # t0 <= address to backwards string
    add sp, sp, s2 # (partially) reset sp
    mv t1, s2 # t1 <= length
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    # inverting and storing string
    mv t2, sp # address to the start of the stack
    sub sp, sp, t1
    1:
        beqz t1, 1f
        lbu t3, (t0) # load string byte (starting from last)
        sb t3, (t2) # store at the start
        # updating addresses
        addi t0, t0, 1
        addi t2, t2, -1
        addi t1, t1, -1
        j 1b
    1:
    debug_pqp_2:
    addi t2, t2, 1
    mv a0, t2 # address to the start of the string
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
        addi s1, s1, 1 # update pointer
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

# receives string on a0
# reverses in-place, returns a0
reverse_string:
    addi sp, sp, -16
    sw ra, (sp)

    mv t0, a0
    li t1, '\n'
    # loops until finding a line break
    1:
        lbu t2, (t0) # load byte
        beq t2, t1, 1f # if it's a line break, end loop
        add t0, t0, 1 # update pointer
        j 1b
    1:
    add t0, t0, -1 # t0 is now the address of the last byte in the string (excluding the line break)
    mv t1, a0
    1:
        bge t1, t0, 1f
        lbu t2, (t0)
        lbu t3, (t1)
        sb t3, (t0)
        sb t2, (t1)
        addi t0, t0, -1
        addi t1, t1, 1
        j 1b
    1:
    lw ra, (sp)
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

_start:
    li sp, 0x7FFFFFC
    jal read
    lbu t0, (a0) # t0 <= operation byte
    li t1, '1'
    beq t0, t1, op_1
    li t1, '2'
    beq t0, t1, op_2
    li t1, '3'
    beq t0, t1, op_3
    li t1, '4'
    beq t0, t1, op_4
op_1:
    jal read
    jal write
    j end
op_2:
    jal read
    jal reverse_string
    jal write
    j end
op_3:
    jal read
    mv s1, a0 # s1 <= address of number in base 10
    jal atoi
    mv a1, s1 # override previous string (base 10) with number in base 16
    li a2, 16 # base 16
    jal itoa
    jal write
    j end
op_4:
    jal read
    mv s1, a0
    jal perform_arithmetic_operation
    mv a1, s1
    li a2, 10
    jal itoa
    jal write
    j end
end:
    li a0, 0
    jal exit


# Terminate calling process
# Parameters: a0 - status code
# No return value
exit:
    li a7, 93    # syscall exit (93)
    ecall
    ret

# Parses the C-string pointed by a0 interpreting its content as an integral number,
# which is returned as a value of type int.
# Parameters: a0 - address of the string
# Return value: a0 - integer represented by the string
atoi:
    li t1, 10            # base 10
    li a2, 0             # holds number being computed
    li a3, 0             # a3 indicates whether number is negative (1) or positive (0)
    lbu t2, (a0)         # 1st digit
    li t0, '-'
    bne t2, t0, pos      # if 1st digit isn't '-' the number is positive
    li a3, 1             # negative
    addi a0, a0, 1       # skip the minus sign
pos:
    li t3, '9'           # 1st stop condition
    li t0, '0'           # 2nd stop condition
1:
    lbu t2, (a0)         # get current digit
    bgt t2, t3, 1f       # if digit > '9' then end loop
    blt t2, t0, 1f       # if digit < '0' then end loop
    addi t2, t2, -'0'    # convert digit
    mul a2, a2, t1       # multiply number by 10
    add a2, a2, t2       # add digit
    addi a0, a0, 1       # update address
    j 1b
1:
    li t0, 1
    bne a3, t0, return   # if a3 != 1, number is positive (just return)
    sub a2, x0, a2       # invert the number (negative)
return:
    mv a0, a2
    ret

# Converts an integer value to a null-terminated string using the specified base
# and stores the result in the address in a1.
# Parameters: a0 - value to be converted to a string
#             a1 - address where the resulting string will be stored
#             a2 - numerical base used to represent the value as a string
# Return value: a0 - a pointer to the resulting null-terminated string
itoa:
    # converting number to ascii and stacking its digits
    addi sp, sp, -1
    li t0, '\n'            # stack line break (last byte)
    sb t0, (sp)
    li t2, 0               # t2 indicates whether the number is negative (1) or positive (0)
    li t2, 10
    bne a2, t2, not_negative # if base is not 10, jump to number conversion
    li t3, 1               # t3 is the number's length in ascii digits (including 0)
    bgez a0, not_negative
    li t2, 1
    sub a0, x0, a0         # a0 is the absolute value of the number
not_negative:
1:                         # loops for each digit
    remu t0, a0, a2        # t0 <= a0 % base (value of current digit)
    li t1, 10
    bge t0, t1, letter     # if t0 >= 10 the digit will be a letter
    addi t0, t0, '0'       # turn value into ascii character
    j stack_digit
letter:
    sub t0, t0, t1         # t0 <= value - 10
    li t1, 'A'
    add t0, t1, t0         # t0 <= letter that represents the value
stack_digit:
    addi sp, sp, -1        # update sp
    sb t0, (sp)            # stack digit
    addi t3, t3, 1         # increment length
    divu a0, a0, a2        # a0 <= a0 / base
    beqz a0, 1f            # if a0 == 0, there's no more digits to stack
    j 1b
1:
    # treating negative case
    beqz t2, cp_num        # if not negative, jump to wr_num
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp)            # stack minus sign if number is negative
    addi t3, t3, 1         # increment length
cp_num:
    # copying to the parameter address
    mv a0, a1
    mv t0, t3              # t0 <= length
    mv t1, sp              # address of current digit
1:
    beqz t0, 1f            # if counter == 0 then end loop
    lbu t2, (t1)
    sb t2, (a1)
    addi t0, t0, -1        # update counter
    addi t1, t1, 1         # update address
    addi a1, a1, 1         # update address
    j 1b
1:
    # popping digits from stack
    add sp, sp, t3
    ret