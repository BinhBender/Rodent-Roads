.eqv CAR_DATA_ARRAY_ITEM_OFFSET 12
.eqv LANE_DATA_ARRAY_ITEM_OFFSET 3
.eqv ERROR -1
.eqv CAR_WIDTH 9
.eqv CAR_X_LEFT_BOUND 0
.eqv CAR_X_RIGHT_BOUND 54 #Should be WIDTHLIMIT - length of car ==> 63 - 9

#last 4 bits will be for structures
.eqv ROAD_LAYER  	0x10
.eqv GRASS_LAYER 	0x20
.data
	CAR_DATA: .space 768 	#MAX CARS * WORD SIZE * 3(Current Position, Prev Position, Speed) ==> 64 * 4 * 3
				#First word car positoin
				#Second word car previous postion
				#Third word is speed (this wil also inherently hold direction because we will use the negative and positive)
	CAR_AMOUNT: .word 0
	#Holds the spawn locations of the cars,
	#Left column are for right direction cars
	#Right column are for left direction cars
	#Each element is 8 bytes
	CarSpawnLocation: .word 0x10040000, 0x100400D8
			.word	0x10040800, 0x100408D8
			.word	0x10041000, 0x100410D8
			.word	0x10041800, 0x100418D8
			.word	0x10042000, 0x100420D8
			.word	0x10042800, 0x100428D8
			.word	0x10043000, 0x100430D8
			.word	0x10043800, 0x100438D8
			.word	0x10044000, 0x100440D8
			.word	0x10044800, 0x100448D8
			.word	0x10045000, 0x100450D8
			.word	0x10045800, 0x100458D8
			.word	0x10046000, 0x100460D8
			.word	0x10046800, 0x100468D8
			.word	0x10047000, 0x100470D8
			.word	0x10047800, 0x100478D8
	LaneData: .space 48	#Will store the direction of the lane, speed, counter till its ready
				#First byte Type of lane
				#Second byte Speed of cars
				#Third byte counter till car is ready
					#This counter will be at the width of each car, and when it hits zero, it is able to spawn another car that this lane

	
        x: .word 0
        y: .word 0
.text

# the parameter is an immediate 
.macro generate_random_constant (%upper)
	li $v0, 42
	li $a0, 0
	addi $a1, $0, %upper
	syscall
	move $v0, $a0
	
.end_macro


	#loop through the lane once
.macro Spawn_framework
	#save registers 
	addi $sp,$sp, -24
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	#loop index,14 usable lanes
	li $t0, 14
	la $t1, LaneData		#Pointer for lanes
	la $t5, CarSpawnLocation	#Pointer for the spawn location
	
	#loop through the lanes
	SpawnOuterLoop:
	#Increment the values
	addi $t0, $t0, -1
	#println($t0)
	addi $t1, $t1, LANE_DATA_ARRAY_ITEM_OFFSET
	addi $t5, $t5, 8
	beqz $t0, EndSpawnOuterLoop
	# those two registers can be reused for direction and speed if you want    
	lb $t2, 0($t1)     	#extract roadtype   ( t2 can also be speed)
	lb $t3, 2($t1)		# and counter   ( t3 can also be direction)
	# if grass skip
	bge $t2, GRASS_LAYER, SpawnOuterLoop
	# if counter > 0 skip
	bgez $t3, UpdateCounter
		#SPAWNING CARS
		
		#println(100)
		generate_random_constant(5) # 1/3 chance to spawn
		bnez $v0, UpdateCounter
	        ### Binh's code here, decide the direction and Spawn
	        # reset counter of the lane  (assuming the car length is 9)
	        	find_empty_element()
	        #println($v0)
	        # v0 is returned as the car data address
	        	move $a2, $v0
	        	beq $a2, -1, NoAvaliableSpace
			lb $a1 1($t1) 	#get speed
	        	bgtz $a1, RIGHTDIRECTION
	        		lw $a0, 4($t5) 
	        		j make_car
	        	RIGHTDIRECTION:
	        	#Spawn on the left to go to the right
	        		lw $a0, 0($t5)
	        	make_car:
	        	move $a1, $t1
	        	initialize_car($a0, $a1, $a2)
	        #Resets the counter
	        li $t4, CAR_WIDTH
	        sb $t4, 2($t1)
		NoAvaliableSpace:
		j SpawnOuterLoop
	#move the car
	UpdateCounter:   
		lb $t2 1($t1) 	#get speed
		abs $t2, $t2	#Since speed could be negative, this is required to make sure the counter 
					#decrements properly.
		sub $t3, $t3, $t2	#Subtract from the counter 
		sb $t3, 2($t1)
	 j SpawnOuterLoop
	EndSpawnOuterLoop:
	
	#pop back from the stack
	
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	sw $t5, 20($sp)
	addi $sp,$sp, 24
.end_macro


#This resets the car data
.macro flush_cars
	#load the address of car_data into $t0 
	la $t0, CAR_DATA
	li $t1, 192	#CarData / 4
	flush_car_loop:
	#store 0 into the data of %t0
	sw $0, 0($t0)
	#move to next word
	addi $t0, $t0, 4
	#Check if it has reached the limit
	addi $t1, $t1, -1
	bnez $t1, flush_car_loop
	
