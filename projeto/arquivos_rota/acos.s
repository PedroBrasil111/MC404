.bss
.align 4
isr_stack:     # Base address of the ISR stack
.skip 4096
isr_stack_end: # Top address

.text
.align 2

# General Purpose Timer (GPT) - 0xFFFF0100 - 0xFFFF0300
.set GPT_CONTROL_REG_PORT,      0xFFFF0100 # unsigned byte
.set SYSTIME_DATA_REG_PORT,     0xFFFF0104 # unsigned word
# Self Driving Car - 0xFFFF0300 - 0xFFFF0500
.set GPS_CONTROL_REG_PORT,      0xFFFF0300 # unsigned byte
.set CAM_CONTROL_REG_PORT,      0xFFFF0301 # unsigned byte
.set SENSOR_CONTROL_REG_PORT,   0xFFFF0302 # unsigned byte
.set X_ANGLE_DATA_REG_PORT,     0xFFFF0304 # word
.set X_POSITION_DATA_REG_PORT,  0xFFFF0310 # word
.set SENSOR_DIST_DATA_REG_PORT, 0xFFFF031C # word
.set STEERING_WHEEL_REG_PORT,   0xFFFF0320 # byte
.set ENGINE_DIR_REG_PORT,       0xFFFF0321 # byte
.set HAND_BR_REG_PORT,          0xFFFF0322 # unsigned byte
.set CAMERA_IMG_DATA_PORT,      0xFFFF0324 # 256-unsigned byte array
# Serial Port - 0xFFFF0500 - 0xFFFF0700
.set WRITE_CONTROL_REG_PORT,    0xFFFF0500 # unsigned byte
.set WRITE_REG_PORT,            0xFFFF0501 # unsigned byte
.set READ_CONTROL_REG_PORT,     0xFFFF0502 # unsigned byte
.set READ_DATA_REG_PORT,        0xFFFF0503 # unsigned byte

# Triggers a device and waits until it finishes reading.
# Paramaters:
#     a0: Address of the device's control port.
# No return value.
trigger_device:
    li t0, 1
    sb t0, (a0) # Trigger the device
1:  # Loop until byte at control port is equal to 0
    lbu t0, (a0)
    bnez t0, 1b
    # Loop end, returning
    ret

# Syscall code: 10
# Starts the engine and steering wheel to move the car.
# Parameters:
#     a0: Movement direction.
#       * -1 to go backward, 0 to set the engine off, 1 to go forward.
#     a1: Steering wheel angle (value ranging from -127 to 127).
#       * Negative values turn the steering wheel to the left
#         and positive values to the right.
# Return value (a0):
#     0 if syscall was successful and -1 if it failed (invalid parameters).
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
    sb a1, (t0) # Store steering wheel value
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0) # Store engine value
    # Returning
    li a0, 0    # Syscall successful
    j return_result
invalid_val:
    li a0, -1   # Syscall failed
return_result:
    ret

# Syscall code: 11
# Sets the handbrake value.
# Parameters:
#     a0: Indicates if the handbrake must be used.
#       * a0 must be 1 to use the handbrake.
# No return value.
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0) # Store hand brake value
    ret

# Syscall code: 12
# Reads values from the luminosity sensor and stores them in the parameter address.
# Parameters:
#     a0: Address of an array with 256 elements that will store
#         the values read by the luminosity sensor.
# No return value.
syscall_read_sensors:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    mv s1, a0                   # Save array address
    # Triggering line camera reading
    li a0, CAM_CONTROL_REG_PORT
    jal trigger_device          # Triggers camera to read the image
    li t1, CAMERA_IMG_DATA_PORT # t1 <= address where image is stored
    addi t0, t1, 256            # t0 <= end address (stop condition)
1:  # Loop copying each byte to the parameter address
    lbu t2, (t1)                # Load current byte
    sb t2, (s1)                 # Store in array
    addi t1, t1, 1              # Next byte (image)
    addi s1, s1, 1              # Next byte (array)
    bltu t1, t0, 1b             # Loop if end address hasn't been reached
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# Syscall code: 13
# Returns the value of the smallest distance to an object read by the ultrasonic sensor.
# No parameters.
# Return value (a0):
#     Value obtained from the sensor reading (-1 in case no object has been detected
#     in less than 20 meters).
syscall_read_sensor_distance:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    # Triggering sensor reading
    li a0, SENSOR_CONTROL_REG_PORT
    jal trigger_device               # Triggers ultrassonic sensor to read the distance
    li t0, SENSOR_DIST_DATA_REG_PORT # t0 <= address where distance is stored
    lw a0, (t0)                      # a0 <= distance (in cm)
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# Syscall code: 15
# Reads the car's approximate position using the GPS device and stores it at the specified addresses.
# Parameters:
#     a0, a1, a2: Addresses for variables storing the x, y and z positions, respectively.
# No return value.
syscall_get_position:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Saving parameter addresses
    mv s1, a0
    mv s2, a1
    mv s3, a2
    # Triggering GPS reading
    li a0, GPS_CONTROL_REG_PORT
    jal trigger_device    # Triggers the GPS to read the position
    # Storing values
    li t0, X_POSITION_DATA_REG_PORT
    lw t1, 0(t0)          # t1 <= x position
    sw t1, (s1)           # Store x position
    lw t1, 4(t0)          # t2 <= y position
    sw t1, (s2)           # Store y position
    lw t1, 8(t0)          # t2 <= z position
    sw t1, (s3)           # Store z position
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Syscall code: 16
# Reads the car's global rotation using the GPS device and stores it at the specified addresses.
# Parameters:
#     a0, a1, a2: Addresses for variables storing the x, y and z Euler angles, respectively.
# No return value.
syscall_get_rotation:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Saving parameter addresses
    mv s1, a0
    mv s2, a1
    mv s3, a2
    # Triggering GPS reading
    li a0, GPS_CONTROL_REG_PORT
    jal trigger_device    # Triggers the GPS to read the rotation
    # Storing values
    li t0, X_ANGLE_DATA_REG_PORT
    lw t1, 0(t0)          # t1 <= x position
    sw t1, (s1)           # Store x position
    lw t1, 4(t0)          # t2 <= y position
    sw t1, (s2)           # Store y position
    lw t1, 8(t0)          # t2 <= z position
    sw t1, (s3)           # Store z position
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Syscall code: 17
# Reads a specified number of bytes from the Serial Port.
# If this number exceeds the total buffered bytes on the device,
# the reading will be interrupted.
# Parameters:
#     a0: Address of the buffer where the byte string will be stored.
#     a1: Number of bytes to read.
# Return value (a0):
#     Number of bytes read.
syscall_read_serial:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Reading string
    mv s1, a0                 # s1 <= buffer
    mv s2, a1                 # s2 <= size
    li s3, 0                  # s3 counts the number of characters read
