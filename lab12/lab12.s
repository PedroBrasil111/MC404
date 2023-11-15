.text
# Serial Port - 0xFFFF0100 - 0xFFFF0300
.set WRITE_CONTROL_REG_PORT, 0xFFFF0100    # unsigned byte
.set WRITE_REG_PORT, 0xFFFF0101            # unsigned byte
.set READ_CONTROL_REG_PORT, 0xFFFF0102     # unsigned byte
.set READ_DATA_REG_PORT, 0xFFFF0103        # unsigned byte

# Reads one byte from the Serial Port
# Return value: a0 - Byte read
read_byte:
    li t0, READ_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)  # Trigger read
1:  # Loops until reading is complete
    lbu t1, (t0) # Load byte at reg port
    bnez t1, 1b  # If it's not zero, loop
    # Loop end
    li t0, READ_DATA_REG_PORT
    lbu a0, (t0) # Load byte onto a0
    ret

# Writes one byte to the Serial Port
# Parameters: a0 - Byte that will be written
write_byte:
    li t0, WRITE_REG_PORT
    sb a0, (t0)  # Stores byte
    li t0, WRITE_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)  # Trigger write
1:  # Loops until writing is complete
    lbu t1, (t0) # Load byte at reg port
    bnez t1, 1b  # If it's not zero, then loop
    # Loop end
    ret

# Writes a string to the Serial Port until reaching a line break character
# Parameters: a0 - Address of the string
write:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Writing string
    mv s1, a0
    li s2, '\n'
1:  # Loops for each byte
    lbu a0, (s1)   # Load byte
    beq a0, s2, 1f # If it's a line break, end loop
    jal write_byte
    addi s1, s1, 1 # Update address (next byte)
    j 1b
1:
    mv a0, s2      # a0 <= '\n'
    jal write_byte # Write line break
    # Loading registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Parses the string pointed by a0 interpreting its content as an integral number,
# which is returned as a value of type int.
# Parameters: a0 - Address of the string
# Return value: a0 - Integer represented by the string
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
    bne a3, t0, ret_atoi # if a3 != 1, number is positive (just return)
    sub a2, x0, a2       # invert the number (negative)
ret_atoi:
    mv a0, a2
    ret

# Given a string in the format "num1 op num2\n", where num1 and num2 are
# numbers of arbitrary size in base 10 and op is the symbols of a
# basic math operation (addition, subtraction, multiplication or division),
# returns the result of the operation
# Parameters: a0 - String address
# Return value: a0 - Operation result
perform_arithmetic_operation:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Initial manipulations
    mv s1, a0      # s1 <= string address
    jal atoi
    mv s2, a0      # s2 now holds 1st number
    mv t0, s1      # t0 <= address to the start of the string
    li t1, ' '
1:  # Loops until reaching space
    lbu t2, (t0)
    addi t0, t0, 1
    bne t2, t1, 1b
    # Loop end, now t0 points to the operation symbol
    lbu s3, (t0)   # s3 <= operation
    addi a0, t0, 2 # a0 points to the 2nd number
    jal atoi       # a0 is now the 2nd number
    # Checking operation
    li t0, '-'
    beq s3, t0, subtract
    li t0, '*'
    beq s3, t0, multiply
    li t0, '/'
    beq s3, t0, divide
    # add:
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
    # Loading registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Converts an integer value to a string using the specified base
# and stores the result in the address in a1.
# Parameters: a0 - Value to be converted to a string
#             a1 - Address where the resulting string will be stored
#             a2 - Numerical base used to represent the value as a string
# Return value: a0 - A pointer to the resulting string
itoa:
    # Converting number to ascii and stacking its digits
    addi sp, sp, -1
    li t0, '\n'              # Stack line break (last byte)
    sb t0, (sp)
    li t2, 0                 # t2 indicates whether the number is negative (1) or positive (0)
    li t3, 1                 # t3 is the number's length in ascii digits (including \n)
    li t0, 10
    bne a2, t0, not_negative # if not base 10, treat as unsigned number
    bgez a0, not_negative
    li t2, 1
    sub a0, x0, a0           # a0 is the absolute value of the number
