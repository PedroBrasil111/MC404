.bss
input_address: .skip 0x14  # buffer

.text
.globl _start
.set input_length, 20
read:
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_address #  buffer to write the data
    li a2, input_length # size
    li a7, 63 # syscall read (63)
    ecall
    ret

babylonian_estimative:
    li t1, 0 # sets t1 to 0
1:
    beq t1, 9, 1f # if t1 == 9 then done
    srli t0, a0, 2 # t0 = a0 / 4
    addi a0, t0, 1 # a0 = t0 + 1
    addi t1, t1, 1 # t1 = t1 + 1
    j 1b # repeat
1:
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, input_address       # buffer
    li a2, input_length           # size
    li a7, 64           # syscall write (64)
    ecall
    ret

extract_number:
    li t1, 0 # sets t1 to 0
    li a0, 0 # sets a0 to 0
1:
    beq t1, 3, 1f # if t1 == 3 then done
    lw a2, 0(input_address)
    addi a3, a2, -42
    
1:

_start:
    jal read
    
    jal babylonian_estimative

    jal write
    jal exit

exit:
    li a0, 0
    li a7, 93
    ecall