# Title:    MMN_11_Q4
# Question: Q4
# Author:   Yotam Levit - ID. 200041119
# Date:     1.8.2025 (dd.mm.YYYY)
#
# Description: The program calculates products of pairs of neighbor numbers
#	       (positive and negative number) in an array of numbers using loops.
#	       The program will also use additional registers to calculate 
#	       the sum of all products and sum of the diffrences between products,
#	       At the end of the program all the results will be printed to the user as presented on the MMN11_Q4.
#		
#
# Input:       An array of 10 byte sized numbers represented using MSB / Two complement
#
# Output:      The program prints all the products of pairs of neighbor numbers in the array.
#	       The program also prints the sum of all the products and the sum of the diffrences between the products.
#	       The output will be exactly as presented in the example on MMN11_Q4 
#

#################### Data Segment ####################
.data

array: .byte -14,89,-8,-10,-90,120,-1,-19,90,10 # Input - array of 10 numbers (Two complement / MSB representation) in Byte size
array1: .word 0:9 				# 9 words array for the 9 products

# Print messages
input_msg: .asciiz "Input array is: "
product_of_numbers_msg: .asciiz "The product of adjacent numbers in the array: "
sum_of_products_msg: .asciiz "The sum of all products is: "
sum_of_differences_msg: .asciiz "The sum of the differences of products is: "
newline: .asciiz "\n"
#################### Code Segment ####################
.text
.globl main
main:
	# Prints input to the use
	la $a0, input_msg  # Loads print msg to a0 
    	jal print_string 		# Calling funciton to print string
	la $a0, array       # pointer to start of array
    	li $a2, 10          # number of bytes
    	jal print_byte_array
    	
    	li $a0, '\n'  	# Prints new line after number
	li $v0, 11
	syscall 

	# Init registers
	la $t1, array 		 # Load base address of input byte array into $t1
	or $t2, $zero, $zero     # Setting $t2 as a counter for a loop. Using OR making sure register is 0
	addi $t3, $zero, 9     	 # setting $t3 the total number of pais on the array. Using addi we make sure the register is 9
		      		 # Using a resigter will save performance, allows us to use basic instructions (1 insted of 2 with an immediate).
	
	or $t4, $zero, $zero     # Setting $t4 as the sum of all the products. Using OR making sure register is 0
	la $t6, array1 		 # Loads base address of the product array into $t6
	
	# Load and print intro message
    	la $a0, product_of_numbers_msg  # Loads print msg to a0 
    	jal print_string 		# Calling funciton to print string
  
	li $a0, '\n'  	# Prints new line after number
	li $v0, 11
	syscall 
	
loop:
	beq $t2, $t3, exit_loop # Loop condition, when counter equals to 9 we got over all the pairs (0-9)

	lb $t7, ($t1) 		# Load first number
	lb $t8, 1($t1)		#load second number
	mul $t9, $t7, $t8 	# Multiplay pair of numbers - results is stored in lo and t1,
				# no need for high bytes max result is 127^2, min result is -128*128
	
	move $a0, $t9  # Prints the product
	li $a1, '\n' # New line to print after the number
	jal print_int
	
	sw $t9, ($t6) 		# Store result in array1
	
	add $t4, $t4, $t9 	# Adding the new product to the sum of products
	
	addi $t6, $t6, 4 	# move t6 address to next element in array1
	addi $t1, $t1, 1 	# move t1 to the next element in array
	addi $t2, $t2, 1 	# t2 ++
	j loop

exit_loop:
	# Load and print sum of product result
	la $a0, sum_of_products_msg  	# Loads print msg to a0 
    	jal print_string 		# Calling funciton to print string
    	
    	move $a0, $t4  			# Loads print msg to a0 
    	jal print_int
    	
    	# Load and print sum of product diffrences result
    	la $a0, sum_of_differences_msg  # Loads print msg to a0 
    	jal print_string 		# Calling funciton to print string
    	
    	la $t1, array1 		 	# Loads the address of the product array
	lw $t7, ($t1) 			# Load first product of array
	lw $t8, 32($t1)			# Load last product of array
	sub $a0, $t7, $t8 		# Setting $a0 as sum of the diffrences between the products (To pass later to the print_int function).
			  		# Sum of diffrences is just the diffrence between first product and last product (THis is true for all array size 10).
	jal print_int
	
	j program_end


program_end:
	li $v0, 10 # Call exit
	syscall
	

# -------------------------------
# Function: print_int
# Decription: prints a number in a register ands a char ar the end (can be newline or space etc)
# Input:    $a0 = integer to print
#	    $a1 = char to print after the number
# -------------------------------
print_int:
	li $v0, 1 	# Print number syscall
	syscall 
    
	move $t0, $ra 	# Backup return address, not using stack to not use IO. Making sure t0 is not in use in print_string
	move $a0, $a1  	# Prints new line after number
	li $v0, 11
	syscall 
    
	move $ra, $t0 	# restore return address
	jr $ra


# -------------------------------
# Function: print_string
# Input:    $a0 = address of string (.asciiz)
# -------------------------------
print_string:
	li $v0, 4 	# Print string syscall
	syscall
	jr $ra
    
    
# -------------------------------------------------------
# Function: print_byte_array
# Input:
#   $a0 - pointer to array of bytes
#   $a2 - number of elements
# Output:
#   prints each byte (as signed int) followed by a space
# -------------------------------------------------------
print_byte_array:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)

	move $s0, $a0      # s0 = pointer to array

print_byte_array_loop:
	beq $a2, $zero, print_byte_array_end

	lb $a0, 0($s0)     # load signed byte
	li $a1, ' ' 	   # Print space after number
	jal print_int

	addi $s0, $s0, 1   # move to next byte
	addi $a2, $a2, -1
	j print_byte_array_loop

print_byte_array_end:
	lw $s0, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra
