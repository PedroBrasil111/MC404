.text
/******************************************************************************/
/*  Car Peripheral                                                            */
/******************************************************************************/

/*
  Define values to vertical and horizontal movement of the car.
  Parameters: 
  * vertical:   a byte that defines the vertical movement of the car, between -1 and 1.
                -1 makes the car go backwards and 1 forward. (Engine)
  * horizontal: defines the vertical movement of the car, between -127 and 127
                Negative values make the car go to the left and positive to the right. (Steering Wheel)
  Returns:
  * 0 in case of a success.
  * -1 if any of the parameters are out of bounds.
*/
# int set_engine(int vertical, int horizontal);
set_engine:
    li a7, 10 # Syscall set engine and steering
    ecall     # a0 <= 0 in case of success, -1 if a parameter is out of bounds
    ret

/*
  Set the handbrake of the car
  Parameters:
  * value:  a byte that defines if the brake will be triggered or not.
            1 to trigger the brake e 0 to stop using it.
  Returns:
  * 0 in case of success.
  * -1 if the value parameter is invalid.
*/
# int set_handbrake(char value);
set_handbrake:
    andi t0, a0, ~0x1 # t0 is a0 with the last byte cleared (if a0 is 0 or 1, then t0 is 0)
    bnez t0, fail_handbrake
    li a7, 11         # Syscall set handbrake
    ecall             # Syscall has no return value
    li a0, 0
    j ret_handbrake
fail_handbrake:
    li a0, -1
ret_handbrake:
    ret

/*
  Reads distnace from the ultrasonic sensor
  Parameters: 
    None
  Returns: 
    * the distance detected by the sensor, in cetimeters, if an object is detected.
    * -1, if no object is detected.
*/
# int read_sensor_distance();
read_sensor_distance:
    li a7, 13 # Syscall read sensor distance
    ecall     # a0 <= distance detected in cm, or -1 if there are no objects within 20m
    ret

/*
  Reads the approximate position of the car using a GPS device
  Parameters:
  * x: address of the variable that will store the value of the x position.
  * y: address of the variable that will store the value of the y position.
  * z: address of the variable that will store the value of the z position.
  Returns:
    Nothing
*/
# void get_position(int* x, int* y, int* z);
get_position:
    li a7, 15 # Syscall get position
    ecall     # Syscall has no return value
    ret

/*
  Reads the global rotation of the gyroscope device
  Parameters:
  * x: address of the variable that will store the value of the Euler angle in x.
  * y: address of the variable that will store the value of the Euler angle in y.
  * z: address of the variable that will store the value of the Euler angle in z.
  Returns:
    Nothing
*/
# void get_rotation(int* x, int* y, int* z);
get_rotation:
    li a7, 16 # Syscall get position
    ecall     # Syscall has no return value
    ret

/******************************************************************************/
/*  GPT Peripheral                                                            */
/******************************************************************************/

/*
  Reads system time
  Parameters:
    None
  Returns:
    System time, in milliseconds.
*/
# unsigned int get_time();
get_time:
    li a7, 20 # Syscall get systime
    ecall     # a0 <= time since sistem has been booted, in milliseconds
    ret

/******************************************************************************/
/*  Utility Functions                                                         */
/******************************************************************************/

/*
  puts function from https://www.cplusplus.com/reference/cstdio/puts/ but in this 
  case it must use the Serial Port peripheral to perform writes.
  It prints a \n instead of the ending \0.
  Parameters:
    * str: string terminated in \0.
  Returns:
    Nothing
*/
# void puts ( const char *str );
puts:
    ret
/*
  gets function from https://www.cplusplus.com/reference/cstdio/gets/ but in this 
  case it must use the Serial Port perifpheral to perform reads.
  Parameters:
    * str: Buffer to be filled.
  Returns:
    Filled butter with a \0 terminated string.
*/
# char *gets ( char *str );
gets:
    ret

/*
  atoi function from https://www.cplusplus.com/reference/cstdlib/atoi/?kw=atoi 
  Parameters:
    * str: \0 terminated string of the decimal representation of a number.
  Returns:
    The integer value represented by the string.
*/
# int atoi (const char *str);
atoi:
    ret

/*
  itoa function from https://www.cplusplus.com/reference/cstdlib/itoa/ 
  Parameters:
    * value: integer value to be converted.
    * str: Buffer to be filled with \0 terminated string of the representation of the number.
    * base: base to use, either 10 or 16.
  Returns:
    Filled butter with a \0 terminated string.
*/
# char *itoa ( int value, char *str, int base );
itoa:
    ret

/*
  Custom implementation of the strlen function from https://cplusplus.com/reference/cstring/strlen/ 
  Parameters:
    * str: String terminated by \0
  Returns:
    Size of the string without counting the \0
*/
# int strlen_custom( char *str );
strlen_custom:
    li t0, 0       # t0 will hold the string's length
1:  # Loops for each byte
    lbu t1, (a0)   # Loads byte from string
    bez t1, 1f     # If byte is null (\0), then end loop
    addi t0, t0, 1 # Increment length
    addi a0, a0, 1 # a0 points to the next byte in the string
    j 1b           # Loop
1:
    mv a0, t0      # a0 is now the string's length
    ret

/*
  Approximate Square Root computation using the Babylonian Method.
  Parameters:
    * value: integer value
    * iterations: number of iterations to perform the Babylonian method
  Returns:
    Approximate square root of value.
*/
# int approx_sqrt(int value, int iterations);
approx_sqrt:
    # k = y/2, k' = (k + y/k)/2
    li t0, 0       # Counter for iterations
    srli t1, a0, 1 # t1 is the initial guess k = y/2
1:  # Loops the same number of times as iterations
    bge t0, a1, 1f # If counter >= number of iterations then end loop
    addi t0, t0, 1 # Update counter
    div t2, a0, t1 # t2 = y/k
    add t2, t2, t1 # t2 += k
    srli t2, t2, 1 # t2 /= 2
    mv t1, t2      # t1 = t2 is the new approximation k'
    j 1b
1:
    mv a0, t1      # a0 <= approximate square root
    ret

/*
  Euclidean Distance between two points, A and B, in a 3D space.
  Parameters:
    * x_a: X coordinate of point A.
    * y_a: Y coordinate of point A.
    * z_a: Z coordinate of point A.
    * x_b: X coordinate of point B.
    * y_b: Y coordinate of point B.
    * z_b: Z coordinate of point B.
  Returns:
    Euclidean distance between the two points.
*/
#                       a0       a1       a2       a3       a4       a5
# int get_distance(int x_a, int y_a, int z_a, int x_b, int y_b, int z_b);
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
    jal approx_sqrt # a0 <= distance
    # Recovering ra
    lw ra, (sp)
    addi sp, sp, 16
    ret

/*
  It copies all fields from the head node to the fill node and 
  returns the next node on the linked list (head->next).
  Parameters:
    * head: current head of the linked list
    * fill: node struct to be filled with values from the current head node. 
  Returns:
    Next node on the linked list.
*/
# Node *fill_and_pop(Node *head, Node *fill);
fill_and_pop:
    li t0, 7        # Counter
1:  # Loops for each field (there are 8 fields in total, all of them are words)
    lw t1, (a0)     # Load information from head node
    sw t1, (a1)     # and store it in the head node
    addi a0, a0, 4  # Next field of the head node
    addi a1, a1, 4  # Next field of the fill node
    addi t0, t0, -1 # Updates counter
    bgtz t0, 1b     # If counter > 0, then loop
    # Loop end
    ret             # a0 <= next node on the linked list
