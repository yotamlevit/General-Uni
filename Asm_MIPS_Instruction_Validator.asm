# Title:    MMN_11_Q5
# Question: Q5
# Author:   Yotam Levit - ID. XXXX
# Date:     3.8.2025 (dd.mm.YYYY)
#
# Program: MMN11_Q5 — MIPS Instruction Memory Scanner
#
# Title:    MMN_11_Q5
# Question: Q5
# Author:   Yotam Levit - ID. 200041119
# Date:     3.8.2025 (dd.mm.YYYY)
#
# Description: 	Read a sequence of 32-bit MIPS instructions in memory (labelled InstrMem,
#       	   	terminated by 0xFFFFFFFF), and for each:
#       	    * Classify as R-type, I-type or illegal
#       	    * Extract register operands (rs, rt, and rd for R-types)
#       	    * Count total, valid, invalid, R-type & I-type instructions
#       	  	* Detect warnings:
#       	        	- rs == rt in any beq or other R-type
#       	        	- any attempt to write to $zero (rt==0 in loads, rd==0 in R-types)
# 				* Accumulate a per-register usage frequency table
#       	    * Print each warning/illegal as its found:
#       	         	Warning: <msg> at index <dec>: 0x<hex>
#       	         	Unknown instruction at index <dec>: 0x<hex>
#       	   	After the scan, print:
#       	     		Total instructions:    <N>
#       	     		Valid instructions:    <M>
#       	     		Invalid instructions:  <K>
#       	     		R-type instructions:   <R>
#       	     		I-type instructions:   <I>
#       	     		Warnings:              <W>
#	
#       	     		Register usage:
#       	       		$<reg> - <count> time(s)
#		
#
# Input:       .data -> InstrMem: .word <32-bit hex instuction>... , 0xFFFFFFFF terminator
#
# Output:	Printed warnings, summary stats, and register usage as above
#
#################### Data Segment ####################
.data

# Instruction commands - between 5-50 including end of array.
InstrMem: .word 0x012A4020 # add $8, $9, $10 (R-type)
.word 0x8C910004 # lw $17, 4($4) (I-type)
.word 0xACB20008 # sw $18, 8($5) (I-type)
.word 0x11290003 # beq $9, $9, label (I-type, rs == rt) -> WARNING
.word 0x01400020 # add $0, $10, $0 (R-type, rd==0) -> WARNING
.word 0x8C000010 # lw $0, 16($0) (I-type, rt==0) -> WARNING
.word 0xAC13000C # sw $19, 12($0) (I-type)
.word 0x003123AB # illegal opcode/func
.word 0xFFFFFFFF # End of array

# Registers Counters array
RegCounters: .byte 0:32
# ----------- Print messages ------------
# Summary
total_instr_msg: .asciiz "\nTotal instructions: "
valid_instr_msg: .asciiz "Valid instructions: "
invlid_instr_msg: .asciiz "Invalid instructions: "
r_type_instr_msg: .asciiz "R-type instructions: "
i_type_instr_msg: .asciiz "I-type instructions: "
warnings_count_msg: .asciiz "Warnings: "
register_usage_title_msg: .asciiz "\nRegister usage:\n"

# Warnings & Errors
e_illegal_msg:  .asciiz "Unknown instruction at index "
w_zero_msg:  .asciiz "Warning: attempt to write to $zero at index "
w_rsrt_msg:  .asciiz "Warning: rs == rt at index "

# Prefixes & Postsfixes
newline:     .asciiz "\n"
hex_prefix:   .asciiz ": "
register_prefix: .asciiz "$"
register_usage_print_delimiter: .asciiz " - "
register_usage_print_postfix: .asciiz " time"
many_postfix: "s"

#################### Code Segment ####################
.text
.globl main
main:
	# Init pointers and counters
	or $s0, $zero, $zero     # Setting $t0 as counter/index for total instructions. Using OR making sure register is 0.
	or $s1, $zero, $zero     # Setting $t1 as counter for valid instructions. Using OR making sure register is 0.
	or $s2, $zero, $zero     # Setting $t2 as counter for R-Type instructions. Using OR making sure register is 0.
	#or $s3, $zero, $zero     # Setting $t3 as counter for I-Type instructions. Using OR making sure register is 0.
	or $s4, $zero, $zero     # Setting $t4 as counter for Warnings. Using OR making sure register is 0.
	la $s5, InstrMem 	 # Load base address of InstrMem array into $t0
	

