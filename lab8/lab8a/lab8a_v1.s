.bss
buffer: .skip 262159 # 512 * 512 + 15 bytes
width: .skip 2  # halfword (max 512)
height: .skip 2 # halfword (max 512)

.data
max_val: .half 255

.text
.globl _start
input_file: .asciz "image.pgm"

# parameters: a0 - width, a1 - length (both between 0 and 512)
start_canvas:
    li a7, 2201
    ecall
    ret

# returns the file descriptor for the image on a0
open:
    li a1, 0             # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0             # mode
    li a7, 1024          # syscall open
    ecall
    ret

# parameters: a0 - buffer address
# returns the address in which the colors start in the buffer
set_width_height:
    addi a0, a0, 2 # skip "P5" from the header
    li t1, 0   # stop condition
    li a1, 0   # stores the number
    la a2, width
    j 1f
    store:
    sh a1, (a2) # stores width first then height
    li a1, 0 # reset a1
    la a2, height
    addi t1, t1, 1
    1:
        li t0, 2 # stop condition for getting the numbers
        beq t1, t0, 1f
        addi a0, a0, 1
        lbu t2, (a0) # t2 is the digit at the position of a0
        li t0, ' ' # stop condition for current number being computed
        beq t0, t2, store
        li t0, '\n'
        beq t0, t2, store
        # multiply number by 10 and add digit
        li t0, 10
        mul a1, a1, t0
        addi t2, t2, -'0'
        add a1, a1, t2
        j 1b
    1:
    li t0, '\n'
    # stops when the digit stored at a0 is '\n'
    1:
        addi a0, a0, 1
        lbu t2, (a0)
        beq t2, t0, 1f
        j 1b
    1:
    addi a0, a0, 1
    ret

# parameters: a0 - file descriptor, a1 - buffer address, a2 - how many bytes will be read
read_pgm:
    li a7, 63         # syscall read
    ecall
    ret

write:
    li a0, 1 # 1 = stdout fd
    li a2, 30 # size
    li a7, 64 # syscall write
    ecall
    ret

# parameters: a0 - address of the buffer
show_image:
    mv a3, a0 # a3 is the address of the number being shown
    li a0, 0 # x coordinate
    lhu t0, height
    lhu t1, width
    li a7, 2200
    loop_row:
        beq a0, t1, end_row
        li a1, 0 # y coordinate
        loop_col:
            beq a1, t0, end_col
            lbu t2, (a3) # t2 is the current color
            #addi t2, t2, -'0'
            li a2, 255 # a2 is the concatenated pixel's colors, always ends with alpha = 255
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            ecall
            addi a3, a3, 1 # next number
            addi a1, a1, 1
            j loop_col
        end_col:
        addi a0, a0, 1
        j loop_row
    end_row:
    ret

    # li a0, 0
    # li a1, 0
    # li a7, 2200
    # la t0, buffer
    # 1:
    #
    # 1:
    # li a0, 100 # x coordinate = 100
    # li a1, 200 # y coordinate = 200
    # li a2, 0xAAAAAAFF # pixel color
    # li a7, 2200 # syscall setPixel (2200)
    # 1:
    #     li t0, 300
    #     beq a1, t0, 1f
    #     addi a1, a1, 1
    #     ecall
    #     j 1b
    # 1:
    # ret

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    la a0, input_file
    jal open

    mv s0, a0 # save file descriptor to s0
    la a1, buffer
    li a2, 15 # max header size
    jal read_pgm

    la a0, buffer
    jal set_width_height
    mv s1, a0 # save colors start address to s1

    lhu t0, width
    lhu t1, height
    mv a0, s0 # file descriptor
    la a1, buffer # buffer start
    mul a2, t0, t1 # a2 = width * height (number of bytes containing color)
    addi a2, a2, 13
    jal read_pgm

    mv a0, s1
    jal show_image

    jal exit