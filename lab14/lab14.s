.bss
.align 4
user_stack:             # User stack's top address (1024 bytes)
.skip 1024
user_stack_end:         # User stack's base address
.align 4
isr_stack:              # ISR stack's top address (1024 bytes)
.skip 1024
isr_stack_end:

.text
.set GPS_CONTROL_REG_PORT, 0xFFFF0100
.set X_POSITION_DATA_REG_PORT, 0xFFFF0110
.set STEERING_WHEEL_REG_PORT, 0xFFFF0120
.set ENGINE_DIR_REG_PORT, 0xFFFF0121
.set HAND_BR_REG_PORT, 0xFFFF0122

# Sets the parameter value as the steering wheel direction
# Parameters: a0 - ranging from -127 to 127
set_steering_wheel_angle:
    li t0, STEERING_WHEEL_REG_PORT
    sb a0, (t0) # Set steering wheel direction
    ret

# Sets the parameter value as the engine direction
# Parameters: a0 - engine direction: 1 (fwd), 0 (off), -1 (bwd)
set_engine_direction:
    li t0, ENGINE_DIR_REG_PORT
    sb a0, (t0) # Set engine direction
    ret

# Sets the parameter value as the hand break state
# Syscall code: 11
# Parameters: a0 - 1 (enabled), 0 (disabled)
syscall_set_handbrake:
    li t0, HAND_BR_REG_PORT
    sb a0, (t0)
    ret

# Loads the current position (x, y, z) onto the parameter addresses
# Syscall code: 15
# Parameters: a0, a1, a2 - Address of the variable that will store the value of x, y, z position, respectively
syscall_get_position:
    # Triggering gps read
    li t0, GPS_CONTROL_REG_PORT
    li t1, 1
    sb t1, (t0) # Trigger gps
1:  # Loops until reading is completed
    lbu t1, (t0)
    bnez t1, 1b
    # Loop end, Storing values
    li t0, X_POSITION_DATA_REG_PORT
    lw t1, 0(t0) # t1 <= x
    sw t1, (a0)  # Storing x
    lw t1, 4(t0) # t2 <= y
    sw t1, (a1)  # Storing y
    lw t1, 8(t0) # t2 <= z
    sw t1, (a2)  # Storing z
    ret

# Start the engine to move the car. a0's value can be -1 (go backward),
# 0 (off) or 1 (go forward). a1's value can range from -127 to
# +127, where negative values turn the steering wheel to the left and positive
# values to the right
# Syscall code: 10
# Parameters: a0 - Movement direction (-1, 0 or 1)
#             a1 - Steering wheel angle (between -127 and 127 inclusive)
syscall_set_engine_and_steering:
    # Storing ra
    addi sp, sp, -16
    sw ra, (sp)
    # Treating invalid cases
    li t0, 1
    bgt a0, t0, invalid_val
    li t0, -1
    blt a0, t0, invalid_val
    li t0, 127
    bgt a1, t0, invalid_val
    li t0, -127
    blt a1, t0, invalid_val
    # Setting values
    jal set_engine_direction
    mv a0, a1
    jal set_steering_wheel_angle
    # Returning from label
    li a0, 0  # Syscall successful
    j return_result
invalid_val:
    li a0, -1 # Syscall failed
return_result:
    # Loading ra
    lw ra, (sp)
    addi sp, sp, 16
    ret

# Syscall and Interrupts handler. Decides which specific ISR to call
# based on the value on the register a7
int_handler:
    # Storing registers
    csrrw sp, mscratch, sp  # Switches sp and mscratch
    addi sp, sp, -32
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw a0, 8(sp)
    sw a1, 12(sp)
    sw a2, 16(sp)
    # Determining which ISR to call
    li t0, 10
    beq a7, t0, engine_and_steering_int
    li t0, 11
    beq a7, t0, handbrake_int
    li t0, 15
    beq a7, t0, position_int
engine_and_steering_int:
    jal syscall_set_engine_and_steering
    j syscall_ret_end
handbrake_int:
    jal syscall_set_handbrake
    j syscall_end
position_int:
    jal syscall_get_position
syscall_end:                # Label for syscalls that don't have return values
    lw a0, 8(sp)            # Since there's no return, a0 is restored
syscall_ret_end:            # Label for syscalls that return something
    # Setting user mode
    li t0, 0x1800           # Updates the mstatus.MPP field (bits 11 and 12) with value 00 (U-mode)
    csrc mstatus, t0
    # Setting return address
    csrr t0, mepc           # Loads return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4          # Adds 4 to the return address (to return after ecall)
    csrw mepc, t0           # Stores the return address back on mepc
    # restoring registers
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw a1, 12(sp)
    lw a2, 16(sp)
    addi sp, sp, 32
    csrrw sp, mscratch, sp  # Switches sp and mscratch again
    mret                    # Returns from interrupt

.globl _start
_start:
    # Registering the ISR (Direct mode)
    la t0, int_handler     # Loads the address of the routine that will handle interrupts
    csrw mtvec, t0         # (and syscalls) on the register MTVEC to set the interrupt array.
    # Initializing stacks
    la t0, isr_stack_end
    csrw mscratch, t0      # Sets ISR stack
    la sp, user_stack_end  # Sets user stack
    # Enabling external interrupts
    li t0, 0x800
    csrs mie, t0           # Sets mie.MEIE (bit 11) as 1
    # Setting user mode
    li t0, 0x1800
    csrc mstatus, t0       # Updates the mstatus.MPP field (bits 11-12) with value 00 (U-mode)
    # Enabling global interrupts
    li t0, 0x8
    csrs mstatus, t0       # Sets mstatus.MIE (bit 3) as 1
    # loading user software
    la t0, user_main
    csrw mepc, t0          # Loads the user software entry point into mepc
    mret                   # PC <= MEPC, mode <= MPP

.globl control_logic
control_logic:
    li a0, 1
    li a1, -15
    li a7, 10              # Code for set engine and steering wheel syscall
    ecall