.bss
buffer: .skip 4
x_coord: .skip 4
y_coord: .skip 4
z_coord: .skip 4
x_ang: .skip 4
y_ang: .skip 4
z_ang: .skip 4

.text
.globl _start

.set NULL, 0
.set GPS_REG_PORT, 0xFFFF0100
.set SENSOR_REG_PORT, 0xFFFF0102
.set EULER_ANG_X_DATA_PORT, 0xFFFF0104
.set EULER_ANG_Y_DATA_PORT, 0xFFFF0108
.set EULER_ANG_Z_DATA_PORT, 0xFFFF010C
.set X_AXIS_DATA_PORT, 0xFFFF0110
.set Y_AXIS_DATA_PORT, 0xFFFF0114
.set Z_AXIS_DATA_PORT, 0xFFFF0118
.set SENSOR_DIST_DATA_PORT, 0xFFFF011C
.set STEERING_WHEEL_REG_PORT, 0xFFFF0120
.set ENGINE_DIR_REG_PORT, 0xFFFF0121
.set HAND_BR_REG_PORT, 0xFFFF0122

# parameters: a0 - register port address
trigger_reg_port:
    li t1, 1
    sb t1, (a0) # trigger action
1: # loops until action is completed
    lb t1, (a0)
    beqz t1, 1f
    j 1b
1:
    ret

trigger_gps:
    addi sp, sp, -16
    sw ra, (sp)
    li a0, GPS_REG_PORT
    jal trigger_reg_port
    lw ra, (sp)
    addi sp, sp, 16
    ret

get_coordinates:
    li t0, X_AXIS_DATA_PORT
    lw t1, 0(t0) # x
    sw t1, x_coord, t2
    lw t1, 4(t0) # y
    sw t1, y_coord, t2
    lw t1, 8(t0) # z
    sw t1, z_coord, t2
    ret

get_euler_angles:
    li t0, EULER_ANG_X_DATA_PORT
    lw t1, 0(t0) # x
    sw t1, x_ang, t2
    lw t1, 4(t0) # y
    sw t1, y_ang, t2
    lw t1, 8(t0) # z
    sw t1, z_ang, t2
    ret

trigger_sensor:
    addi sp, sp, -16
    sw ra, (sp)
    li a0, SENSOR_REG_PORT
    jal trigger_reg_port
    lw ra, (sp)
    addi sp, sp, 16
    ret

# Parameters: a0 - 1 (fwd), 0 (off), -1 (bwd)
set_engine_direction:
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0 - between -127 and 217
set_steering_wheel_direction:
    li t0, STEERING_WHEEL_REG_PORT
    sb a0, (t0) # set steering wheel direction
    ret

# Parameters: a0 - 1 (enabled), 0 (disabled)
set_hand_break:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Returns distance in a0
distance_to_obstacle:
    li a0, SENSOR_DIST_DATA_PORT
    lw a0, (a0)
    ret

_start:
    jal trigger_gps
    jal get_euler_angles
    test:
    lw a0, x_ang
    la a1, buffer
    li a2, 10
    jal itoa
    jal puts
    lw a0, y_ang
    la a1, buffer
    li a2, 10
    jal itoa
    la a1, buffer
    jal puts
    lw a0, z_ang
    la a1, buffer
    li a2, 10
    jal itoa
    la a1, buffer
    jal puts
    li a0, 0
    jal exit

# Writes the C string pointed by a0 to the standard output (stdout)
# and appends a newline character ('\n').
# Parameters: a0 - address of the string (terminated by a null character)
# No return value
puts:
    # storing registers
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s1, 4(sp)
    # writing string
    mv s1, a0          # s1 <= string address
    li t1, 0           # t1 is the string's length
1: # loops for each digit until it reaches a null character
    lbu t2, (s1)       # t2 is the current character
    beqz t2, 1f        # if it's the null character, end loop
    addi t1, t1, 1     # increment length
    addi s1, s1, 1     # update address
    j 1b
1:
    li t2, '\n'
    sb t2, (s1)        # replace null character with newline character
    mv a1, a0          # string address
    add a0, t1, 1      # length with newline character
    jal write          # write string
    li t2, NULL
    sb t2, (s1)        # replace newline character with null character
    # restoring registers and returning
    lw s1, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# Terminate calling process
# Parameters: a0 - status code
# No return value
exit:
    li a7, 93    # syscall exit (93)
    ecall
    ret

# Parameters: a0 - string size, a1 - buffer where string is stored
# No return value
write:
    mv a2, a0    # size
    li a0, 1     # file descriptor = 1 (stdout)
    li a7, 64    # syscall write (64)
    ecall
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
    li t0, NULL            # stack null character (last byte)
    sb t0, (sp)
    li t2, 0               # t2 indicates whether the number is negative (1) or positive (0)
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