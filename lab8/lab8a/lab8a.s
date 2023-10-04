.bss
buffer: .skip 262159 # 15 (header) + 512*512 (color matrix) bytes
width: .skip 2  # halfword (max 512)
height: .skip 2 # halfword (max 512)

.text
.globl _start
input_file: .asciz "image.pgm"

# parameters: a0 - width, a1 - length (both between 0 and 512)
start_canvas:
    li a7, 2201    # syscall setCanvasSize
    ecall
    ret

# returns the file descriptor for the image on a0
open:
    li a1, 0             # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0             # mode
    li a7, 1024          # syscall open
    ecall
    ret

# paramaters: a0 - ascii number's address,
#             a1 - address where the number will be stored
# returns address where the conversion stopped
unsigned_atoi:
    li t1, 10          # base 10
    li a2, 0           # holds number being computed
    li t3, '9'         # 1st stop condition
    li t0, '0'         # 2nd stop condition
    1:
        lbu t2, (a0)         # get current digit
        bgt t2, t3, 1f       # if digit > '9' then end loop
        blt t2, t0, 1f       # if digit < '0' then end loop
        addi t2, t2, -'0'    # convert digit
        mul a2, a2, t1       # multiply number by 10
        add a2, a2, t2       # add digit
        addi a0, a0, 1
        j 1b
    1:
    sw a2, (a1)              # store the number
    ret

# parameters: a0 - buffer address
# returns the address in which the color pixels start in the buffer
extract_header_info:
    # storing ra and s1
    addi sp, sp, -4
    sw ra, (sp)
    addi sp, sp, -4
    sw s1, (sp)
    # getting width and height
    mv s1, a0
    addi a0, a0, 3    # width starts on 4th byte
    la a1, width
    jal unsigned_atoi
    addi a0, a0, 1    # a0 points to the start of the height
    la a1, height
    jal unsigned_atoi
    addi a0, a0, 5    # a0 points to the start of the color pixels (assuming max_val = 255)
    # restoring ra and s1
    lw s1, (sp)
    addi sp, sp, 4
    lw ra, (sp)
    addi sp, sp, 4
    ret

# parameters: a0 - file descriptor, a1 - buffer where info will be stored
read_pgm:
    li a2, 262159    # size
    li a7, 63        # syscall read
    ecall
    ret

# parameters: a0 - address of the buffer, a1 - width, a2 - height
show_image:
    mv a3, a0      # a3 is the address of the number being shown
    mv t0, a1
    mv t1, a2
    li a1, 0       # y coordinate
    li a7, 2200    # syscall setPixel
    # loops for each row
    1:
        bgeu a1, t1, 1f
        li a0, 0    # x coordinate
        # loops for each column
        2:
            bgeu a0, t0, 2f
            lbu t2, (a3)      # t2 is the current color
            li a2, 255        # a2 is the concatenated pixel's colors, always ends with alpha = 255
            # setting RGB using t2 by sliding it left 3 times and concatenating each time
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            ecall             # show pixel
            addi a3, a3, 1    # next number
            addi a0, a0, 1    # next column
            j 2b
        2:
        addi a1, a1, 1    # next row
        j 1b
    1:
    ret

exit:
    li a0, 0
    li a7, 93    # syscall exit
    ecall

_start:
    # load the buffer
    la a0, input_file
    jal open                   # a0 is now the file descriptor for the image
    la a1, buffer
    jal read_pgm
    # extract info from the header
    la a0, buffer
    jal extract_header_info    # a0 now points to the start of the pixel colors
    mv s0, a0
    # initalize canvas
    lhu a0, width
    lhu a1, height
    jal start_canvas
    # paint the image
    mv a0, s0
    lhu a1, width
    lhu a2, height
    jal show_image
    jal exit