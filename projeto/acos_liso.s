.bss
.align 4
user_stack:             # user stack's top address (1024 bytes)
.skip 1024
user_stack_end:         # user stack's base address
.align 4
isr_stack:
.skip 1024
isr_stack_end:
x_coord: .skip 4
y_coord: .skip 4
z_coord: .skip 4
_system_time: .skip 4

.text
# General Purpose Timer (GPT) - 0xFFFF0100 - 0xFFFF0300
.set GPT_REG_PORT, 0xFFFF0100  # byte  - storing “1” triggers the GPT device to start reading the
                           # current system time. The register is set to 0 when the reading is completed
.set TIME_DATA_PORT, 0xFFFF0104  # word  - stores the time (in milliseconds) at the moment of the
                           # last reading by the GPT
.set GPT_INT_DATA_PORT, 0xFFFF0108   # word  - storing v > 0 programs the GPT to generate an external interruption
                           # after v milliseconds. It also sets this register to 0 after v milliseconds
                           # (immediately before generating the interruption)
# Self Driving Car - 0xFFFF0300 - 0xFFFF0500
.set GPS_REG_PORT, 0xFFFF0300 # byte
.set LINE_CAMERA_REG_PORT, 0xFFFF0301 # byte
.set SENSOR_REG_PORT, 0xFFFF0302 # byte
.set EULER_ANG_X_DATA_PORT, 0xFFFF0304 # word
.set EULER_ANG_Y_DATA_PORT, 0xFFFF0308 # word
.set EULER_ANG_Z_DATA_PORT, 0xFFFF030C # word
.set X_AXIS_DATA_PORT, 0xFFFF0310 # word
.set Y_AXIS_DATA_PORT, 0xFFFF0314 # word
.set Z_AXIS_DATA_PORT, 0xFFFF0318 # word
.set SENSOR_DIST_DATA_PORT, 0xFFFF031C # word
.set STEERING_WHEEL_REG_PORT, 0xFFFF0320 # byte
.set ENGINE_DIR_REG_PORT, 0xFFFF0321 # byte
.set HAND_BR_REG_PORT, 0xFFFF0322 # byte
.set CAMERA_IMAGE_DATA_PORT, 0xFFFF0324 # 256-byte array
# Serial Port - 0xFFFF0500 - 0xFFFF0700
.set WRITE_REG_PORT, 0xFFFF0500 # byte - Storing “1” triggers the serial port to write (to the stdout) the byte stored at base+0x01. The register is set to 0 when writing is completed
.set WRITE_REG_DATA, 0xFFFF0501 # byte - Byte to be written.
.set READ_REG_PORT, 0xFFFF0502 # byte - Storing “1” triggers the serial port to read (from the stdin) a byte and store it at base+0x03. The register is set to 0 when reading is complete.
.set READ_REG_DATA, 0xFFFF0503 # byte - Byte read. Null when stdin is empty.

.align 4

# parameters: a0 - 0, 1 or 2 to trigger gps, line camera or ultrassonic sensor, respectively
trigger_reg_port:
    li t0, GPS_REG_PORT
    add t0, t0, a0
    li t1, 1
    sb t1, (t0) # trigger action
1:  # loops until action is completed
    lbu t1, (t0)
    bnez t1, 1b
    # loop ended - return
    ret

# Parameters: a0 - steering wheel value, ranging from -127 to 127
set_steering_wheel_angle:
    li t0, STEERING_WHEEL_REG_PORT
    sb a0, (t0) # set steering wheel direction
    ret

# Parameters: a0 - engine direction: 1 (fwd), 0 (off), -1 (bwd)
set_engine_direction:
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0)
    ret

get_object_distance:
    li a0, SENSOR_DIST_DATA_PORT
    lw a0, (a0)
    ret

