.bss
.align 4
isr_stack:
.skip 4096
isr_stack_end:

.text
.align 2

# General Purpose Timer (GPT) - 0xFFFF0100 - 0xFFFF0300
.set GPT_CONTROL_REG_PORT, 0xFFFF0100      # unsigned byte
.set SYSTIME_DATA_REG_PORT, 0xFFFF0104     # unsigned word 
.set GPT_INTERRUPT_DATA_PORT, 0xFFFF0108   # unsigned word
# Self Driving Car - 0xFFFF0300 - 0xFFFF0500
.set GPS_CONTROL_REG_PORT, 0xFFFF0300      # unsigned byte
.set CAM_CONTROL_REG_PORT, 0xFFFF0301      # unsigned byte
.set SENSOR_CONTROL_REG_PORT, 0xFFFF0302   # unsigned byte
.set X_ANGLE_DATA_REG_PORT, 0xFFFF0304     # word
.set Y_ANGLE_DATA_REG_PORT, 0xFFFF0308     # word
.set Z_ANGLE_DATA_REG_PORT, 0xFFFF030C     # word
.set X_POSITION_DATA_REG_PORT, 0xFFFF0310  # word
.set Y_POSITION_DATA_REG_PORT, 0xFFFF0314  # word
.set Z_POSITION_DATA_REG_PORT, 0xFFFF0318  # word
.set SENSOR_DIST_DATA_REG_PORT, 0xFFFF031C # word
.set STEERING_WHEEL_REG_PORT, 0xFFFF0320   # byte
.set ENGINE_DIR_REG_PORT, 0xFFFF0321       # byte
.set HAND_BR_REG_PORT, 0xFFFF0322          # unsigned byte
.set CAMERA_IMG_DATA_PORT, 0xFFFF0324      # 256-unsigned byte array
# Serial Port - 0xFFFF0500 - 0xFFFF0700
.set WRITE_CONTROL_REG_PORT, 0xFFFF0500    # unsigned byte
.set WRITE_REG_PORT, 0xFFFF0501            # unsigned byte
.set READ_CONTROL_REG_PORT, 0xFFFF0502     # unsigned byte
.set READ_DATA_REG_PORT, 0xFFFF0503        # unsigned byte


# Parameters: a0 - Movement direction (-1/0/1), a1 - Steering wheel angle (-127, 127)
syscall_set_engine_and_steering:
    # Checking for invalid values
    li t0, 1
    bgt a0, t0, invalid_val
    li t0, -1
    blt a0, t0, invalid_val
    li t0, 127
    bgt a1, t0, invalid_val
    li t0, -127
    blt a1, t0, invalid_val
    # Setting values
    li t0, STEERING_WHEEL_REG_PORT
    sb a1, (t0)
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0)
    # Returning
    li a0, 0   # Syscall successful
    j return_result
invalid_val:
    li a0, -1  # Syscall failed
return_result:
    ret

# Parameters: a0, a1, a2 - Address of the variable that will store the value of x, y, z position, respectively
syscall_get_position:
    # Busy waiting on GPS reading
    li t0, GPS_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)           # Triggers gps read
1:  # Loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end, storing values
    li t0, X_POSITION_DATA_REG_PORT
    lw t1, 0(t0)          # t1 <= x position
    sw t1, (a0)           # Stores x position
    lw t1, 4(t0)          # t2 <= y position
    sw t1, (a1)           # Stores y position
    lw t1, 8(t0)          # t2 <= z position
    sw t1, (a2)           # Stores z position
    ret

# Parameters: a0, a1, a2 - Address of the variable that will store the value of x, y, z angle, respectively
syscall_get_rotation:
    # Busy waiting on GPS reading
    li t0, GPS_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)           # Triggers gps read
1:  # Loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end, storing values
    li t0, X_ANGLE_DATA_REG_PORT
    lw t1, 0(t0)          # t1 <= x angle
    sw t1, (a0)           # Stores x angle
    lw t1, 4(t0)          # t2 <= y angle
    sw t1, (a1)           # Stores y angle
    lw t1, 8(t0)          # t2 <= z angle
    sw t1, (a2)           # Stores z angle
    ret

# Parameters: a0 - 1 (enabled), 0 (disabled)
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0 - Address of an array with 256 elements that will store 
#                  the values read by the luminosity sensor
syscall_read_sensors:
    # Busy waiting on line camera reading
    li t0, CAM_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)
1:  # Loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end
    li t1, CAMERA_IMG_DATA_PORT # t1 <= address where image is stored
    addi t0, t1, 256            # End address (stop condition)