.end_macro
.macro println(%num)
	addi $sp, $sp, -8
	sw $v0, 0($sp)
	sw $a0, 4($sp)
	li $v0, 1
	add $a0, $0, %num
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
	
	lw $v0, 0($sp)
	lw $a0, 4($sp)
	addi $sp, $sp, 8
.end_macro
.macro println(%num, %char)
	addi $sp, $sp, -8
	sw $v0, 0($sp)
	sw $a0, 4($sp)
	li $v0, 1
	add $a0, $0, %num
	syscall
	li $v0, 11
	li $a0, %char
	syscall
	
	lw $v0, 0($sp)
	lw $a0, 4($sp)
	addi $sp, $sp, 8
.end_macro
#Finds the car element that is empty so that we could use this to store the next car information
.macro find_empty_element()
	addi $sp,$sp, -12
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	la $t0, CAR_DATA	#Pointer for the car data array
	lw $t1, CAR_AMOUNT	#Amount of cars in the level
	
	find_empty_car:
	#if we have exceeded the limit, then boom
	beqz $t1, no_empty_cars
	lb $t2, 8($t0)	#Load the speed of the car
	#println($t0)
	#if the speed is zero, there is an vacant spot
	beqz $t2, found_empty_car
	
	addi $t0, $t0, CAR_DATA_ARRAY_ITEM_OFFSET #Increment pointer
	addi $t1, $t1, -1
	j find_empty_car
	
	found_empty_car:
		move $v0, $t0	#Returning the address of the element	
		j find_done_empty
	no_empty_cars:
		#return an error
	li $v0, ERROR
	find_done_empty:
	#println($v0)
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp,$sp, 12
.end_macro

.macro initialize_car(%position, %lane_data_element, %car_data_address)
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	#	Set car at position, set car speed to lane speed
	#		set direction to lane direction
	sw %position, 0(%car_data_address)
	sw $0, 4(%car_data_address)
	
	lb $t0, 1(%lane_data_element)
	#println($t0)
	sw $t0, 8(%car_data_address)
	lw $t0, 8(%car_data_address)
	#println($t0)
	lw $t0, 0($sp)
	addi $sp, $sp, 4
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
.macro move_cars
	lw $t0, CAR_AMOUNT	#Counter
	la $t1, CAR_DATA	#Car Pointer
	#for car in cardata
	#	if car.speed != 0
	#	
	#	 car.prevposition = car.position
	#	 car.position += speed * 4
	move_cars_loop:
	
	lb $t2, 8($t1)	#Get the speed
	#li $t2, 2
	#println($t2)
	beqz $t2,move_cars_skip	#If the speed is zero, we know that it does not exist
	#Store the current position to previous position
		lw $t3, 0($t1)	#Gets the current position
		sw $t3, 4($t1)	#Updates the previous position
	#Speed = how many pixels horizontally the car moves
	
	#Push stack
		addi $sp, $sp, -8
		sw $t0, 0($sp)
		sw $t1, 4($sp)
		decode_position($t3)		#Get the x and y virtual coordinates

		#add the x position by the speed to move the car
		add $v0, $v0, $t2	#New x position
		sw $v0, x
		sw $v1, y
		#println($a0)
		#Check for if it has hit the edge or not
		move $a0, $v0
	 	car_check_border($a0)
	 	
		lw $t1, 4($sp)			#Get the address stored in the stack so that we can insert the new value of the movement
	 	beqz $v0, CarGone
	 		lw $a0, x
	 		lw $a1, y
			calculateByteAddress($a0, $a1)	#Plug it back into the thing
			sw $v0, 0($t1)
			j CarMoveConti 	
		CarGone:
			sw $0, 0($t1)
			#sw $0, 4($t1)
			sw $0, 8($t1)
		CarMoveConti:
		#popping the stack back
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		addi $sp, $sp, 8
		
	move_cars_skip:
	addi $t0, $t0, -1 
	addi $t1, $t1, CAR_DATA_ARRAY_ITEM_OFFSET
	
	bnez $t0, move_cars_loop
	
	
.end_macro

.macro decode_position (%memory_address)
	add $t0, $0, %memory_address	#Get Player position
	
	subi $t0, $t0, DISPLAY_ADDRESS	#Removes the display address
	divu $v1 , $t0, WIDTHBYTE	#Return the quotient which is the y
	mfhi $v0			#Return a remainder which is the x
	divu $v0, $v0, 4	#Divide by 4 since the REM is still in the word form
				
	
.end_macro

#Checking for if the car has exceeded the bounds
	#No need to check for direction since the bounds account for it.
.macro car_check_border(%x)
	#if (car < leftBound && car > rightBound)
	#	car has existed the frame
	#	return true
	#else
	#	return false
	addi $sp, $sp, -8
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	move $t0, $0	#Using t0 and t1 as booleans
	move $t1, $0
	blt %x, CAR_X_LEFT_BOUND, borderCrossed
	addi $t0, $0, 1		#This means that the left bound has not been crossed
	bgt %x, CAR_X_RIGHT_BOUND, borderCrossed
	addi $t1, $0, 1 	#This means that the right bound has not been crossed
	borderCrossed:
	and $v0, $t0, $t1	#Return the bool
				# if they are both 1 (means that neither has been crossed)
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	addi $sp, $sp, 8
.end_macro
