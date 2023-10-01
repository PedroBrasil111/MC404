.bss
buffer: .skip 262159 # 15 (header) + 512*512 (color matrix) bytes
width: .skip 2  # halfword (max 512)
height: .skip 2 # halfword (max 512)

.text
.globl _start
input_file: .asciz "image.pgm"

# parameters: a0 - width, a1 - length (both between 0 and 512)
start_canvas:
    li a7, 2201 # syscall setCanvasSize
    ecall
    ret

# returns the file descriptor for the image on a0
open:
    li a1, 0             # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0             # mode
    li a7, 1024          # syscall open
    ecall
    ret

# paramaters: a0 - address of the string, a1 - address where the number will be stored
# returns address where the conversion stopped
atoi:
    li t0, ' ' # stop condition
    li t3, '\n' # 2nd stop condition
    li t1, 10
    li a2, 0 # holds number being computed
    1:
        lbu t2, (a0) # get current digit
        beq t2, t0, 1f
        beq t2, t3, 1f
        addi t2, t2, -'0' # convert to number
        mul a2, a2, t1 # multiply by 10
        add a2, a2, t2 # add digit
        addi a0, a0, 1
        j 1b
    1:
    sh a2, (a1) # stores the number
    ret

# parameters: a0 - buffer address
# returns the address in which the colors start in the buffer
extract_header:
    # storing ra and s0
    addi sp, sp, -4
    sw ra, (sp)
    addi sp, sp, -4
    sw s0, (sp)
    # getting width and height
    mv s0, a0
    addi a0, a0, 3 # width starts on 4th byte
    la a1, width
    jal atoi
    addi a0, a0, 1 # a0 points to the start of the height
    la a1, height
    jal atoi
    addi a0, a0, 5 # a0 points to the start of the colors
    # restoring ra and s0
    lw s0, (sp)
    addi sp, sp, 4
    lw ra, (sp)
    addi sp, sp, 4
    ret

# parameters: a0 - file descriptor
read_pgm:
    la a1, buffer
    li a2, 262159
    li a7, 63         # syscall read
    ecall
    ret

# parameters: a0 - address of the buffer, a1 - width, a2 - height
show_image:
    mv a3, a0 # a3 is the address of the number being shown
    mv t0, a1
    mv t1, a2
    li a1, 0 # y coordinate
    li a7, 2200 # syscall setPixel
    # loops for each row
    1:
        beq a1, t1, 1f
        li a0, 0 # x coordinate
        # loops for each column
        2:
            beq a0, t0, 2f
            lbu t2, (a3) # t2 is the current color
            li a2, 255 # a2 is the concatenated pixel's colors, always ends with alpha = 255
            # setting RGB using t2 by sliding it left 3 times and concatenating
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            ecall
            addi a3, a3, 1 # next number
            addi a0, a0, 1 # next column
            j 2b
        2:
        addi a1, a1, 1 # next row
        j 1b
    1:
    ret

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    # load the buffer
    la a0, input_file
    jal open
    jal read_pgm
    # extract info from the header
    la a0, buffer
    jal extract_header
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