scan_loop:
	lw $s6, ($s5)		 # Loads instruction into $t2. $t2 will be used as our instruction buffer.
	beq $s6, 0xFFFFFFFF, end_scan_loop
	
	move $a0, $s6
	jal  ClassifyInstruction
	
	bne $v0, 0, legal_instruction # TODO handle illeagal instrudctions
	la $a0, e_illegal_msg
	move $a1, $s0
	move $a2, $s6
	jal PrintWarning
	j scan_next_instruction
	
legal_instruction:
	bne $v0 ,1, instruction_rtype_logged # If r-type count
	addi $s2, $s2, 1 # r-type counter++
	
instruction_rtype_logged:	
	addi $s1, $s1, 1 # Valid instruction ++	
	move $a1, $v0 # Instruction Type Rtype IRype
	jal ExtractRegisters
	
	move $a0, $a1 # Instruction Type Rtype IRype
	move $a1, $v0 # rs
	move $a2, $v1 # rt
	move $a3, $t0 # rd
	jal CountRegisters
	
	move $a0, $s0
	jal CheckWarnings # a1-a3 are not change from CountRegisters
	add $s4, $s4, $v0 # Add warnings form current instruction to warnings coutner
	


scan_next_instruction:
	addi $s5, $s5, 4
	addi $s0, $s0, 1 # $t1 ++
	j scan_loop


end_scan_loop:
	move $a0, $s0
	move $a1, $s1
	move $a2, $s2
	move $a3, $s4
	jal PrintSummary
	jal PrintRegisterUsage
	
	j program_end
	
program_end:
	li $v0, 10 # Call exit
	syscall

    
# -------------------------------------------------------
# Function: ClassifyInstruction
# Decription: Identify command - R/I or iligal
# Input:
#   	$a0 - 32-bit ASM instruction word
# Output:
#   	$v0 - 0 (illegal) | 1 (R-type) | 2 (I-type)
# Uses: $t1,$t2
# -------------------------------------------------------
ClassifyInstruction:
	srl $t1,$a0,26          # opcode -> $t1
	
	# R-format if opcode==0
        beq $t1,0,CheckIsRType
        
	# I-type check: lw(0x23), sw(0x2B), beq(0x04)
        beq $t1,0x23, IsIType
        beq $t1,0x2B, IsIType
        beq $t1,0x04, IsIType
        
        # else illegal
        j RetIlleagalInstr
        
CheckIsRType:
	andi $t1, $a0, 0x3F # func -> $t7
	
	# Supported add(0x20), sub(0x22), and(0x24), or(0x25), slt(0x2A)
	beq $t1, 0x20, IsRType # add(0x20)
	beq $t1, 0x22, IsRType # sub(0x22)
	beq $t1, 0x24, IsRType # and(0x24)
	beq $t1, 0x25, IsRType # or(0x25)
	beq $t1, 0x2A, IsRType # slt(0x2A)
	
        j RetIlleagalInstr
        
IsRType:
        li $v0,1 # RType
        jr $ra

IsIType:
        li $v0,2 # IType
        jr $ra

RetIlleagalInstr:
	li $v0, 0 # Illigeal
        jr $ra

# -------------------------------------------------------
# Function: ExtractRegisters
# Decription: Decode the instruction fields rs,rt,rd
# Input:  $a0 - instruction word
#         $a1 - RType or IType
# Output: $v0 - rs
#         $v1 - rt
#         $t0 - rd (or 0 if I-type)
# -------------------------------------------------------
ExtractRegisters:
	# Extract rs
	srl $v0, $a0, 21
	andi $v0, $v0, 0x1F
	
	# Extract rt
        srl $v1, $a0, 16
        andi $v1, $v1, 0x1F
        
        # Init $v3 for rd
        or $t0, $zero, $zero
        
	# Checks if IType - no rd needed for iType
	beq $a1, 2, RetExtractRegisters # 2 = Itype
	
	# If here instruction is RType - extract rd
	srl $t0, $a0, 11
        andi $t0, $t0, 0x3F
	