# a0: movement direction (-1/0/1), a1: steering wheel angle (-127, 127)
syscall_set_engine_and_steering:
    # storing ra
    addi sp, sp, -16
    sw ra, (sp)
    # treating invalid cases
    li t0, 1
    bgt a0, t0, invalid_val
    li t0, -1
    blt a0, t0, invalid_val
    li t0, 127
    bgt a1, t0, invalid_val
    li t0, -127
    blt a1, t0, invalid_val
    # setting values
    jal set_engine_direction
    mv a0, a1
    jal set_steering_wheel_angle
    # returning
    li a0, 0 # syscall successful
    j return_result
invalid_val:
    li a0, -1 # syscall failed
return_result:
    # restoring ra
    lw ra, (sp)
    addi sp, sp, 16
    ret

# Parameters: a0 - 1 (enabled), 0 (disabled)
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0 - address of an array with 256 elements that will store 
#                  the values read by the luminosity sensor
syscall_read_sensors:
ret
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    # reading camera
    mv s1, a0                     # saves address
    li a0, 1                      # line camera code
    jal trigger_reg_port          # triggers line camera
    # copying array to parameter address
    li t1, CAMERA_IMAGE_DATA_PORT # t1 <= address where image is stored
    addi t0, t1, 256              # end address (stop condition)
1:  # loops for each byte
    lbu t2, (t1)                  # load current byte
    sb t2, (s1)                   # store in array
    addi t1, t1, 1                # next byte
    addi s1, s1, 1                # next byte
    bltu t1, t0, 1b               # loop if end address hasn't been reached
    # restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# return value: value obtained on the sensor reading; -1 in case no object has been detected in less than 20 meters
syscall_read_sensor_distance:
ret
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    # reading sensor
    li a0, 2                # ultrassonic sensor code
    jal trigger_reg_port    # triggers ultrassonic sensor
    jal get_object_distance # a0 <= distance to nearest object (in cm)
    li t0, 100
    div a0, a0, t0          # convert to meters
positive_distance:
    # restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# Parameters: a0, a1, a2 - address of the variable that will store the value of x, y, z position, respectively
syscall_get_position:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # moving addresses
    mv s1, a0
    mv s2, a1
    mv s3, a2
    # triggering gps read
    li t0, GPS_REG_PORT
    li t1, 1
    sb t1, (t0)
    1:
        lbu t1, (t0)
        bnez t1, 1b
    # li a0, 0             # gps code
    # jal trigger_reg_port # triggers gps
    # storing values
    li t0, X_AXIS_DATA_PORT
    lw t1, 0(t0)         # t1 <= x position
    sw t1, (a0)          # storing x position
    lw t1, 4(t0)         # t2 <= y position
    sw t1, (a1)          # storing y position
    lw t1, 8(t0)         # t2 <= z position
    sw t1, (a2)          # storing z position
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Parameters: a0, a1, a2 - address of the variable that will store the value of x, y, z angle, respectively
syscall_get_rotation:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # moving addresses
    mv s1, a0
    mv s2, a1
    mv s3, a2
    # triggering gps read
    li a0, 0 # gps code
    jal trigger_reg_port # triggers gps
    # storing values
    li t0, EULER_ANG_X_DATA_PORT
    lw t1, 0(t0)         # t1 <= x angle
    sw t1, (s1)          # storing x angle
    lw t1, 4(t0)         # t2 <= y angle
    sw t1, (s2)          # storing y angle
    lw t1, 8(t0)         # t2 <= z angle
    sw t1, (s3)          # storing z angle
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# reads one byte from the Serial Port and returns it
read_byte:
    li t0, READ_REG_PORT
    li t1, 1
    sb t1, (t0) # triggers read
    # loops until reading is complete
    1:
        lbu t1, (t0) # load byte at reg port
        bnez t1, 1b # if it's not zero, loop
    li t0, READ_REG_DATA
    lbu a0, (t0) # loads byte onto a0
    ret

# Parameters: a0 - byte that will be written
write_byte:
    li t0, WRITE_REG_DATA
    sb a0, (t0) # store byte
    li t0, WRITE_REG_PORT
    li t1, 1
    sb t1, (t0) # trigger write
1: # loops until writing is complete
    lbu t1, (t0) # load byte at reg port
    bnez t1, 1b # if it's not zero, loop
    ret