not_negative:
1:  # Loops for each digit
    remu t0, a0, a2          # t0 <= a0 % base (value of current digit)
    li t1, 10
    bge t0, t1, letter       # If t0 >= 10 the digit will be a letter
    addi t0, t0, '0'         # Turn value into ascii character
    j stack_digit
letter:
    sub t0, t0, t1           # t0 <= value - 10
    li t1, 'A'
    add t0, t1, t0           # t0 <= letter that represents the value
stack_digit:
    addi sp, sp, -1          # Update sp
    sb t0, (sp)              # Stack digit
    addi t3, t3, 1           # Increment length
    divu a0, a0, a2          # a0 <= a0 / base
    bnez a0, 1b              # If a0 != 0, there's no more digits to stack
    # Treating negative case
    beqz t2, cp_num          # If not negative, jump to cp_num
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp)              # Stack minus sign if number is negative
    addi t3, t3, 1           # Increment length
cp_num:
    # Copying to the parameter address
    mv a0, a1
    mv t0, t3                # t0 <= length (counter for next loop)
    mv t1, sp                # Address of current digit
1: # Loops for each byte
    beqz t0, 1f              # If counter == 0 then end loop
    lbu t2, (t1)
    sb t2, (a1)
    addi t0, t0, -1          # Update counter
    addi t1, t1, 1           # Update address
    addi a1, a1, 1           # Update address
    j 1b
1:
    # Popping digits from stack
    add sp, sp, t3
    ret

# a0 - buffer, a1 - size
# reverses in place, returns buffer address
reverse_string:
    mv t0, a0       # t0 starts pointing at the 1st address of the string
                    # it will keep being incremented by 1 (ascending address),
    add t1, a0, a1  # while t1 points to its end, and will be incremented
                    # by -1 (descending address)
    addi t1, t1, -1
1:  # Loops inverting the string
    # Loading bytes
    lbu t2, (t0)
    lbu t3, (t1)
    # Inverting bytes
    sb t2, (t1)
    sb t3, (t0)
    # Incrementing addresses
    addi t0, t0, 1
    addi t1, t1, -1
    blt t0, t1, 1b  # Loop while asc. address < desc. address
    # Loop end
    ret

# Terminate calling process
# Parameters: a0 - status code
# No return value
exit:
    li a7, 93    # syscall exit (93)
    ecall
    ret

.globl _start
_start:
    # Reading operation code
    jal read_byte   # Returns the operation code
    mv s1, a0       # s1 <= operation code
    jal read_byte   # Remove line break character from buffer
    # Reading string with variable size
    li s2, 0        # s2 holds the string's length (including \n)
1:  # Loops for each byte on the buffer (until reaching \n)
    jal read_byte   # a0 <= byte read
    addi sp, sp, -1
    sb a0, (sp)     # Stack byte
    addi s2, s2, 1  # Increment length
    li t1, '\n'
    beq a0, t1, 1f  # If byte is \n, break loop
    j 1b            # Loop
1:
    # Reversing the string (because it was stacked)
    mv a0, sp       # a0 <= string address
    mv a1, s2       # a1 <= length (with \n)
    jal reverse_string
    addi s2, s2, -1 # s2 is now the actual length of the string
    # Checking operations
    li t0, '1'
    beq s1, t0, op_1
    addi t0, t0, 1
    beq s1, t0, op_2
    addi t0, t0, 1
    beq s1, t0, op_3
    addi t0, t0, 1
    beq s1, t0, op_4
op_1:
    jal write
    j end
op_2:
    mv a1, s2 # a1 <= length
    jal reverse_string
    jal write
    j end
op_3:
    jal atoi  # a0 <= value of the number in base 10
    mv a1, sp # a1 <= buffer address
    li a2, 16 # base 16
    jal itoa
    jal write
    j end
op_4:
    jal perform_arithmetic_operation
    # a0 is now the result of the operation
    mv a1, sp # a1 <= buffer address
    li a2, 10 # base 10
    jal itoa
    jal write
    j end
end:
    add sp, sp, s2
    add sp, sp, 1 # sp is now back to its starting value
    li a0, 0
    jal exit