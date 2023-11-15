.bss
buffer: .skip 100
x_coord: .skip 4
y_coord: .skip 4
z_coord: .skip 4

.text
.globl _start

.set GPS_REG_PORT, 0xFFFF0100
.set X_AXIS_DATA_PORT, 0xFFFF0110
.set Y_AXIS_DATA_PORT, 0xFFFF0114
.set Z_AXIS_DATA_PORT, 0xFFFF0118
.set STEERING_WHEEL_REG_PORT, 0xFFFF0120
.set ENGINE_DIR_REG_PORT, 0xFFFF0121
.set HAND_BR_REG_PORT, 0xFFFF0122

trigger_gps:
    li t0, GPS_REG_PORT
    li t1, 1
    sb t1, (t0) # trigger gps
1:  # loops until reading is completed
    lbu t1, (t0)
    bnez t1, 1b
    # loop end - return
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

# Parameters: a0 - 1 (fwd), 0 (off), -1 (bwd)
set_engine_direction:
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0 - ranging from -127 to 127
set_steering_wheel_direction:
    li t0, STEERING_WHEEL_REG_PORT
    sb a0, (t0) # set steering wheel direction
    ret

# Parameters: a0 - 1 (enabled), 0 (disabled)
set_hand_break:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

check_distance:
    lw t0, x_coord
    li t1, 73 # test track x
    sub t0, t0, t1 # t0 <= distance in x axis (not moduled)
    mul t0, t0, t0 # distance in x axis squared
    lw t1, z_coord
    li t2, -19 # test track z
    sub t1, t1, t2 # t1 <= distance in z axis (not moduled)
    mul t1, t1, t1 # distance in z axis squared
    add t0, t0, t1 # t0 <= distance squared
    li t1, 225 # t1 <= 225 (15 squared)
    slt a0, t0, t1 # a0 indicates if the car is within a radius of 15 m of the track
    ret

_start:
    li a0, 1
    jal set_engine_direction # starts the engine to go forward
    li a0, -15
    jal set_steering_wheel_direction
    1:
        jal trigger_gps
        jal get_coordinates
        jal check_distance
        bnez a0, stop
        j 1b
    1:
    stop:
    li a0, 0
    jal exit

# Terminate calling process
# Parameters: a0 - status code
# No return value
exit:
    li a7, 93    # syscall exit (93)
    ecall
    ret