# Parameters: a0 - buffer, a1 - size
# Return value: a0 - number of characters read
syscall_read_serial:
    # storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # reading string
    mv s1, a0       # s1 <= buffer address
    mv s2, a1       # s2 <= size
    li s3, 0        # counter (number of characters read)
1:
    bgeu s3, s2, 1f  # if s3 >= size, then end loop
    jal read_byte   # a0 <= current byte
    beqz a0, 1f     # if byte is null, then end loop
    add t2, s1, s3  # t2 <= address where byte will be stored
    sb a0, (t2)     # stores byte
    addi s3, s3, 1  # increment counter
    li t1, '\n'     # stop condition
    beq a0, t1, 1f  # if byte == '\n', then end loop
    j 1b
1:
    mv a0, s3       # a0 <= number of characters read
    # restoring registers
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Parameters: a0 - buffer, a1 - size
syscall_write_serial:
    ret


syscall_get_systime:
    li t0, GPT_REG_PORT
    li t1, 1
    sb t1, (t0)     # trigger the GPT
1:  # loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # loop end, returning time
    li t0, TIME_DATA_PORT # t0 <= address where time is stored
    lw a0, (t0)     # a0 <= current time
    la t1, _system_time
    lw t1, (t1)
    sub a0, a0, t1
    ret

int_handler:
    ###### Syscall and Interrupts handler ######
    # storing registers
    csrrw sp, mscratch, sp  # switches sp and mscratch
    addi sp, sp, -64
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw a0, 20(sp)
    sw a1, 24(sp)
    sw a2, 28(sp)
    sw a3, 32(sp)
    sw s1, 36(sp)
    sw s2, 40(sp)
    sw s3, 44(sp)
    sw s4, 48(sp)
    # handling interrupt
    li t0, 10
    beq a7, t0, engine_and_steering_int
    li t0, 11
    beq a7, t0, handbrake_int
    li t0, 12
    beq a7, t0, read_sensors_int
    li t0, 13
    beq a7, t0, read_sensor_distance_int
    li t0, 15
    beq a7, t0, position_int
    li t0, 16
    beq a7, t0, rotation_int
    li t0, 17
    beq a7, t0, read_serial_int
    li t0, 18
    beq a7, t0, write_serial_int
    li t0, 20
    beq a7, t0, systime_int
engine_and_steering_int:
    jal syscall_set_engine_and_steering
    j syscall_ret_end
handbrake_int:
    jal syscall_set_handbrake
    j syscall_end
read_sensors_int:
    jal syscall_read_sensors
    j syscall_end
read_sensor_distance_int:
    jal syscall_read_sensor_distance
    j syscall_ret_end
position_int:
    jal syscall_get_position
    j syscall_end
rotation_int:
    jal syscall_get_rotation
    j syscall_end
read_serial_int:
    jal syscall_read_serial
    j syscall_ret_end
write_serial_int:
    jal syscall_write_serial
    j syscall_end
systime_int:
    jal syscall_get_systime
    j syscall_ret_end
syscall_end:
    lw a0, 20(sp)
syscall_ret_end:
    # setting user mode
    li t0, 0x1800           # updates the mstatus.MPP field (bits 11 and 12) with value 00 (U-mode)
    csrc mstatus, t0
    # setting return address
    csrr t0, mepc           # load return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4          # adds 4 to the return address (to return after ecall)
    csrw mepc, t0           # stores the return address back on mepc
    # restoring registers
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw a1, 24(sp)
    lw a2, 28(sp)
    lw a3, 32(sp)
    lw s1, 36(sp)
    lw s2, 40(sp)
    lw s3, 44(sp)
    lw s4, 48(sp)
    addi sp, sp, 64
    csrrw sp, mscratch, sp  # switches sp and mscratch again
    mret                    # returns from interrupt

.globl _start
_start:
    li sp, 0x7fffffc
    addi sp, sp, -4
    mv a0, sp
    li a1, 4
    jal syscall_read_serial
    addi sp, sp, 4