RetExtractRegisters:
	jr $ra

# -------------------------------------------------------
# Function: CountRegisters
# Decription: Update register counters in memort (RegCounters)
#	      The first byte represent $0 and second byte represent $1 etc.
# Input: $a0 - instruction type (RType or IType)
#   	 $a1 - rs value
#	 $a2 - rt value
#	 $a3 - rd value (ignored for IType)
# Output:
#   	Updates the right counter in RegCounter that represent the register number.
# Uses: $t0,$t1,$t2,$t3
# -------------------------------------------------------
CountRegisters:
	la $t0, RegCounters # Laods the base address of RegCounters
	
	# Count rs register
	#mul $t3, $a1, 4
	add $t1, $t0, $a1 # addr of rs register counter = RegCounters + rs
	lb $t2, ($t1)	  # t2 contains current counter of the register
	addi $t2, $t2, 1  # increment
	sb $t2, ($t1)    # Dump new count into memory
	
	# Count rt register
	#mul $t3, $a2, 4
	add $t1, $t0, $a2 # addr of rt register counter = RegCounters + rt
	lb $t2, ($t1)	  # t2 contains current counter of the register
	addi $t2, $t2, 1  # increment
	sb $t2, ($t1)    # Dump new count into memory
	
	bne $a0, 1, RetCountRegisters # if instruction type is not RType go to end of function, no need for rd count
	
	# If here instruction is t Rtype
	# Count rd
	#mul $t3, $a3, 4
	add $t1, $t0, $a3 # addr of rd register counter = RegCounters + rd
	lb $t2, ($t1)	  # t2 contains current counter of the register
	addi $t2, $t2, 1  # increment
	sb $t2, ($t1)    # Dump  new count into memory
	

RetCountRegisters:
	jr $ra

# -------------------------------------------------------
# Function: CheckWarnings
# Decription: Execute checks on the instructions and print warnings if needed
#	      A warning is:
#			- For R-Type and beq if rs=rt - Warning: rs == rt at index X: 0xXXXXXXXX
#			- For R-Type and lw if rt=0 - Warning: attempt to write to $zero at index X: 0xXXXXXXXX
# Input: $a0 - instruction index - given index considered as a legal instruction
#   	 $a1 - rs
#	 $a2 - rt
#	 $a3 - rd
# Output:
#  	If a warning is found - print a msg to the screen
#	$v0 - nubmer of warnings for this command (max 2 for r-type both rs==rt and rd==0)
# -------------------------------------------------------
CheckWarnings:
	# save return address and registers in stack
    	sub $sp, $sp, 20
    	sw $ra, 16($sp)
    	sw $s0, 12($sp) # s0 is callee saved register

    	
	# Reset return value register
	or $s0, $zero, $zero
	
	la $t8, InstrMem
	mul $t9, $a0, 4
	add $t4, $t9, $t8 # t4 hold the adddess for the instruction work on index a0
	lw $t3, ($t4) 	  # Load instruction work into $t3
	
	srl $t1,$t3,26 # opcode -> $t1
	
	# Test if instruction is  R-type or beq and if rs==rt
	ori $t2, $t1, 0x04 		# t2 = (opcode = R-Type or beq instrquction) # TODO check if ori is really needed
	bne $t2, 0x04, test_zero_warn 	# Checks if instruction is not R-type or beq 
	bne $a1,$a2, test_zero_warn	# Checks if not rs==rt
	
	# If here rs==rt warning should be raised
	addi $s0, $s0, 1 # $v0++
	
	# Save a0-a2 in stack - caller responsibility
	sw $a0, 8($sp)   # save index
    	sw $a1, 4($sp)   # save rs
    	sw $a2, 0($sp)   # save inst word

	# print “Warning: rs == rt at index ”
	move $a1, $a0
	la $a0, w_rsrt_msg
	move $a2, $t3
    	jal PrintWarning
    	# Restore Registers from stack
    	lw $a0, 8($sp)
    	lw $a1, 4($sp)
    	lw $a2, 0($sp)
	
