.bss
str_address: .skip 0x14  # buffer (20 bytes)
sqrts: .skip 0x10        # 4 words for storing the inputted numbers (16 bytes)

.text
.globl _start
.set str_len, 20

read:
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, str_address #  buffer to write the data
    li a2, str_len # size
    li a7, 63 # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, str_address       # buffer
    li a2, str_len           # size
    li a7, 64           # syscall write (64)
    ecall
    ret

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
