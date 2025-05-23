.bss
buffer: .skip 262159 # 13 (header) + 512*512 (color matrix) bytes
filtered_image: .skip 262146 # 512*512 bytes
width: .skip 2 # halfword (max 512)
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
debug: .asciz "oi"

.text
.globl _start

write:
    mv s5, a0
    mv s6, a1
    mv s7, a2
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, debug        # buffer
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

# parameters: a0 - row, a1 - column, a2 - width
find_matrix_position:
    mul a0, a0, a2
    add a0, a0, a1
    ret

# parameters: a0 - original image's address, a1 - filtered image's address
#             a2 - width, a3 - height
apply_filter:
    # storing info
    addi sp, sp, -4
    sw ra, (sp)
    addi sp, sp, -4
    sw s0, (sp)
    addi sp, sp, -4
    sw s1, (sp)
    # 
    mv s0, a0
    mv s1, a1
    li t0, 1 # column
    # loops for each row
    1:
        addi t3, a2, -1
        bgeu t0, t3, 1f # stop if column >= width - 1
        li t1, 1 # row
        2:
            addi t3, a3, -1
            bgeu t1, t3, 2f # stop if row >= height - 1
            mv a0, t1 # row
            mv a1, t0 # column
            li t2, -1
            li s2, 0
            3:
                li t3, 1
                bgeu t2, t3, 3f
                li t4, -1
                4:
                    li t3, 1
                    bgeu t4, t3, 4f
                    add a0, t1, t4
                    add a1, t0, t3
                    jal find_matrix_position
                    add a0, s0, a0
                    lw a0, (a0)
                    add a0, x0, a0
                    add s2, s2, a0
                    addi t4, t4, 1
                    j 4b
                4:
                addi t2, t2, 1
                j 3b
            3:
            jal write
            mv a0, t1
            mv a1, t0
            jal find_matrix_position
            add t3, a0, s0
            lw a1, (t3)
            li t3, 9
            mul a1, a1, t3
            add s2, s2, a1
            add a0, s1, a0
            sw s2, (a0)
            addi t1, t1, 1
            j 2b
        2:
        addi t0, t0, 1
        j 1b
    1:
    # restoring info
    sw s1, (sp)
    addi sp, sp, 4
    sw s0, (sp)
    addi sp, sp, 4
    sw ra, (sp)
    addi sp, sp, 4
    ret

# parameters: a0 - buffer address, a1 - width, a2 - height
# TODO - deixar + compacto
add_borders:
    # adding borders to 1st and last row
    li t1, 0 # t1 indicates the row where the border is being added
    li t5, 0 # black pixel
    j 1f
    last_row:
    addi t1, a2, -1
    # loops for 1st and last row
    1:
        mv t3, a1 # t3 = width
        mul t3, t3, t1 # t3 = row * width
        add t3, t3, a0 # t3 is the address to the first element in the row
        add t4, t3, a1 # t4 is the address to the last element in the row
        2:
            sb t5, (t3)
            add t3, t3, 1
            bgeu t3, t4, 2f # if column >= width end loop
            j 2b
        2:
        bgtz t1, 1f
        j last_row
    1:
    # adding borders to 1st and last column
    mul t4, a1, a2 # t4 = width * height
    add t4, t4, a0 # last element of the matrix
    li t1, 0 # t1 indicates the column where the border is being added
    j 1f
    last_col:
    addi t1, a1, -1
    1:
        mv t3, a0 
        add t3, t3, t1 # address where the byte will be stored
        2:
            sb t5, (t3)
            add t3, t3, a1 # add width (next row)
            bgeu t3, t4, 2f # if t3 surpassed the limit, end loop
            j 2b
        2:
        bgtz t1, 1f
        j last_col
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
    li a7, 63 # syscall read
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
        bge t1, a1, 1f
        li a0, 0 # x coordinate
        # loops for each column
        2:
            bge t0, a0, 2f
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
    # add borders
    la a0, filtered_image
    lhu a1, width
    lhu a2, height
    jal add_borders
    # apply filter
    mv a0, s0
    la a1, filtered_image
    lhu a2, width
    lhu a3, height
    jal apply_filter
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