test_zero_warn:	
	# Test if instruction is  R-type or lw and if rd==0
	# t1 holds opcode
	bne $t1, 0x23, test_rd_zero_warn # Checks if instruction is not lw
	beq $a2, $zero, print_zero_warn # Checks if rt==0 print warn
	
	# If here then instruction is lw (0x23) and rt!=0
	j RetCheckWarnings
	
test_rd_zero_warn:
	# t1 holds opcode
	bne $t1, 0, RetCheckWarnings # Continue only if instruciton is R-Type
	beq $a3, $zero, print_zero_warn # Checks if rd==0 print warn
	
	# If here then instruction is R-Type and rd!=0
	j RetCheckWarnings

print_zero_warn:
	# If here rd==0 warning should be raised
	addi $s0, $s0, 1 # $v0++
	# Save a0-a2 in stack
	sw $a0, 8($sp)   # save index
    	sw $a1, 4($sp)   # save rs
    	sw $a2, 0($sp)   # save inst word
	# print “Warning: rs == rt at index ”
	move $a1, $a0
	la $a0, w_zero_msg
	move $a2, $t3
    	jal PrintWarning
    	# Restore Registers from stack
    	lw $a0, 8($sp)
    	lw $a1, 4($sp)
    	lw $a2, 0($sp)
  	
RetCheckWarnings:
	move $v0, $s0 # move warning counter to v0
	# restore return address
	lw $s0, 12($sp)
 	lw $ra, 16($sp)
	addi $sp, $sp, 20
	jr $ra

# -------------------------------------------------------
# Function: print_warning
# Decription: Prints a warning line in the format:
#     <message> at index <decimal>: 0x<hexword>\n
# Input:
#   $a0 = address of warning message string (e.g. w_rsrt_msg)
#   $a1 = instruction index (decimal)
#   $a2 = instruction word (32-bit)
# Uses: $ra, $v0, $sp, $t0
# -------------------------------------------------------
PrintWarning:
    # print message string ($a0)
    li $v0, 4       # syscall: print_string
    syscall

    # print decimal index ($a1)
    move $a0, $a1
    li $v0, 1       # syscall: print_int
    syscall

    # print hex prefix ": 0x"
    la $a0, hex_prefix
    li $v0, 4       # syscall: print_string
    syscall

    # print instruction in hex ($a2)
    move $a0, $a2
    li $v0, 34      # syscall: print_hex
    syscall

    # print newline
    la $a0, newline
    li $v0, 4       # syscall: print_string
    syscall

    jr $ra


# -------------------------------------------------------
# Function: PrintSummary
# Decription: Prints the program summary
# Input:
#	$a0 - Total number of instructions
#	$a1 - Number of valid instructions
#	$a2 - Number of r-type instructions
#	$a3 - Number of Warnings
# Output:
#	The program prints to the scrren the next summary:
#	Total instructions: <X>
#	Valid instructions: <X>
#	Invalid instructions: <X>
#	R-type instructions: <X>
#	I-type instructions: <X>
#	Warnings: <X>
# -------------------------------------------------------
#warnings_count_msg: .asciiz "Warnings: " ### TODO
PrintSummary:
	# save return address and registers in stack
    	sub $sp, $sp, 4 # Can also use addi -8
    	sw $ra, ($sp)
    	
	move $t0, $a0
	move $t1, $a1
	move $t2, $a2
	#move $t3, $a3
	
	la $a0, total_instr_msg
	move $a1, $t0
	jal PrintSummaryLine
	
	la $a0, valid_instr_msg
	move $a1, $t1
	jal PrintSummaryLine
	
	la $a0, invlid_instr_msg
	sub $a1, $t0, $t1
	jal PrintSummaryLine
	
	la $a0, r_type_instr_msg
	move $a1, $t2 
	jal PrintSummaryLine
	
	la $a0, i_type_instr_msg
	sub $a1, $t1, $t2
	jal PrintSummaryLine
	
	la $a0, warnings_count_msg
	move $a1, $a3
	jal PrintSummaryLine

	# restore return address
 	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra

