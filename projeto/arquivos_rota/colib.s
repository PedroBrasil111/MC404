.rodata
.align 2
ln_br: .asciz "\n" # line break

.text
.align 2
/******************************************************************************/
/*  Car Peripheral                                                            */
/******************************************************************************/

# Defines values to vertical and horizontal movement of the car.
# Parameters:
#     a0 (vertical): A byte that defines the vertical movement of the car, between -1 and 1.
#                    -1 makes the car go backwards and 1 forward. (Engine)
#     a1 (horizontal): Defines the vertical movement of the car, between -127 and 127.
#                      Negative values make the car go to the left and positive to the right.
#                      (Steering Wheel)
# Return value (a0):
#     0 in case of a success.
#     -1 if any of the parameters are out of bounds.
# C signature: int set_engine(int vertical, int horizontal)
.globl set_engine
set_engine:
    li a7, 10 # Syscall set engine and steering
    ecall     # a0 <= 0 in case of success, -1 if a parameter is out of bounds
    ret

# Sets the handbrake of the car.
# Parameters:
#     a0 (value): A byte that defines if the brake will be triggered or not.
#                 1 to trigger the brake e 0 to stop using it.
# Return value (a0):
#     0 in case of success.
#     -1 if the value parameter is invalid.
# C signature: int set_handbrake(char value)
.globl set_handbrake
set_handbrake:
    andi t0, a0, ~0x1 # t0 is a0 with the last byte cleared (if a0 is 0 or 1, then t0 is 0)
    bnez t0, fail_handbrake
    li a7, 11         # Syscall set handbrake
    ecall             # has no return value
    li a0, 0          # Operation success
    j ret_handbrake
fail_handbrake:
    li a0, -1         # Operation failed
ret_handbrake:
    ret

# Reads distance from the ultrasonic sensor.
# No paramaters.
# Return value (a0):
#     the distance detected by the sensor, in cetimeters, if an object is detected.
#     -1, if no object is detected.
# C signature: int read_sensor_distance()
.globl read_sensor_distance
read_sensor_distance:
    li a7, 13 # Syscall read sensor distance
    ecall     # a0 <= distance detected in cm, or -1 if there are no objects within 20m
    ret

# Reads the approximate position of the car using a GPS device.
# Parameters:
#     x: address of the variable that will store the value of the x position.
#     y: address of the variable that will store the value of the y position.
#     z: address of the variable that will store the value of the z position.
# No return value.
# C signature: void get_position(int* x, int* y, int* z)
.globl get_position
get_position:
    li a7, 15 # Syscall get position
    ecall     # has no return value
    ret

# Reads the global rotation of the gyroscope device.
# Parameters:
#     x: address of the variable that will store the value of the Euler angle in x.
#     y: address of the variable that will store the value of the Euler angle in y.
#     z: address of the variable that will store the value of the Euler angle in z.
# No return value.
# C signature: void get_rotation(int* x, int* y, int* z)
.globl get_rotation
get_rotation:
    li a7, 16 # Syscall get position
    ecall     # has no return value
    ret

/******************************************************************************/
/*  GPT Peripheral                                                            */
/******************************************************************************/

# Reads system time.
# No paramaters.
# Return value (a0):
#     System time, in milliseconds.
# C signature: unsigned int get_time()
.globl get_time
get_time:
    li a7, 20 # Syscall get systime
    ecall     # a0 <= time since sistem has been booted, in milliseconds
    ret

/******************************************************************************/
/*  Utility Functions                                                         */
/******************************************************************************/

# Writes the C string pointed by str to the Serial Port output
# and appends a newline character ('\n').
# Parameters:
#     a0 (str): string terminated in \0.
# No return value
# C signature: void puts ( const char *str )
.globl puts
puts:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    # Writing string
    mv s1, a0         # Save address
    jal strlen_custom # a0 <= string's length
    mv a1, a0         # a1 <= number of bytes to write (length)
    mv a0, s1         # a0 <= address of the buffer
    li a7, 18         # Syscall write serial
    ecall             # has no return value
    # Writing line break
    la a0, ln_br
    li a1, 1
    ecall             # Writes line break
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# Reads characters from the Serial Port input and stores them as a C string into str
# until a newline character is reached.
# Parameters:
#     a0 (str): Buffer to be filled.
# Return value (a0):
#     Filled buffer with a \0 terminated string.
# C signature: char *gets ( char *str )
.globl gets
gets:
    # Storing registers
    addi sp, sp, -16
    sw ra, (sp)
    sw s1, 4(sp)
    mv s1, a0         # Save address
    mv s2, a0         # s2 will be used to iterate over the string