1:  # Loops for each byte
    lbu t2, (t1)                # Loads current byte
    sb t2, (a0)                 # Stores in array
    addi t1, t1, 1              # Next byte
    addi a0, a0, 1              # Next byte
    bltu t1, t0, 1b             # Loops if end address hasn't been reached
    ret

# Return value: a0 - Value obtained on the sensor reading; -1 in case no object has been detected in less than 20 meters
syscall_read_sensor_distance:
    # Busy waiting on sensor reading
    li t0, SENSOR_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)
1:  # Loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end
    li t0, SENSOR_DIST_DATA_REG_PORT
    lw a0, (t0)           # a0 <= distance (in cm)
    ret

# Parameters: a0 - Buffer, a1 - Size
# Return value: a0 - Number of characters read
syscall_read_serial:
    li t0, 0         # t0 counts the number of characters read
1:  # Loops for each character
    bgeu t0, a1, 1f  # If t0 >= size, then end loop
    # Busy waiting on serial port reading
    li t1, 1
    li t2, READ_CONTROL_REG_PORT
    sb t1, (t2)      # Triggers read
2:  # Loops until reading is complete
    lbu t1, (t2)
    bnez t1, 2b
    # Loop end
    li t2, READ_DATA_REG_PORT
    lbu t1, (t2)     # t1 <= current byte
    beqz t1, 1f      # If byte is null, then end loop
    add t2, a0, t0   # t2 <= address where byte will be stored
    sb t1, (t2)      # Stores byte
    addi t0, t0, 1   # Increments counter
    j 1b
1:
    mv a0, t0        # a0 <= number of characters read
    ret

# Parameters: a0 - Buffer, a1 - Size
syscall_write_serial:
    # Writing string
    add t0, a0, a1  # t0 <= stop condition (end address = buffer address + size)
1:  # Loops for each character
    bge a0, t0, 1f  # If current address >= end address, then end loop
    lbu t1, (a0)    # Loads character
    li t2, WRITE_REG_PORT
    sb t1, (t2)     # Stores byte
    # Busy waiting on serial port writing
    li t2, WRITE_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t2)     # Triggers write
2:  # Loops until byte has ben written
    lbu t1, (t2)    # Load byte at reg port
    bnez t1, 2b     # If it's not zero, then loop
    # Loop end
    addi a0, a0, 1  # Update address
    j 1b
1:
###########################
    li t0, WRITE_REG_PORT
    li t1, '\n'
    sb t1, (t0)
    li t0, WRITE_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)
naosei:
    lbu t1, (t0)
    bnez t1, naosei
###########################
    ret

# Return value: a0 - Current system time
syscall_get_systime:
    li t0, GPT_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0)                  # Triggers the GPT
1:  # Loops until reading is complete
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end, returning system time
    li t0, SYSTIME_DATA_REG_PORT # t0 <= address where time is stored
    lw a0, (t0)                  # a0 <= current time
    ret

int_handler:
    ###### Syscall and Interrupts handler ######
    # Storing context
    csrrw sp, mscratch, sp  # Switches sp and mscratch
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
    # Determining which ISR to call
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
syscall_end:                # Label for syscalls that don't have return values
    lw a0, 20(sp)           # Since there's no return, a0 is restored
syscall_ret_end:            # Label for syscalls that return something
    # Setting user mode
    li t0, 0x1800           # Updates the mstatus.MPP field (bits 11 and 12) with value 00 (U-mode)
    csrc mstatus, t0
    # Setting return address
    csrr t0, mepc           # Loads return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4          # Adds 4 to the return address (to return after ecall)
    csrw mepc, t0           # Stores the return address back on mepc
    # Recovering context
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
    csrrw sp, mscratch, sp  # Switches sp and mscratch again
    mret                    # Returns from interrupt

.globl _start
_start:
    # Registering the ISR (Direct mode)
    la t0, int_handler     # Loads the address of the routine that will handle interrupts
    csrw mtvec, t0         # (and syscalls) on the register MTVEC to set the interrupt array.
    # Initializing stacks
    la t0, isr_stack_end
    csrw mscratch, t0      # Set ISR stack
    li sp, 0x07FFFFFC      # Set user stack
    # Setting user mode
    li t0, 0x1800
    csrc mstatus, t0       # Update the mstatus.MPP field (bits 11-12) with value 00 (U-mode)
    # Enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0       # Set mstatus.MIE (bit 3) as 1
    # Enabling external interrupts
    li t0, 0x800
    csrs mie, t0           # Set mie.MEIE (bit 11) as 1
    # Loading user software
    la t0, main 
    csrw mepc, t0          # Loads the user software entry point into mepc
    mret                   # PC <= MEPC, mode <= MPP