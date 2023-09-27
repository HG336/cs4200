.globl main
.equ STDOUT, 1
.equ STDIN, 0
.equ __NR_READ, 63
.equ __NR_WRITE, 64
.equ __NR_EXIT, 93

.text
main:
    # Print the first prompt message
    li a7, __NR_WRITE
    li a0, STDOUT
    la a1, prompt1
    addi a2, zero, prompt1_end - prompt1
    ecall

    # Read the first integer from the user and store it in input1
    li a7, __NR_READ
    li a0, STDIN
    la a1, input1
    addi a2, zero, input_end - input1
    ecall

    # Print the second prompt message
    li a7, __NR_WRITE
    li a0, STDOUT
    la a1, prompt2
    addi a2, zero, prompt2_end - prompt2
    ecall

    # Read the second integer from the user and store it in input2
    li a7, __NR_READ
    li a0, STDIN
    la a1, input2
    addi a2, zero, input_end - input2
    ecall

    # Print the thrid prompt message
    li a7, __NR_WRITE
    li a0, STDOUT
    la a1, prompt1
    addi a2, zero, prompt1_end - prompt1
    ecall

    # Read the third integer from the user and store it in input3
    li a7, __NR_READ
    li a0, STDIN
    la a1, input3
    addi a2, zero, input_end - input3
    ecall

    # Print the inputs (for demonstration)
    li a7, __NR_WRITE
    li a0, STDOUT
    la a1, input1
    ecall

    call do_math

do_math:
       # Load the operator from input2 
    la a3, input2
    lw a4, 0(a3)
    # Check the operator and call the corresponding function

    li a5, 0xa2b
    beq a4, a5, do_add
    li a5, 0xa2d
    beq a4, a5, do_sub
    li a5, 0xa2a
    beq a4, a5, do_mulitply
    li a5, 0xa2f
    beq a4, a5, do_divide


do_add:
# a0 - First Integer String
        la a3, input1
        lw a0, 0(a3)
        # a1 - Second Integer String
        la a3, input3
        lw a1, 0(a3)

        # Initialize the carry and the result register
        li t2, 0    # t2 - Carry
        li t3, 0    # t3 - Result
        
        # Loop through each bit of the integers
        li t4, 0    # t4 - Bit position counter
bit_loop:
        bge t4, 32, end_loop   # If 32 bits have been processed, exit the loop
        
        # Extract the current bits to be added
        andi t5, a0, 1   # t5 - Bit from first integer
        andi t6, a1, 1   # t6 - Bit from second integer
        
        # Perform bitwise addition
        xor t7, t5, t6   # t7 = t5 + t6 without carry
        xor t7, t7, t2   # Add the carry
        or t8, t5, t6    # t8 - intermediate carry
        and t8, t8, t2   # Final carry for next iteration
        or t2, t8, t9    # Update carry
        
        sll t7, t7, t4   # Shift the result bit to its position
        or t3, t3, t7    # Combine with the previously calculated bits
        
        srl a0, a0, 1    # Shift the first integer right for next bit
        srl a1, a1, 1    # Shift the second integer right for next bit
        
        addi t4, t4, 1   # Move to the next bit
        j bit_loop

end_loop:
        # Check for overflow
        bnez t2, overflow_detected
        
        # Set the result register
        mv a0, t3
        ret
        
overflow_detected:
        li a1, 1    # Set overflow flag in a1 register
        ret


do_sub:
        # a0 - First Integer String
        la a3, input1
        lw a0, 0(a3)
        # a1 - Second Integer String
        la a3, input3
        lw a1, 0(a3)
        
        # Convert input strings to integers
        jal ra, string_to_int    # Assuming this function is defined to convert string to int
        mv t0, a0                # t0 = first integer
        mv a0, a1                # Move the second string to a0 for conversion
        jal ra, string_to_int    # Convert second string to int
        mv t1, a0                # t1 = second integer
        
        # Take 2's complement of the second integer
        li t2, -1                # Load -1 into a temporary register
        xori t1, t1, t2          # Invert all bits of the second integer
        li t2, 1                 # Load immediate 1 into a temporary register
        mv a0, t0                # Move first integer to a0
        mv a1, t1                # Move 2's complement of second integer to a1
        jal ra, do_add           # Call do_add to add 1 to the inverted bits of the second integer
        
        # Check for overflow and return the result
        mv a0, a1                # Move the result to a0
        ret                      # Return
        

do_mulitply:
    # a0 - First Integer String
     la a3, input1
     lw a0, 0(a3)
      # a1 - Second Integer String
      la a3, input3
      lw a1, 0(a3)
    # Convert input strings to integers
    jal ra, string_to_int
    mv t0, a0   # t0 = first integer
    mv a0, a1   # Move the second string to a0 for conversion
    jal ra, string_to_int
    mv t1, a0   # t1 = second integer
    
    # Initialize result registers
    li t2, 0    # t2 = Least Significant 32 bits of the result
    li t3, 0    # t3 = Most Significant 32 bits of the result

    li t4, 0    # Initialize bit position counter
multiply_loop:
    bge t4, 32, end_loop   # If all bits have been processed, exit the loop
    
    andi t5, t1, 1   # Extract the least significant bit of the second integer
    beqz t5, skip_addition   # If the bit is 0, skip the addition
    
    # For set bit, shift first integer and accumulate to the result
    sll t6, t0, t4   # Shift the first integer to left by the bit position
    mv a0, t2        # Set operand for do_add
    mv a1, t6        # Set operand for do_add
    jal ra, do_add   # Call do_add to accumulate the partial product
    mv t2, a0        # Update Least Significant 32 bits of the result
    
skip_addition:
    srl t1, t1, 1    # Shift the second integer right for the next bit
    addi t4, t4, 1   # Move to the next bit
    j multiply_loop
    
end_loop:
    # Return the result
    mv a0, t3    # Most Significant 32 bits of the product
    mv a1, t2    # Least Significant 32 bits of the product
    ret

do_divide:
  # a0 - First Integer String
     la a3, input1
     lw a0, 0(a3)
      # a1 - Second Integer String
     la a3, input3
      lw a1, 0(a3)
    
    # Convert input strings to integers
    jal ra, string_to_int
    mv t0, a0   # t0 = dividend
    mv a0, a1   # Move the divisor string to a0 for conversion
    jal ra, string_to_int
    mv t1, a0   # t1 = divisor
    
    li t2, 0    # t2 = quotient
    li t3, 0    # t3 = remainder, initially same as dividend
    
    # Check if divisor is zero
    beqz t1, end_divide   # If divisor is zero, end division to avoid division by zero
    
divide_loop:
    # Compare remainder and divisor
    blt t3, t1, end_loop  # If remainder is less than divisor, end loop
    
    # Subtract divisor from remainder and update quotient
    mv a0, t3   # Move remainder to a0 for do_sub
    mv a1, t1   # Move divisor to a1 for do_sub
    jal ra, do_sub  # Call do_sub
    
    mv t3, a0   # Update remainder
    addi t2, t2, 1  # Increment quotient by 1
    j divide_loop
    
end_loop:
    mv a0, t2   # Move quotient to a0
    mv a1, t3   # Move remainder to a1
    ret
    
end_divide:
    # Handle division by zero case here, if needed
    # You may want to return an error code or flag in this case
    ret



    # Exit the program
    li a0, 0
    jr ra

.data
prompt1: .ascii "\nPlease enter an integer: "
prompt1_end:
prompt2: .ascii "\nPlease enter an operator (+, -, *, /): "
prompt2_end:

input1: .space 100
input2: .space 100
input3: .space 100
input_end: