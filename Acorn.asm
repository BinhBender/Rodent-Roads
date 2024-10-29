.eqv ACORN_X_LOWER_BOUNDS 0
.eqv ACORN_X_UPPER_BOUNDS 58
.eqv ACORN_Y_LOWER_BOUNDS 16
.eqv ACORN_Y_UPPER_BOUNDS 112

.eqv ACORN_RANDOMIZE_RANGE_X 58
.eqv ACORN_RANDOMIZE_RANGE_Y 96


.eqv WORD_SIZE 4
.eqv WIDTHBYTE 256
.eqv DISPLAY_ADDRESS 0x10040000

.eqv MAX_ACORNS 8	#ARBATRARY NUMBER
.eqv ACORN_LOCATIONS 32 #MAX_ACORNS * WORD SIZE => 8 * 4 = 32
.include "utility.asm"
.data 
	#Each word is a location of one so 32/4 = 8 max acorns
	AcornLocation: .space ACORN_LOCATIONS 
	
	#First 4 bytes for the distance, second 4 are for the index
	ClosestAcorn:	.space 8
	
.macro generate_random (%upper)
	li $v0, 42
	add $a1, $0, %upper
	li $a0, 0
	syscall
	move $v0, $a0
	
.end_macro

.macro calculateByteAddress (%x, %y)
	#get x offset
	mul %x, %x, WORD_SIZE
	#get y offset
	mul %y, %y, WIDTHBYTE
	#combine x and y offset to get absolute byte offset
	add $v0, %x, %y
	addi $v0, $v0, DISPLAY_ADDRESS
	
.end_macro	
######################
.macro generate_Acorns
#push stack
#I would use it as a counter for generating the acorn
		# $t0 to $t3 are used , needed to be pushed to stack
	addi $t0, $0, MAX_ACORNS
        la $t1, AcornLocation
	Generating_Acorns_loop: 
		addi $t0, $t0, -1
#Randomize the X first
    # Load the upper bound into $a0
		li $a0, ACORN_RANDOMIZE_RANGE_X
 		generate_random($a0)
 		move $t2, $v0

		li $a0, ACORN_RANDOMIZE_RANGE_Y
 		generate_random($a0)
		add $v0, $v0, ACORN_Y_LOWER_BOUNDS	#Need to add this since y doesn't start at zero, so we randomize the range, then add the bounds
		move $t3, $v0
		
   		calculateByteAddress ($t2,$t3)
   		sw $v0, 0($t1)
   		addi $t1, $t1, 4
	bnez $t0, Generating_Acorns_loop
	
.end_macro
.macro decode_position (%memory_address)
addi $sp, $sp -4
sw $t0, 0($sp)
	add $t0, $0, %memory_address	#Get Player position
	
	subi $t0, $t0, DISPLAY_ADDRESS	#Removes the display address
	divu $v1 , $t0, WIDTHBYTE	#Return the quotient which is the y
	mfhi $v0			#Return a remainder which is the x
	divu $v0, $v0, 4	#Divide by 4 since the REM is still in the word form
lw $t0, 0($sp)
addi $sp, $sp 4		
	
.end_macro
.macro find_collided_Acorn(%hitx, %hity)
#For every alive acorn in the scene
	#Store index of acorn with closest ditance
	#	if acorn[i] < closestAcorn
	#		switch index
	#Pushed using registers to the stack
	addi $sp, $sp, -16
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	
	li $t0, 0x7fffffff	#We assume that the closest acorn is very far away
	la $t1, ClosestAcorn
	sw $t0, 0($t1)
	
	#Make space to transfer data
	#Since floats and registers can only convert and send data through memory, we need to do this inorder to compare and calculate values.
	addi $sp, $sp, -16
	mtc1 %hitx, $f0		#move v0 to f0
	mtc1 %hity, $f1		#move v1 to f1
	#Convert the word integers to floats
	cvt.s.w $f0, $f0	
	cvt.s.w $f1, $f1	
	swc1 $f0, 0($sp)	
	swc1 $f1, 4($sp)

#Load the hit address
	la $t0, AcornLocation	#Pointer to the locations
	li $t1, 0		#Keeper for the index	
	
	find_collided_Acorn_Loop:	
	lw $t2, 0($t0)			
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 11
	li $a0, '\n'
	syscall
	beqz $t2, skipCheck	#Check if the acorn is in play or not

		addi $sp, $sp, -4
		sw $t0, 0($sp)
		decode_position($t2) 	#Get the virtual x and y coordinates
		lw $t0, 0($sp)
		addi $sp, $sp, 4
		
		mtc1 $v0, $f0		#move v0 to f0
		mtc1 $v1, $f1		#move v1 to f1
	
		#Convert the word integers to floats
		cvt.s.w $f0, $f0	
		cvt.s.w $f1, $f1	
	
		#Store them into the stack
		swc1 $f0, 8($sp)
		swc1 $f1, 12($sp)
		
		#Load the address of the stack
		la $a0, 0($sp)
		la $a1, 4($sp)
		la $a2, 8($sp)
		la $a3, 12($sp)
		#Calculate the distance between the hit and the selected acorn
		Distance($a0,$a1,$a2,$a3)
	
		lw $t2, result
		lw $t3, ClosestAcorn
		#Check if it is higher or lower
		bge $t2, $t3, noSwap
			sw $t2, ClosestAcorn	#store the distance for the next comparison
			sw $t1, ClosestAcorn+4	#store the index
		noSwap:

		skipCheck:
		addi $t0, $t0, 4	#increment the pointer
		addi $t1, $t1, 1	#Decrement the counter

	bne $t1, MAX_ACORNS, find_collided_Acorn_Loop
	addi $sp, $sp, 16
	#Check if we have actually got an acorn or not
	lw $t3, ClosestAcorn
	bnez $t3, SkipError
		li $v0, -1
		j find_acorn_conti
	SkipError:
		lw $v0, ClosestAcorn+4
	find_acorn_conti:	
	#Pop the stack to return the registers used
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	addi $sp, $sp, 16
	#Returns the index of the closeest Acorn
	
.end_macro

	
