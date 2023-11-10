.section .data
input_buffer: .space 20        # Reserve 20 bytes for the input buffer.
output_buffer: .space 20       # Reserve 20 bytes for the output buffer.

.section .text
.globl _start

_start:
    # Read input
    li a0, 0                   # File descriptor 0 (stdin).
    la a1, input_buffer        # Address of the buffer to write the data.
    li a2, 20                  # Size (reads 20 bytes).
    li a7, 63                  # Syscall read (63).
    ecall

    # Process each 4-digit number
    la t0, input_buffer
    la t1, output_buffer
    li t2, 4                   # Loop counter for 4 numbers.

process_loop:
    # Parse integer from input
    li t3, 0                   # Clear t3 to store the number.
    li t5, 10                  # Multiplier for digit position.

    # Assuming the input is well-formatted as "DDDD DDDD DDDD DDDD\n"
    li t6, 4                   # Counter for digits in a number.
parse_integer:
    lb t4, 0(t0)               # Load byte from input buffer.
    subi t4, t4, '0'           # Convert ASCII to integer.
    mul t3, t3, t5             # Shift previous digits.
    add t3, t3, t4             # Add new digit to total.
    addi t0, t0, 1             # Move to the next byte.
    addi t6, t6, -1
    bnez t6, parse_integer     # Loop if more digits to read.

    # Calculate square root using Babylonian method with 10 iterations
    mv t7, t3                  # t7 is the number for which we find the square root.
    srai t8, t7, 1             # Initial guess, half of t7.
    li t9, 10                  # Iteration counter.

babylonian_method:
    div t4, t7, t8             # t4 = t7 / t8.
    add t4, t8, t4             # t4 = t8 + t4.
    srai t8, t4, 1             # t8 = t4 / 2.
    addi t9, t9, -1
    bnez t9, babylonian_method # Loop for 10 iterations.

    # Convert result to string
    li t5, 1000                # Divider for extracting digits.
    li t6, 4                   # Counter for digits in output.

convert_to_string:
    div t4, t8, t5             # Extract digit.
    rem t8, t8, t5             # Remaining number.
    addi t4, t4, '0'           # Convert to ASCII.
    sb t4, 0(t1)               # Store byte in output buffer.
    muli t5, t5, 0.1           # Reduce divider by 10.
    addi t1, t1, 1             # Move to the next byte in buffer.
    addi t6, t6, -1
    bnez t6, convert_to_string # Loop if more digits to write.

    # Add space or newline after the 4-digit number
    li t4, ' '                 # ASCII space.
    bne t2, zero, no_newline   # If not the last number, write a space.
    li t4, '\n'                # Else write a newline.

no_newline:
    sb t4, 0(t1)               # Store byte in output buffer.
    addi t1, t1, 1             # Increment buffer pointer.
    addi t2, t2, -1            # Decrement number counter.
    bnez t2, process_loop      # If there are more numbers, loop.

    # Write output
    li a0, 1                   # File descriptor 1 (stdout).
    la a1, output_buffer       # Address of the output buffer.
    li a2, 20                  # Size (20 bytes).
    li a7, 64                  # Syscall write (64).
    ecall

    # Exit
    li a7, 93                  # Syscall exit (93). 