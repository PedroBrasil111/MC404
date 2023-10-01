.bss
buffer: .skip 262159 # 15 (header) + 512*512 (color matrix) bytes
.align 2
filtered_image: .skip 262144 # 512*512 bytes
.align 2
width: .skip 2 # halfword (max 512)
.align 2
height: .skip 2 # halfword (max 512)

.data
filter:
    .byte -1
    .byte -1
    .byte -1
    .byte -1
    .byte 8
    .byte -1
    .byte -1
    .byte -1
    .byte -1
input_file: .asciz "image.pgm"
oi_rs: .asciz "oi\n"

.text
.globl _start

write:
    mv s5, a0
    mv s6, a1
    mv s7, a2
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, oi_rs        # buffer
    li a2, 3            # size
    li a7, 64           # syscall write (64)
    ecall
    mv a0, s5
    mv a1, s6
    mv a2, s7
    ret

# parameters: a0 - width, a1 - length (both between 0 and 512)
start_canvas:
    li a7, 2201 # syscall setCanvasSize
    ecall
    ret

# returns the file descriptor for the image on a0
open:
    li a1, 0 # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0 # mode
    li a7, 1024 # syscall open
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

# posicao (i, j) para a lista
# (i,j) -> i*m + j (m: #colunas)

# posicao k da lista para a matriz
# i = k // m
# j = k % m

# bordas
# i = 0 e i = height - 1 -> j = [0, width - 1]
# 
# j = 0 e j = width - 1 -> i = [1, height - 2]

# r0 - row, r1 - column, r2 - width
# mul r0, r0, r2
# add r0, r0, r1

# parameters: a0 - original image's address, a1 - filtered image's address
#             a2 - width, a3 - height
apply_filter:
    addi t0, a2, 1 # 1st pixel that'll be "filtered" - position (1,1)
    1:

        mv t1, ra
        jal write
        mv ra, t1

        divu t1, t0, a2 # current row
        addi t2, a3, -1 # stop condition (last row)
        bgeu t1, t2, 1f

        li t2, 0 # pixel color after filter
        add t3, a0, t0 # address to current pixel
        lbu t4, (t3) # current pixel
        slli t4, t4, 3 # t4 *= 8
        add t2, t2, t4

        lbu t4, -1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        lbu t4, 1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        sub t3, t3, a2
        lbu t4, (t3)
        sub t4, x0, t4
        add t2, t2, t4

        lbu t4, -1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        lbu t4, 1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        add t3, t3, a2
        add t3, t3, a2
        lbu t4, (t3)
        sub t4, x0, t4
        add t2, t2, t4

        lbu t4, -1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        lbu t4, 1(t3)
        sub t4, x0, t4
        add t2, t2, t4

        bltz t2, negative
        li t3, 255
        bgt t2, t3, over_255
        j store_filtered
        negative:
        li t2, 0
        j store_filtered
        over_255:
        li t2, 255
        store_filtered:
        add t3, a1, t0
        sb t2, (t3)
        addi t0, t0, 1
        j 1b
    1:
    ret


# parameters: a0 - buffer address, a1 - width, a2 - height
add_borders:
    # adding borders to 1st and last row
    li t0, 0 # black pixel
    add t1, a2, -1 # last row
    mul t1, t1, a1 # t1 = last row * width
    li t2, 0 # t2 is the current column
    # loops for each column
    1:
        bgeu t2, a1, 1f # stop if column >= width
        add t3, a0, t2 # t3 = address to (0, column)
        sb t0, (t3) # store pixel in 1st row
        add t3, t3, t1 # t3 = address to (height - 1, column)
        sb t0, (t3) # store pixel in last row
        addi t2, t2, 1
        j 1b
    1:
    # adding borders to 1st and last column
    addi t1, a1, -1 # last column
    li t2, 1 # t2 is the current row
    mv t3, a0
    # loops for each row
    1:
        bgeu t2, a2, 1f # stop if row >= height
        add t3, t3, a1 # t3 is the address to the 1st item in the row
        sb t0, (t3)
        add t4, t3, t1 # t4 is the address to the last item in the row
        sb t0, (t4)
        addi t2, t2, 1
        j 1b
    1:
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
    addi a0, a0, 5 # a0 points to the start of the colors (assuming max_val = 255)
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
    li a7, 63 # syscall read
    ecall   
    ret

# parameters: a0 - address of the buffer, a1 - width, a2 - height
# TODO - possivel com so 1 loop (worth?)
show_image:
    mv a3, a0 # a3 is the address of the number being shown
    mv t0, a1
    mv t1, a2
    li a1, 0 # y coordinate
    li a7, 2200 # syscall setPixel
    # loops for each row
    1:
        bgeu a1, t1, 1f
        li a0, 0 # x coordinate
        # loops for each column
        2:
            bgeu a0, t0, 2f
            lbu t2, (a3) # t2 is the current color
            li a2, 255 # a2 is the concatenated pixel's colors, always ends with alpha = 255
            # setting RGB using t2 by sliding it left 3 times and concatenating each time
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            slli t2, t2, 8
            or a2, a2, t2
            ecall # show pixel
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
    # apply filter
    mv a0, s0
    la a1, filtered_image
    lhu a2, width
    lhu a3, height
    jal apply_filter
    # add borders
    la a0, filtered_image
    lhu a1, width
    lhu a2, height
    jal add_borders
    # initalize canvas
    lhu a0, width
    lhu a1, height
    jal start_canvas
    # paint the image
    la a0, filtered_image
    lhu a1, width
    lhu a2, height
    jal show_image
    jal exit