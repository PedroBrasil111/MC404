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

.text
.set GPS_REG_PORT, 0xFFFF0100
.set X_AXIS_DATA_PORT, 0xFFFF0110
.set Y_AXIS_DATA_PORT, 0xFFFF0114
.set Z_AXIS_DATA_PORT, 0xFFFF0118
.set STEERING_WHEEL_REG_PORT, 0xFFFF0120
.set ENGINE_DIR_REG_PORT, 0xFFFF0121
.set HAND_BR_REG_PORT, 0xFFFF0122
.align 4

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

# Parameters: a0 - 1 (enabled), 0 (disabled)
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Parameters: a0, a1, a2 - address of the variable that will store the value of x, y, z position, respectively
syscall_get_position:
    # triggering gps read
    li t0, GPS_REG_PORT
    li t1, 1
    sb t1, (t0) # trigger gps
1: # loops until reading is completed
    lbu t1, (t0)
    beqz t1, 1f
    j 1b
1:
    # storing values
    li t0, X_AXIS_DATA_PORT
    lw t1, 0(t0) # t1 <= x
    sw t1, (a0)  # storing x
    lw t1, 4(t0) # t2 <= y
    sw t1, (a1)  # storing y
    lw t1, 8(t0) # t2 <= z
    sw t1, (a2)  # storing z
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

int_handler:
    ###### Syscall and Interrupts handler ######
    # storing registers
    csrrw sp, mscratch, sp  # switches sp and mscratch
    addi sp, sp, -32
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw a0, 8(sp)
    sw a1, 12(sp)
    sw a2, 16(sp)
    # handling interrupt
    li t0, 10
    beq a7, t0, engine_and_steering_int
    li t0, 11
    beq a7, t0, handbrake_int
    li t0, 15
    beq a7, t0, position_int
engine_and_steering_int:
    jal syscall_set_engine_and_steering
    j syscall_end
handbrake_int:
    jal syscall_set_handbrake
    j syscall_end
position_int:
    jal syscall_get_position
syscall_end:
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
    lw a0, 8(sp)
    lw a1, 12(sp)
    lw a2, 16(sp)
    addi sp, sp, 32
    csrrw sp, mscratch, sp  # switches sp and mscratch again
    mret                    # returns from interrupt

.globl _start
_start:
    # registering the ISR (Direct mode)
    la t0, int_handler     # loads the address of the routine that will handle interrupts
    csrw mtvec, t0         # (and syscalls) on the register MTVEC to set the interrupt array.
    # enabling external interrupts
    li t0, 0x800
    csrs mie, t0           # sets mie.MEIE (bit 11) as 1
    # enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0       # sets mstatus.MIE (bit 3) as 1
    # initializing stacks
    la t0, isr_stack_end
    csrw mscratch, t0      # sets ISR stack
    la sp, user_stack_end  # sets user stack
    # setting user mode
    li t0, 0x1800
    csrc mstatus, t0       # updates the mstatus.MPP field (bits 11-12) with value 00 (U-mode)
    # loading user software
    la t0, user_main 
    csrw mepc, t0          # loads the user software entry point into mepc
    mret                   # PC <= MEPC, mode <= MPP

.globl control_logic
control_logic:
    li a0, 1
    li a1, -15
    li a7, 10
    ecall