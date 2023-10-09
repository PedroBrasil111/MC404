.text
.globl recursive_tree_search
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit

# Reads characters from the standard input (stdin) and stores them as a C string
# into str until a newline character is reached.
# Parameters: a0 - string size, a1 - buffer address
read:
    mv a2, a0
    li a0, 0      # file descriptor = 0 (stdin)
    li a7, 63     # syscall read (63)
    ecall
    ret


# Parameters: a0 - string size, a1 - buffer where string is stored
write:
    mv a2, a0        # size
    li a0, 1         # file descriptor = 1 (stdout)
    li a7, 64        # syscall write (64)
    ecall
    ret

# Writes the C string pointed by str to the standard output (stdout) 
# and appends a newline character ('\n').
# Parameters: a0 - string terminated by \0
# No return value
puts:
    # storing registers
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s1, 4(sp)
    # writing string
    mv s1, a0       # s1 <= string address
    li t1, 0        # t1 is the string's length
    # loops for each digit until it reaches null character
    1:
        lbu t2, (s1)       # t2 is the current character
        beqz t2, 1f        # if it's the null character, end loop
        addi t1, t1, 1     # increment length
        addi s1, s1, 1     # update address
        j 1b
    1:
    teste:
    li t2, '\n'
    sb t2, (s1) # replace null character with newline character
    mv a1, a0 # string address
    add a0, t1, 1 # length with newline character
    jal write # write string
    li t2, 0
    sb t2, (s1) # replace newline character with null character
    # restoring registers
    lw s1, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# Reads characters from the standard input (stdin) and stores them as a C string 
# into the buffer until a newline character or the end-of-file is reached.
# Parameters: a0 - buffer to be filled
# Return value: a0 - buffer address.
gets:
    # storing registers
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # initializing registers
    mv s1, a0 # s1 <= buffer address
    mv s2, a0 # s2 <= buffer address
    li s3, '\n'
    # reads and stores each character
    1:
        li a0, 1 # size read
        mv a1, s1 # address where character will be stored
        jal read # read and store character
        lbu t0, (s1) # t0 <= current character
        beq t0, s3, 1f # if it's a newline character, end loop
        addi s1, s1, 1 # update address
        j 1b
    1:
    # storing null character
    li t0, 0
    sb t0, (s1) # store null character (overrides the newline character)
    mv a0, s2 # return the string's address
    # restoring registers
    lw ra, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    ret

# Paramaters: a0 - ascii number's address
# Return value: a0 - integer represented by the string
atoi:
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
        addi a0, a0, 1       # update address
        j 1b
    1:
    li t0, 1
    bne a3, t0, return       # if a3 != 1, number is positive (just return)
    sub a2, x0, a2           # invert the number (negative)
    return:
    mv a0, a2
    ret

# Parameters: a0 - value to be converted to a string
#             a1 - address where to store the resulting null-terminated string
#             a2 - numerical base used to represent the value as a string
# Return value: a0 - a pointer to the resulting null-terminated string
itoa:
    # converting number to ascii and stacking its digits
    addi sp, sp, -1
    li t0, 0          # stack null character (last byte)
    sb t0, (sp)
    li t2, 0          # t2 indicates whether the number is negative (1) or positive (0)
    li t3, 1          # t3 is the number's length in ascii digits (including 0)
    bgez a0, not_negative
    li t2, 1
    sub a0, x0, a0    # a0 is the absolute value of the number
    not_negative:
    # loops for each digit
    1:
        remu t0, a0, a2      # t0 <= a0 % base (value of current digit)
        li t1, 10
        bgt t0, t1, letter # if t0 > 10 it should be a letter
        addi t0, t0, '0'    # turn into ascii character
        j stack_digit
        letter:
        sub t0, t0, t1 # t0 <= value - 10
        li t1, 'A'
        add t0, t1, t0 # t0 <= letter corresponding to value
        stack_digit:
        addi sp, sp, -1     # update sp
        sb t0, (sp)         # stack digit
        addi t3, t3, 1      # increment length
        divu a0, a0, a2     # a0 <= a0 / base
        beqz a0, 1f         # if a0 == 0, there's no more digits to stack
        j 1b
    1:
    # treating negative case
    beqz t2, cp_num    # if not negative, jump to wr_num
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp)        # stack minus sign if number is negative
    addi t3, t3, 1     # increment length
    cp_num:
    # copying to the parameter address
    mv a0, a1
    mv t0, t3 # t0 <= length
    mv t1, sp # address of current digit
    1:
        beqz t0, 1f # if counter == 0 then end loop
        lbu t2, (t1)
        sb t2, (a1)
        addi t0, t0, -1 # update counter
        addi t1, t1, 1 # update address
        addi a1, a1, 1 # update address
        j 1b
    1:
    # popping digits from stack
    add sp, sp, t3
    ret

# Parameters: a0 - address of the root node,
#             a1 - value being searched,
# Return value: a0 - depth of the node if the value was found, -1 otherwise
recursive_tree_search:
    # store registers
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s1, 4(sp)
    # checking root node
    mv s1, a0                    # s1 <= address of the root node
    beqz s1, null_root           # if the address is null, jump to null_root
    lw t0, 0(s1)                 # t0 is the value in the root node
    beq t0, a1, found            # if t0 is equal to the searched value, jump to found
    # searching on child nodes
    lw a0, 4(s1)                 # a0 is the address of the left child node
    jal recursive_tree_search    # searches from the left child
    bgtz a0, increment           # if the value is greather than one, it was found on the child node's tree
    lw a0, 8(s1)                 # a0 is the address of the right child node
    jal recursive_tree_search    # searches from the right child
    bgtz a0, increment           # if the value is greather than one, it was found on the child node's tree
    j ret_search                 # if the value wasn't found in any of the children, return 0 (already in a0)
    increment:
    addi a0, a0, 1               # increments depth by 1
    j ret_search                 # return depth
    null_root:
    li a0, 0                     # sets return value as 0 (value not found)
    j ret_search
    found:
    li a0, 1                     # if value was found, return 1 (depth of the root node)
    ret_search:
    # restore registers
    lw ra, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

exit:
    li a0, 0
    li a7, 93    # syscall exit
    ecall
    ret