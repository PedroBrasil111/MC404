.bss
x_coord: .skip 4
y_coord: .skip 4
z_coord: .skip 4

.text
.set GPS_CONTROL_REG_PORT, 0xFFFF0100     # unsigned byte
.set X_POSITION_DATA_REG_PORT, 0xFFFF0110 # word
.set STEERING_WHEEL_REG_PORT, 0xFFFF0120  # byte
.set ENGINE_DIR_REG_PORT, 0xFFFF0121      # byte
.set HAND_BR_REG_PORT, 0xFFFF0122         # unsigned byte

# Triggers and waits for a reading by the GPS
trigger_gps:
    li t0, GPS_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0) # Trigger gps
1:  # Loops until reading is completed
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end - return
    ret

# Stores the coordinates of the car from the last reading by the
# GPS on x_coord, y_coord and z_coord
get_coordinates:
    li t0, X_POSITION_DATA_REG_PORT
    lw t1, 0(t0) # x
    sw t1, x_coord, t2
    lw t1, 4(t0) # y
    sw t1, y_coord, t2
    lw t1, 8(t0) # z
    sw t1, z_coord, t2
    ret

# Sets the parameter value as the engine direction
# Parameters: a0 - 1 (fwd), 0 (off), -1 (bwd)
set_engine_direction:
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0) # Set engine direction
    ret

# Sets the parameter value as the steering wheel direction
# Parameters: a0 - ranging from -127 to 127
set_steering_wheel_direction:
    li t0, STEERING_WHEEL_REG_PORT
    sb a0, (t0) # Set steering wheel direction
    ret

# Sets the parameter value as the hand break state
# Parameters: a0 - 1 (enabled), 0 (disabled)
set_hand_break:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0) # Set hand brake state
    ret

# Checks the distance in the xz plane between the car and the test track and
# returns a value indicating if the distance is smaller than 15 meters
# Return value: a0 - 1 if the car is within 15 meters, 0 otherwise
check_distance:
    lw t0, x_coord
    li t1, 73      # Test track x position
    sub t0, t0, t1 # t0 <= distance in x axis (not moduled)
    mul t0, t0, t0 # Distance in x axis squared
    lw t1, z_coord
    li t2, -19     # Test track z position
    sub t1, t1, t2 # t1 <= distance in z axis (not moduled)
    mul t1, t1, t1 # Distance in z axis squared
    add t0, t0, t1 # t0 <= distance squared
    li t1, 225     # t1 <= 225 (15 squared)
    slt a0, t0, t1 # a0 indicates if the car is within a radius of 15 m of the track
    ret

# Terminate calling process
# Parameters: a0 - Status code
exit:
    li a7, 93    # Syscall exit (93)
    ecall
    ret

.globl _start
_start:
    li a0, 1
    jal set_engine_direction # Starts the engine going forward
    li a0, -15
    jal set_steering_wheel_direction
1:  # Loops until car is within 15 meters of the test track
    jal trigger_gps
    jal get_coordinates
    jal check_distance
    beqz a0, 1b
    # Loop end
    li a0, 0
    jal exit