1:  # Loop until reaching \n or \0
    li a1, 1          # a1 <= num of bytes to be read (1)
    mv a0, s2         # a0 <= address where byte will be stored
    li a7, 17         # Syscall read serial
    ecall             # Reads one byte from the Serial Port
    lbu t0, (s2)      # t0 <= byte read
    li t1, '\n'
    beq t0, t1, 1f    # If the byte is a line break or
    beqz t0, 1f       # a null character, then end loop
    addi s2, s2, 1    # Increment address
    j 1b              # Loop
1:
    # Storing null character at the end of the string
    li t0, 0
    sb t0, (s2)
    mv a0, s1         # a0 <= filled buffer
    # Restoring registers and returning
    lw ra, (sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# Parses the C-string str interpreting its content as an integral number,
# which is returned as a value of type int.
# Parameters:
#     a0 (str): \0 terminated string of the decimal representation of a number.
# Return value (a0):
#     The integer value represented by the string.
# C signature: int atoi (const char *str)
.globl atoi
atoi:
    li t1, 10            # t1 <= base (10)
    li a2, 0             # a2 will hold the number being computed
    li a3, 0             # a3 indicates whether number is negative (1) or positive (0)
    lbu t2, (a0)         # 1st digit
    li t0, '-'
    bne t2, t0, pos      # if 1st digit isn't '-' the number is positive (or zero)
    li a3, 1             # a3 <= 1, since number is negative
    addi a0, a0, 1       # Skip the minus sign
pos:
    li t3, '9'           # 1st stop condition
    li t0, '0'           # 2nd stop condition
1:  # Loop calculating the value from each digit
    lbu t2, (a0)         # Get current digit
    bgt t2, t3, 1f       # If digit > '9' then end loop
    blt t2, t0, 1f       # If digit < '0' then end loop
    addi t2, t2, -'0'    # Convert digit
    mul a2, a2, t1       # Multiply number by 10
    add a2, a2, t2       # Add digit
    addi a0, a0, 1       # Update address
    j 1b
1:
    li t0, 1
    bne a3, t0, ret_atoi # If a3 != 1, number is positive (just return)
    sub a2, x0, a2       # Invert the number (negative)
ret_atoi:
    mv a0, a2            # a0 <= number
    ret

# Converts an integer value to a null-terminated string using the specified base
# and stores the result in the array given by str parameter.
# Parameters:
#     a0 (value): Integer value to be converted.
#     a1 (str): Buffer to be filled with \0 terminated string of the
#               representation of the number.
#     a2 (base): Base to use, either 10 or 16.
# Return value (a0):
#     Filled butter with a \0 terminated string.
# C signature: char *itoa ( int value, char *str, int base )
.globl itoa
itoa:
    # Converting number to ascii and stacking its digits
    addi sp, sp, -1
    li t0, 0
    sb t0, (sp)              # Stack null character (last byte)
    li t2, 0                 # t2 indicates whether the number is negative (1) or positive (0)
    li t3, 1                 # t3 is the number's length in ascii digits (including \n)
    li t0, 10
    bne a2, t0, not_negative # If not base 10, treat the number as unsigned number
    bgez a0, not_negative    # Jump to not_negative if number is positive (or zero)
    li t2, 1                 # t2 <= 1, since number is negative
    sub a0, x0, a0           # a0 <= absolute value of the number
not_negative:
1:  # Loop calculating each digit
    remu t0, a0, a2          # t0 <= a0 % base (value of current digit)
    li t1, 10
    bge t0, t1, letter       # If t0 >= 10, then the digit is represented as a letter
    addi t0, t0, '0'         # Turn value (number between 0 and 9) into ascii character
    j stack_digit
letter:
    sub t0, t0, t1           # t0 <= value - 10
    li t1, 'A'
    add t0, t1, t0           # t0 <= letter that represents the value
stack_digit:
    addi sp, sp, -1          # Update sp
    sb t0, (sp)              # Stack digit
    addi t3, t3, 1           # Increment length
    divu a0, a0, a2          # a0 <= a0 / base
    bnez a0, 1b              # If a0 != 0, there are more digits to stack
    # Loop end, treating negative case
    beqz t2, cp_num          # If the number's not negative, jump to cp_num
    # Stacking minus sign
    addi sp, sp, -1
    li t0, '-'
    sb t0, (sp)              # Stack minus sign
    addi t3, t3, 1           # Increment length
cp_num:
    # Copying string to the parameter address by popping characters
    mv a0, a1                # a0 <= buffer address
    mv t0, t3                # t0 <= length (counter for next loop)
    mv t1, sp                # t1 <= address of current digit in the stack
1: # Loop for each byte
    beqz t0, 1f              # If counter == 0 then end loop
    lbu t2, (t1)             # Load byte from stack
    sb t2, (a1)              # Store on the buffer
    addi t0, t0, -1          # Update counter
    addi t1, t1, 1           # Update address
    addi a1, a1, 1           # Update address
    j 1b                     # Loop
1:
    # Popping digits from the stack and returning
    add sp, sp, t3
    ret

# Returns the length of the C string str.
# Parameters:
#     a0 (str): String terminated by \0.
# Return value (a0):
#     Size of the string without counting the \0.
# C signature: int strlen_custom( char *str )
.globl strlen_custom
strlen_custom:
    li t0, 0       # t0 will hold the string's length
1:  # Loop for each byte until reaching \0
    lbu t1, (a0)   # Load byte from string
    beqz t1, 1f    # If byte is null, then end loop
    addi t0, t0, 1 # Increment length
    addi a0, a0, 1 # a0 points to the next byte in the string
    j 1b           # Loop
1:
    mv a0, t0      # a0 is now the string's length
    ret

# Approximate Square Root computation using the Babylonian Method.
# Parameters:
#     a0 (value): Integer value.
#     a1 (iterations): Number of iterations to perform the Babylonian method.
# Returns:
#     Approximate square root of value.
# C signature: int approx_sqrt(int value, int iterations)
.globl approx_sqrt
approx_sqrt:
    # Initial guess: k = y/2
    # Next guess: k' = (k + y/k)/2
    li t0, 0       # Counter for iterations
    srli t1, a0, 1 # t1 is the initial guess k = y/2
1:  # Loop the same number of times as iterations (a1)
    bge t0, a1, 1f # If counter >= iterations then end loop
    addi t0, t0, 1 # Update counter
    div t2, a0, t1 # t2 = y/k
    add t2, t2, t1 # t2 += k
    srli t2, t2, 1 # t2 /= 2
    mv t1, t2      # t1 = t2 is the new approximation k'
    j 1b
1:
    mv a0, t1      # a0 <= approximate square root
    ret

# Euclidean Distance between two points, A and B, in a 3D space.
# Parameters:
#     a0 (x_a): X coordinate of point A.
#     a1 (y_a): Y coordinate of point A.
#     a2 (z_a): Z coordinate of point A.
#     a3 (x_b): X coordinate of point B.
#     a4 (y_b): Y coordinate of point B.
#     a5 (z_b): Z coordinate of point B.
# Return value (a0):
#     Euclidean distance between the two points.
# C signature: int get_distance(int x_a, int y_a, int z_a, int x_b, int y_b, int z_b)
.globl get_distance
get_distance:
    # Storing ra
    addi sp, sp, -16
    sw ra, (sp)
    # distance = sqrt((xa-xb)^2 + (ya-yb)^2 + (za-zb)^2)
    sub t0, a0, a3  # t0 <= xa - xb
    mul t0, t0, t0  # t0 <= (xa - xb)^2
    sub t1, a1, a4  # t1 <= ya - yb
    mul t1, t1, t1  # t1 <= (ya - yb)^2
    sub t2, a2, a5  # t2 <= za - zb
    mul t2, t2, t2  # t2 <= (za - zb)^2
    add t0, t0, t1
    add a0, t0, t2  # a0 <= distance ^ 2
    li a1, 15       # a1 <= Number of iterations (15 works)
    jal approx_sqrt # a0 <= distance
    # Recovering ra
    lw ra, (sp)
    addi sp, sp, 16
    ret

# Copies all fields from the head node to the fill node and
# returns the next node on the linked list (head->next).
# Parameters:
#     head: Current head of the linked list.
#     fill: Node struct to be filled with values from the current head node.
# Return value (a0):
#     Next node on the linked list.
# C signature: Node *fill_and_pop(Node *head, Node *fill)
.globl fill_and_pop
fill_and_pop:
    li t0, 8        # Counter
    mv t2, a0
1:  # Loop for each field (there are 8 fields in total, all of them are words)
    lw t1, (t2)     # Load information from head node
    sw t1, (a1)     # and store it in the head node
    addi t2, t2, 4  # Next field of the head node
    addi a1, a1, 4  # Next field of the fill node
    addi t0, t0, -1 # Updates counter
    bgtz t0, 1b     # If counter > 0, then loop
    # Loop end
    addi a0, a0, 28
    lw a0, (a0)     # a0 <= next node on the linked list
    ret