# -------------------------------------------------------
# Function: PrintSummaryLine
# Decription: Prints one line of the summary form this format:
#	      <message>: <decimal>\n
# Input:
#	$a0 - message to print
#	$a1 - decinal to print
# Output:
#	Print to the screen the message and the number in this format:
#	<message>: <decimal>\n
# -------------------------------------------------------
PrintSummaryLine:
	# save return address and registers in stack
    	sub $sp, $sp, 4
    	sw $ra, 0($sp)
	# print message string ($a0)
	jal PrintString

	# print decimal index ($a1)
	move $a0, $a1
	jal PrintInt
	
	# print newline
        la $a0, newline
	jal PrintString
	
	# restore return address
 	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# -------------------------------------------------------
# Function: PrintRegisterUsage
# Decription: Prints the program resigters summary
# Input:
#	No argument input.
#	THe program gets register counter inputs from the memory on RegCounters
# Output:
#   The program prints the register summary in this format for each register that appeared more then 0 times:
#	$<register_number> - <number_of_appearances>
# -------------------------------------------------------
PrintRegisterUsage:
# prologue: save $ra and $s0
	sub $sp, $sp,8
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	
	# Print Title
	la $a0, register_usage_title_msg
	jal PrintString
	
	li $s0, 0           # s0 = index = 0
	la $t1,RegCounters

register_usage_loop:
	beq $s0, 32, register_usage_loop_done   # done when index == 32

	lb $t0,($t1) # t0 = register count

	beq $t0,$zero, skip_register_print  # skip if count==0
	
	move $a0, $s0
	move $a1, $t0
	jal PrintRegUsageSummaryLine

skip_register_print:
	# next address address = RegCounters pointer + 1
	add $t1,$t1, 1 # Next Byte (register counter)
	add $s0,$s0,1
	j register_usage_loop

register_usage_loop_done:
	# restore $s0 and $ra
	lw $s0,0($sp)
	lw $ra,4($sp)
	addi $sp,$sp,8
	jr $ra
	
	
# -------------------------------------------------------
# Function: PrintRegUsageSummaryLine
# Decription: Prints one line of the register usage summary form this format:
#	      $<register_nubmer>: <usage_count>\n
# Input:
#	$a0 - register_number
#	$a1 - usage_count
# Output:
#	Print to the screen the message and the number in this format:
#	$<register_nubmer>: <usage_count>\n
# Registey Usage: $t2
# -------------------------------------------------------
PrintRegUsageSummaryLine:
	# save return address and registers in stack
    	sub $sp, $sp, 4
    	sw $ra, ($sp)
    	
    	move $t2 , $a0
    	# print "$"
	la $a0,register_prefix
	jal PrintString

	# print index (register number) (decimal)
	move $a0,$t2
	jal PrintInt

	# print " - "
	la $a0,register_usage_print_delimiter
	jal PrintString

	# print count
	move $a0,$a1
	jal PrintInt
	
	# printe "time"
	la $a0, register_usage_print_postfix
	jal PrintString
	
	ble $a1, 1, skip_multi_occurrences_ending # if usage <= 1
	
	# printe many postfix ("s")
	la $a0, many_postfix
	jal PrintString
	
	
skip_multi_occurrences_ending:

	# print newline
	la $a0,newline
	jal PrintString
	
	# restore return address
 	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra

# -------------------------------
# Function: PrintInt
# Decription: prints a number in a register 
# Input:    $a0 = integer to print
# -------------------------------
PrintInt:
	# save return address and registers in stack
    	sub $sp, $sp, 4 # Can also use addi -8
    	sw $ra, ($sp)
    	
	li $v0, 1 	# Print number syscall
	syscall  
    
	# restore return address
 	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra


# -------------------------------
# Function: print_string
# Input:    $a0 = address of string (.asciiz)
# -------------------------------
PrintString:
	# save return address and registers in stack
    	sub $sp, $sp, 4
    	sw $ra, ($sp)
    	
	li $v0, 4 	# Print string syscall
	syscall
	
	# restore return address
 	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