1:  # Loop reading and copying each character to the buffer
    bgeu s3, s2, 1f           # If s3 >= size, then end loop
    li a0, READ_CONTROL_REG_PORT
    jal trigger_device        # Triggers the Serial Port to read one byte
    li t0, READ_DATA_REG_PORT # Address where byte read is stored
    lbu t1, (t0)              # t1 <= current byte
    beqz t1, 1f               # If byte is null, then end loop
    add t0, s1, s3            # t0 <= address where byte will be stored
    sb t1, (t0)               # Store byte
    addi s3, s3, 1            # Increment counter
    j 1b                      # Loop
1:
    mv a0, s3                 # a0 <= number of characters read
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Syscall code: 18
# Writes a specified number of bytes from the Serial Port.
# Parameters:
#     a0: Address of the buffer where the byte string that will be written is stored.
#     a1: Number of bytes to write.
# No return value.
syscall_write_serial:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    # Writing string
    mv s1, a0             # s1 <= buffer
    add s2, s1, a1        # s2 <= stop condition (end address = buffer address + size)
    li s3, WRITE_REG_PORT # The Serial Port writes the byte stored in this address
1:  # Loop writing each character to the Serial Port
    bgeu s1, s2, 1f       # If current address >= end address, then end loop
    lbu t0, (s1)          # Load character
    sb t0, (s3)           # Store character on reg port
    li a0, WRITE_CONTROL_REG_PORT
    jal trigger_device    # Triggers the Serial port to write the character
    addi s1, s1, 1        # Update address
    j 1b                  # Loop
1:
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16
    ret

# Syscall code: 20
# Returns the time since the system has been booted, in miliseconds.
# No parameters.
# Return value (a0):
#     Current system time.
syscall_get_systime:
    # Storing ra
    addi sp, sp, -16
    sw ra, (sp)
    # Triggering the GPT to read the system time
    li a0, GPT_CONTROL_REG_PORT
    jal trigger_device
    # Loading system time
    li a0, SYSTIME_DATA_REG_PORT # Address where system time is stored
    lw a0, (a0)                  # a0 <= system time
    # Restoring ra and returning
    lw ra, (sp)
    addi sp, sp, 16
    ret

# Syscall and Interrupts handler.
# Uses Direct Mode for syscalls (checks for each possible value
# stored on a7 to jump to the specific syscall's ISR)
int_handler:
    # Storing context
    csrrw sp, mscratch, sp  # Switch sp and mscratch
    addi sp, sp, -64
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw a0, 12(sp)
    sw a1, 16(sp)
    sw a2, 20(sp)
    sw s1, 24(sp)
    sw s2, 28(sp)
    sw s3, 32(sp)
    sw ra, 36(sp)
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
    lw a0, 12(sp)           # Since there's no return, a0 is restored
syscall_ret_end:            # Label for syscalls that return something
    # Setting user mode
    li t0, 0x1800           # Update the mstatus.MPP field (bits 11 and 12) with value 00 (U-mode)
    csrc mstatus, t0
    # Setting return address
    csrr t0, mepc           # Load return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4          # Add 4 to the return address (to return after ecall)
    csrw mepc, t0           # Store the return address back on mepc
    # Recovering context and returning
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw a1, 16(sp)
    lw a2, 20(sp)
    lw s1, 24(sp)
    lw s2, 28(sp)
    lw s3, 32(sp)
    lw ra, 36(sp)
    addi sp, sp, 64
    csrrw sp, mscratch, sp  # Switch sp and mscratch again
    mret                    # Return from interrupt

.globl _start
_start:
    # Registering the ISR (Direct mode)
    la t0, int_handler     # Load the address of the routine that will handle interrupts
    csrw mtvec, t0         # (and syscalls) on the register MTVEC to set the interrupt array.
    # Initializing stacks
    la t0, isr_stack_end   # Load the top address of the ISR stack
    csrw mscratch, t0      # Set ISR stack pointer
    li sp, 0x07FFFFFC      # Set user stack pointer
    # Setting user mode
    li t0, 0x1800
    csrc mstatus, t0       # Update the mstatus.MPP field (bits 11-12) with value 00 (U-mode)
    # Enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0       # Set mstatus.MIE (bit 3) to enable global interrupts
    # Enabling external interrupts
    li t0, 0x800
    csrs mie, t0           # Set mie.MEIE (bit 11) to enable external interrupts
    # Loading user software
    la t0, main
    csrw mepc, t0          # Load the user software entry point into mepc
    mret                   # PC <= MEPC, mode <= MPP