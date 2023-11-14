.bss
.align 4
isr_stack:
.skip 4096
isr_stack_end:
# _system_time: .skip 4

.text
.align 2
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

.align 2

# a0: movement direction (-1/0/1), a1: steering wheel angle (-127, 127)
syscall_set_engine_and_steering:
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
    li t0, STEERING_WHEEL_REG_PORT
    sb a1, (t0)
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0)
    # returning
    li a0, 0  # syscall successful
    j return_result
invalid_val:
    li a0, -1  # syscall failed
return_result:
    ret

# Parameters: a0, a1, a2 - address of the variable that will store the value of x, y, z position, respectively
syscall_get_position:
    # busy waiting on GPS reading
    li t0, GPS_REG_PORT
    li t1, 1
    sb t1, (t0)  # triggers gps read
1:  # loops until reading is complete
    lbu t1, (t0)
    beqz t1, 1f
    j 1b
1:
    # loop end, storing values
    li t0, X_AXIS_DATA_PORT
    lw t1, 0(t0)          # t1 <= x position
    sw t1, (a0)           # storing x position
    lw t1, 4(t0)          # t2 <= y position
    sw t1, (a1)           # storing y position
    lw t1, 8(t0)          # t2 <= z position
    sw t1, (a2)           # storing z position
    ret

# Parameters: a0, a1, a2 - address of the variable that will store the value of x, y, z angle, respectively
syscall_get_rotation:
    # busy waiting on GPS reading
    li t0, GPS_REG_PORT
    li t1, 1
    sb t1, (t0) # triggers gps read
1:  # loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # loop end, storing values
    li t0, EULER_ANG_X_DATA_PORT
    lw t1, 0(t0)          # t1 <= x angle
    sw t1, (a0)           # storing x angle
    lw t1, 4(t0)          # t2 <= y angle
    sw t1, (a1)           # storing y angle
    lw t1, 8(t0)          # t2 <= z angle
    sw t1, (a2)           # storing z angle
    ret

# Parameters: a0 - 1 (enabled), 0 (disabled)
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0 - address of an array with 256 elements that will store 
#                  the values read by the luminosity sensor
syscall_read_sensors:
    # busy waiting on line camera reading
    li t0, LINE_CAMERA_REG_PORT
    li t1, 1
    sb t1, (t0)
1:  # loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # loop end
    li t1, CAMERA_IMAGE_DATA_PORT  # t1 <= address where image is stored
    addi t0, t1, 256               # end address (stop condition)
1:  # loops for each byte
    lbu t2, (t1)                   # load current byte
    sb t2, (a0)                    # store in array
    addi t1, t1, 1                 # next byte
    addi a0, a0, 1                 # next byte
    bltu t1, t0, 1b                # loop if end address hasn't been reached
    ret

# return value: value obtained on the sensor reading; -1 in case no object has been detected in less than 20 meters
syscall_read_sensor_distance:
    # busy waiting on sensor reading
    li t0, SENSOR_REG_PORT
    li t1, 1
    sb t1, (t0)
1:  # loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # loop end
    li t0, SENSOR_DIST_DATA_PORT
    lw a0, (t0)           # a0 <= distance (in cm)
    ret

# Parameters: a0 - buffer, a1 - size
# Return value: a0 - number of characters read
syscall_read_serial:
    li t0, 0         # counter (number of characters read)
1:  # loops for each character
    bgeu t0, a1, 1f  # if t0 >= size, then end loop
    # busy waiting on serial port reading
    li t1, 1
    li t2, READ_REG_PORT
    sb t1, (t2)      # trigger read
2:  # loops until reading is complete
    lbu t1, (t2)
    bnez t1, 2b
    # loop end
    li t2, READ_REG_DATA
    lbu t1, (t2)     # t1 <= current byte
    beqz t1, 1f      # if byte is null, then end loop
    add t2, a0, t0   # t2 <= address where byte will be stored
    sb t1, (t2)      # stores byte
    addi t0, t0, 1   # increments counter
    j 1b
1:
    mv a0, t0        # a0 <= number of characters read
    ret

# Parameters: a0 - buffer, a1 - size
syscall_write_serial:
    # writing string
    add t0, a0, a1  # t0 <= stop condition (end address = buffer address + size)
1:  # loops for each character
    bge a0, t0, 1f  # if current address >= end address, then end loop
    lbu t1, (a0)    # loads character
    li t2, WRITE_REG_DATA
    sb t1, (t2)     # stores byte
    # busy waiting on serial port writing
    li t2, WRITE_REG_PORT
    li t1, 1
    sb t1, (t2)     # triggers write
2:
    lbu t1, (t2)    # load byte at reg port
    bnez t1, 2b     # if it's not zero, then loop
    # loop end
    addi a0, a0, 1  # update address
    j 1b
1:
    ret

syscall_get_systime:
    li t0, GPT_REG_PORT
    li t1, 1
    sb t1, (t0)             # triggers the GPT
1:  # loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # loop end, returning system time
    li t0, TIME_DATA_PORT  # t0 <= address where time is stored
    lw a0, (t0)            # a0 <= current time
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
    sw ra, 52(sp)
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
    lw ra, 52(sp)
    addi sp, sp, 64
    csrrw sp, mscratch, sp  # switches sp and mscratch again
    mret                    # returns from interrupt

.globl _start
_start:
    # jal syscall_get_systime
    # la t0, _system_time
    # sw a0, (t0)
    # registering the ISR (Direct mode)
    la t0, int_handler     # loads the address of the routine that will handle interrupts
    csrw mtvec, t0         # (and syscalls) on the register MTVEC to set the interrupt array.
    # initializing stacks
    la t0, isr_stack_end
    csrw mscratch, t0      # sets ISR stack
    li sp, 0x07FFFFFC      # sets user stack
    # la sp, user_stack_end  # sets user stack
    # setting user mode
    li t0, 0x1800
    csrc mstatus, t0       # updates the mstatus.MPP field (bits 11-12) with value 00 (U-mode)
    # enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0       # sets mstatus.MIE (bit 3) as 1
    # enabling external interrupts
    li t0, 0x800
    csrs mie, t0           # sets mie.MEIE (bit 11) as 1
    # loading user software
    la t0, main 
    csrw mepc, t0          # loads the user software entry point into mepc
    mret                   # PC <= MEPC, mode <= MPP