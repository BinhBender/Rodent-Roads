#Project by Binh, Katrina, Kaleb
#Debugged by Riley Stone 

#Do not change
.eqv DISPLAY_ADDRESS 0x10040000	#DISPLAY BASE ADDRESS
.eqv KEYBOARD_ADDRESS 0xFFFF0000#KEYBOARD

.eqv START_DISPLAY 0x10040800	#THE STARTING POSITION OF THE FIRST PLACE WE NEED TO ACTUALLY RENDER (SO 10040000 + WHATEVER 512 IS IN HEX)
.eqv WIDTH 64			#HOW LARGE EACH ROW IS
.eqv WIDTHBYTE 256		#HOW LARGE EACH ROW IS IN BYTES
.eqv HEIGHT 128			#THE INTENDED EFFECTIVE HEIGHT OF THE SCREEN

.eqv WORD_SIZE 		4	#BYTE SIZE OF EACH WORD
.eqv MAX_LANES_REAL 	14	#TOTAL LANES INCLUDING THE FIRST AND LAST LANE (BOTH OF WHICH IS FIXED TO BE GRASS)
.eqv MAX_LANES 		12	#TOTAL PLAYABLE LANES
.eqv LANE_PIXEL_SIZE 	8	#Height of each lane
.eqv NUM_OF_PIXELS_PER_LANE 512	#LANE_PIXEL_SIZE * 64 
.eqv NUM_OF_PIXELS_PER_GRASS 384#NUM_OF_PIXELS_PER_LANE - 2(WIDTH) = 512 - 128 
.eqv NUM_OF_PIXELS_PER_ROAD 512

#First 4 bytes will be for entities
.eqv PLAYER_MASK 0x1 # 0001
.eqv CAR_MASK 	 0x2 # 0010
.eqv ACORN_MASK  0x4 # 0100
.eqv PLAYER_ACORN_MASK 	0x5 # 0101
.eqv PLAYER_CAR_MASK	0x3 # 0011
.eqv ALL_MASK 	 0x7 # 1111
.eqv PLAYER_AND_CAR_MASK 	0x3	# 0011
.eqv PLAYER_AND_ACORN_MASK 	0x5	# 0101

.eqv PLAYER_MASK_WORD 	0x01000000 # 00000001 000...00
.eqv CAR_MASK_WORD 	0x02000000 # 00000010 000...00
.eqv ACORN_MASK_WORD  	0x04000000 # 00000100 000...00
.eqv ALL_MASK_WORD 	0x07000000 # 00001111 000...00
#.eqv extraThing 0b0001000

#last 4 bits will be for structures
.eqv ROAD_LAYER  	0x10
.eqv GRASS_LAYER 	0x20
.eqv EDGE_LAYER		0x40

.eqv ROAD_LAYER_WORD 	0x10000000
.eqv GRASS_LAYER_WORD 	0x20000000

.eqv SPEED_BOUND 7 #has to be a number
.eqv SPEED_BOUND_FIX -3	#has to be a number 1/2 of SPEED_BOUND rounded down

.eqv PLAYER_WIDTH 9
.eqv PLAYER_HEIGHT 6
.eqv CAR_WIDTH 9

.eqv TOP_LIMIT 8
.eqv BOTTOM_LIMIT 114
.eqv RIGHT_LIMIT 55
.eqv LEFT_LIMIT  0

.eqv UP 	0x1
.eqv DOWN 	0x2
.eqv RIGHT 	0X4
.eqv LEFT 	0x8

.eqv MAX_CARS	64
#Colors for objects
.eqv ROAD_COLOR 	0x109E9FA5
.eqv GRASS_COLOR 	0x20009A17
.eqv CURB_COLOR		0x40808080

#Each line will have 2 bytes dedicated to it
#	and this is how the data will be laid out
.eqv LANE_DIR_RIGHT 	0x1
.eqv LANE_DIR_LEFT 	0x0
.eqv SPAWN_LOCATION 	0x1004737c

.eqv ERROR -1
#Extra files
.include "DrawSprites.asm"
.include "Cars.asm"
.include "Acorn.asm"

.globl main
.data	
	#message ends at 30
	deathMessage: .asciiz "You got hit by a car :( \nScore:          "
	#Random Game Data
	Score: .word 0
	PlayerPosition: .space 8
	#So this will be the address of the start of each lane seperated by HEIGHT_OF_LANE * WORD_ZIZE * WIDTH bytes.
	LaneLocation: 	.word 0x10040000, 0x10040800, 0x10041000, 0x10041800, 0x10042000, 0x10042800, 0x10043000, 0x10043800, 0x10044000, 0x10044800, 0x10045000, 0x10045800, 0x10046000, 0x10046800, 0x10047000, 0x10047800
	Difficulty: 	.word 2	#Difficulty is the chance that a road will spawn with lanes / x
	ScoreFile: 	.asciiz "score.txt"
	outputBuffer:	.space 64
	digitBuffer:	.space 32
	digitBuffer2:	.space 32
.text

j main
.macro generate_random 
	li $v0, 41
	li $a0, 0
	syscall
	move $v0, $a0
.end_macro
#The upper with syscall #42 does not include the upper
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

.macro render_acorns

	#for acorn in acornLocation
	#	draw_sprite(acorn)
	li $t0, MAX_ACORNS	#Number of max acornsv h
	la $t1, AcornLocation	#Pointer for the generated locations of acorns
	render_acorns_loop:
	addi $t0, $t0, -1	
	
	addi $sp, $sp, -12
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	
	lw $a0, 0($t1)		#Load the location of the acorns
	la $a1, ACORN_SPRITE
	beqz $a0, SkipRender	#This checks if there is an acorn there or not
	
		Draw_Sprite($a0,$a1, PLAYER_ACORN_MASK)
	
	SkipRender:		
	#Pop stack
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	#Increment the location pointer
	addi $t1, $t1, WORD_SIZE
	bnez $t0, render_acorns_loop
	
.end_macro
#HELPER FUNCTION
#a0 = address of memory
#a1 = size of array
#a2 = number to set
#a3 = layer to ignore
.macro SetToN (%base_address, %number_of_elements, %num_to_set, %layer)
	SetToN_LoopBegin:
	beqz %number_of_elements, EndSetToN_LoopEnd
	#Check for layer
	move $t1, %base_address
	#Because we are looking at the last byte, because of little endian, we have to add 3 so that we're pointing at the forth one
	#lb $t0, 3($t1)		#Get the byte data
	#and $t0, $t0, %layer	#Mask the avaliable bytes
	#bnez $t0, SkipDraw	#Check if it is 0, which will happen when its not there
		#inject value of a2 into address at a0
		sw %num_to_set, 0(%base_address)	
	SkipDraw:
	#move to next word
	addi %base_address, %base_address, 4
	#Decrement
	addi %number_of_elements, %number_of_elements, -1
	j SetToN_LoopBegin
	EndSetToN_LoopEnd:
	#Return ending address
	move $v0, %base_address
	
.end_macro	
#This will remove a specified layer at an address
#and if multiple layers are applied, it will remove ONLY the ones avaliable
.macro remove_layer_Process(%address, %pixel, %layer_mask)
	add $t5, $0,  %pixel		#Move to t5 for temp storage
	andi $t6, $t5, %layer_mask	#And this byte to get rid of anything we want to clear in case we input 2 bits or want to remove 2 bits
	xor $t6, $t5, $t6		#Finds the difference (basically just removes the layer bit)
	#if the pixel has grass mask, redraw it as green
	#if the pixel has road mask, redraw it as road color (gray)
	sw $t6, 0(%address)
	
	
.end_macro
#This function loops over every player pixel
.macro Entity_Update(%address_position, %width, %height, %layer)
	addi $sp, $sp, -20
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	
	add $t0, $0, %address_position
	add $t1, $0, %width			#Keep Temp register as counter for width
	add $t2, $0, $t0			#Pointer for the address
	add $t3, $0, %height			#Counter for height
	delete_past_y_loop:
	delete_past_x_loop:

		lw $t4, 0($t2)	#Load pixel data at $t2
		
		remove_layer_Process($t2, $t4, %layer)	#Removes x layer at this location
		
		addi $t2, $t2, WORD_SIZE		#Move pointer to the next pixel
		addi $t1, $t1, -1			#Decrement the register
		
	bnez $t1, delete_past_x_loop			#Check if counter is zero
	
	addi $t3, $t3, -1				#Decrement the height
	addi $t0, $t0, WIDTHBYTE			#Increment the y by moving to the next row
	
	add $t2, $0, $t0				#Advance pointer to the next row 
	add $t1, $0, %width				#Reset $t1 to the width
	bnez $t3, delete_past_y_loop			#Loop if we're not done with the rows
	
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	addi $sp, $sp, 20
#Note: 
#	This is part of the rendering stage
#	Character has to move first
.end_macro
#Checks if the player is above a certain y value and finishes
.macro Check_FinishLine (%y)
	bgt %y, 8, FinishLineNotReached
		j LevelStart_Generate
	FinishLineNotReached:
.end_macro

#Uses $t0 - $t3
#t0 for what type of lane we're looking at
#t1 is the byte position of each lane
render_background:
	#For each road lane
		#Draw on any pixels that don't have the road_mask or acorn_mask or player_mask
		#Maybe add a conditional so that the edges are different colors
	#Then draw on the grass lane that the player is on (since nothing else could appear on the grass lane other than the player)
		#We'll keep track of what lane the player is on
	
	la $t0, LaneData
	addi $t0, $t0, 3
	#counter
	li $t3, MAX_LANES_REAL
	#Load the address of the layer
	la $t1, LaneLocation + 4
	render_background_loop:
	
		#Move the address into the first arg
		lw $a0, 0($t1)
		#Load the size of each pixel per lane
		li $a1, NUM_OF_PIXELS_PER_LANE	
		#We want to avoid drawing on any entities so we ignore all of it 0b0111
		li $a3, ALL_MASK
		#Get the type of lane and inject the corresponding color into that lane
		lb $t2, 0($t0)
		#Check for road layer
		bne $t2, ROAD_LAYER, drawingGrassLayer
			li $a2, ROAD_COLOR
		j render_lane_conti	
		#Check for grass layer
		drawingGrassLayer:
		bne $t2, GRASS_LAYER, render_lane_conti
			li $a2, GRASS_COLOR
		j render_lane_conti
		
		render_lane_conti:
		#Push into the stack (SetToN only uses $t0 but we're pushing 
		# 	everything in case we ever want to do anything else)
		addi $sp, $sp, -16
		sw $t0, 0($sp)
		sw $t1, 4($sp)
		sw $t2, 8($sp)
		sw $t3, 12($sp)
		SetToN($a0, $a1, $a2, $a3)
	
		#pop the stack
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		lw $t3, 12($sp)
		addi $sp, $sp, 16
		
		#Increment the pointer
		addi $t0, $t0, 3
		addi $t1, $t1, 4	#Move to next address
		addi $t3, $t3, -1
	bnez $t3, render_background_loop
	
	jr $ra
# 	=========# 	=========# 	=========# 	=========
#Used $t0 - $t4
generate_lanes:
	#Push $ra to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	

	#Load the address for the lane array
	#	The first and last lanes should be 0 since they hold the menu
	la $t0, LaneData + 6	#The second lane will always be a grass
	#Get number of max lanes
	li $t1, MAX_LANES_REAL
	lw $t4, Difficulty
	
	generate_level_Loop:
		subi $t1, $t1, 1
		#Get Determine if a lane should be a grass or road
		generate_random($t4)
		bnez $v0, NoGrass
			#set grass here
			li $t2, GRASS_LAYER
			j generateLevelConti
		NoGrass: 
			#set road here
			li $t2, ROAD_LAYER
	generateLevelConti:
	
	#Load the lane mask into the thing
	sb $t2, 0($t0)
	####################
	#Randomize the speed
	repeat_random_speed:
	generate_random(SPEED_BOUND)
	#We want the speed to be -3 < s < 3 but MIPS rng doesn't do negatives so we 
	#	Do the bounds as 0 < s < 6 and subtract 3
	addi $v0, $v0, SPEED_BOUND_FIX
	
	beqz $v0, repeat_random_speed
	sb $v0, 1($t0)
	#move $a0, $v0
	#println($a0)---- debug
	#####################
	#Increment the pointer
	addi $t0, $t0, 3	#Lane data is 3 bytes per element
	bnez $t1, generate_level_Loop 
	
	#The top and bottom lanes ALWAYS have to be grass lanes
	li $t2, GRASS_LAYER
	sb $t2, LaneData + 3	#Second lane is grass
	sb $t2, LaneData + 42	#Second last lane is grass
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra

#This is a debug function used to print out the lanes generated
.macro printLanes()
	addi $sp, $sp, -16
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $v0, 8($sp)
	sw $a0, 12($sp)
	
	li $t0, 16
	la $t1, LaneData
	printLanesLoop:
#for i in lanes, print lanes
		lb $t2, 0($t1)
		beq $t2, GRASS_LAYER, GrassPrint
		li $v0, 11
		li $a0, 'R'
		syscall
		j Conti
		GrassPrint:
		beqz $t2, Null
		li $v0, 11
		li $a0, 'G'
		syscall
		j Conti
		Null:
		li $v0, 11
		li $a0, 'B'
		syscall
		Conti:
		
		addi $t1, $t1, 3
		addi $t0, $t0, -1
	bnez $t0, printLanesLoop
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $v0, 8($sp)
	lw $a0, 12($sp)
	addi $sp, $sp, 16
.end_macro
#Takes keyboard input
PollKeyboard:
	#Poll
	li $t0, KEYBOARD_ADDRESS
	#check first bit
	lw $t1, 0($t0)
	andi $t1, $t1, 1
	#load data
	#Check if we have received anything
	beqz $t1, NoKeyInput
	
	#increment to the data
	lw $t1, 4($t0)
	#return
	move $v0, $t1
	jr $ra
	#Skip the loading of the char byte if there is nothing
	NoKeyInput:
	li $v0, ERROR
	jr $ra

.macro decode_position (%memory_address)
	add $t0, $0, %memory_address	#Get Player position
	
	subi $t0, $t0, DISPLAY_ADDRESS	#Removes the display address
	divu $v1 , $t0, WIDTHBYTE	#Return the quotient which is the y
	mfhi $v0			#Return a remainder which is the x
	divu $v0, $v0, 4	#Divide by 4 since the REM is still in the word form
				
	
.end_macro

#Checks if the player has gone over the bounds in virtual coordinates
#	Returns the x and y at the bounds if they have gone over
.macro Check_Border (%x, %y, %speed)

	#Right Border
	blt %x, RIGHT_LIMIT, CheckLeftBorder
	add %x, $0, RIGHT_LIMIT
	CheckLeftBorder:
	#Left Border
	bgt %x, LEFT_LIMIT, CheckDownBorder
	add %x, $0, LEFT_LIMIT
	CheckDownBorder:
	
	#Bottom
	blt %y, BOTTOM_LIMIT, CheckUpBorder
	add %y, $0, BOTTOM_LIMIT
	CheckUpBorder:
	#	Top Border
	bgt %y, TOP_LIMIT, Border_Check_Done
	add %y, $0, TOP_LIMIT
	Border_Check_Done:
	##
	move $v0, %x
	move $v1, %y
	
.end_macro

#uses t0 - t5
#This redraws the background
.macro EraseEntity(%pos_to_redraw, %width, %height, %layer)
	addi $sp, $sp, -24
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	
	add $t0, $0, %pos_to_redraw		#Get the previous position
	add $t1, $0, %width			#Keep Temp register as counter for width
	add $t2, $0, $t0			#Pointer for the address
	add $t3, $0, %height			#Counter for height
	delete_past_y_loop:
	delete_past_x_loop:
		lb $t5, 3($t2)			#Get the layer byte
		and $t4, $t5, %layer		#Mask the layer byte to blacklist the layer we don't want to draw on
		bnez $t4, EraseEntityConti		#IF there is NOT a match, redraw the thing.
		and $t4, $t5, PLAYER_MASK
		bnez $t4, EraseEntityConti
			and $t4, $t5, GRASS_LAYER
			beqz $t4, EE_DRAW_ROAD
				li $t4, GRASS_COLOR
				sw $t4, 0($t2)
				j EraseEntityConti
			EE_DRAW_ROAD:
			and $t4, $t5, ROAD_LAYER
			beqz $t4, EraseEntityConti
				li $t4, ROAD_COLOR
				sw $t4, 0($t2)
		EraseEntityConti:
		addi $t2, $t2, WORD_SIZE	#Move pointer to the next pixel
		addi $t1, $t1, -1		#Decrement the register
		
	bnez $t1, delete_past_x_loop		#Check if counter is zero
	
	addi $t3, $t3, -1			#Decrement the height
	addi $t0, $t0, WIDTHBYTE		#Increment the y by moving to the next row
	
	add $t2, $0, $t0			#Advance pointer to the next row 
	add $t1, $0, %width			#Reset $t1 to the width
	bnez $t3, delete_past_y_loop		#Loop if we're not done with the rows

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	addi $sp, $sp, 24
.end_macro

.macro pick_up_sound
addi $sp, $sp, -4
sw $v0, 0($sp)
	li $v0, 31
	li $a0, 66	#pitch
	li $a1, 200	#duration
	li $a2, 120	#instrument
	li $a3, 127	#volume
	syscall
lw $v0, 0($sp)
addi $sp, $sp, 4
.end_macro
.macro Check_Entity_Collision(%data_of_pixel)
	add $t0, $0, %data_of_pixel 	#Move the pixel into $t0
	#Saving $t0
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	#Check for the player	(Only check the collision if it is a player pixel
	andi $t0, $t0, PLAYER_MASK_WORD
	beqz $t0, CheckDone
	
	lw $t0, 0($sp)
	#Check Acorn
	andi $t0, $t0, ACORN_MASK_WORD 	#Mask the layer
	beqz $t0, CheckCar	
		
		
		#Add 1 to the score
		lw $t1, Score
		addi $t1, $t1, 1
		sw $t1, Score
		
		#######
		#####Delete the acorn####
		lw $t1, PlayerPosition
		decode_position($t1)	#
		
		find_collided_Acorn($v0, $v1)
		
		beq $v0, -1, skipAcornDelete	#This means that it didn't find an acorn (only happens when you collide with the last one)
			#Zero out the acorn at $v0 so that renderer will not render it
			#Entity_Update
			move $t0, $v0 		#Get the index of the closest acorn
			mul $t0, $t0, 4	
			la $t1, AcornLocation	
			add $t0, $t0, $t1	#The memory address of the location to remove
			
			#Next we want to remove the layer
			lw $a0, 0($t0)		#Load the actual location of the acorn
			
			#save t0 into the stack
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			Entity_Update($a0, 7, 7, ACORN_MASK_WORD)
			EraseEntity($a0, 7, 7, 5)	#Removes the acorn pixels
			lw $t0, 0($sp)
			addi $sp, $sp, 4
			pick_up_sound
			sw $0, 0($t0)		#zero out the acorn
			move $v0, $0
		skipAcornDelete:

	#Check Car
	CheckCar:
	lw $t0, 0($sp)
	andi $t0, $t0, CAR_MASK_WORD
	beqz $t0, CheckDone
		#Die!
		addi $sp, $sp, 4
		j saveScore
		#replace syscall with some death screen
	CheckDone:
	
	addi $sp, $sp, 4
.end_macro
game_checks:
	#Check if the player is at the finish line or not
	lw $t0, PlayerPosition
	decode_position($t0)
	move $a0, $v1	#Get the y 
	Check_FinishLine($a0)
	#Check if the player is at the finish line or not
	
	lw  $t0, PlayerPosition
	add $t1, $0, PLAYER_WIDTH			#Keep Temp register as counter for width
	add $t2, $0, $t0				#Pointer for the address
	add $t3, $0, PLAYER_HEIGHT			#Counter for height
	delete_past_y_loop:
	delete_past_x_loop:

		lw $a0, 0($t2)				#Load pixel data at $t2
		addi $sp, $sp, -16
		sw $t0, 0($sp)
		sw $t1, 4($sp)
		sw $t2, 8($sp)
		sw $t3, 12($sp)
		
		Check_Entity_Collision($a0)	#Loops through every pixel
		
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		lw $t3, 12($sp)
		addi $sp, $sp, 16
		
		addi $t2, $t2, WORD_SIZE		#Move pointer to the next pixel
		addi $t1, $t1, -1			#Decrement the register
		bnez $v0, end
			jr $ra
		end:
	bnez $t1, delete_past_x_loop			#Check if counter is zero
	
	addi $t3, $t3, -1				#Decrement the height
	addi $t0, $t0, WIDTHBYTE			#Increment the y by moving to the next row
	
	add $t2, $0, $t0				#Advance pointer to the next row 
	add $t1, $0, PLAYER_WIDTH			#Reset $t1 to the width
	bnez $t3, delete_past_y_loop			#Loop if we're not done with the rows
	jr $ra
.macro determine_new_position (%x, %y, %speed, %direction)
	lw $t0, PlayerPosition
	sw $t0, PlayerPosition+4
	bne %direction, UP, CheckDown
		sub %y, %y, %speed
	j DoneCheck
	
	CheckDown:
	bne %direction, DOWN, CheckRight
		add %y, %y, %speed
	j DoneCheck
	
	CheckRight:
	bne %direction, RIGHT, CheckLeft
		add  %x, %x, %speed
	j DoneCheck
	
	CheckLeft:
	bne %direction, LEFT, DoneCheck
		sub %x, %x, %speed
	DoneCheck:
	
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
.macro render_cars
	#For car in Car_Data
	#	if speed != 0{
	#		if speed > 0 //Check if it is positive
	#			drawSprite(car.position, rightCar)
	#		else 
	#			drawSprite(car.position, leftCar)
	#		Erase Previous position
	#	}
	#
	lw $t0, CAR_AMOUNT	#Counter
	la $t1, CAR_DATA	#Car Pointer
	
	render_cars_loop:
		#if speed != 0
		lw $t2, 8($t1)
		beqz $t2, NoActiveCar
			#Remove the layer
			lw $a0, 4($t1)
			Entity_Update($a0, 9, 6, CAR_MASK_WORD)

			
			bgtz $t2, DrawRight
				la $a1, LEFT_CAR_SPRITE
				move $t7, $a1
				j DrawConti
			DrawRight:
				la $a1, RIGHT_CAR_SPRITE
				move $t7, $a1
			DrawConti:
			#Draw the sprite
			lw $a0, 0($t1)		#Get the position
			Draw_Sprite($a0, $a1)	
			
			#Erase the previous position
			lw $a0, 4($t1)		#Get the previous position
			EraseEntity($a0, 9, 6, CAR_MASK)

			j render_car_conti
		NoActiveCar:
		#Check for if the previous position is not 0
		#if it is, erase it
		#This check is for if the car has been disabled (prev pos = 0) but is still on screen
		lw $a0, 4($t1)
		beqz $a0, NoDeleteDeadCar
			Entity_Update($a0, 9, 6, CAR_MASK_WORD)
			lw $a0, 4($t1)
			EraseEntity($a0, 9, 6, CAR_MASK)
			sw $0 4($t1)	#Zeros out the previous position (empty car slot)
		NoDeleteDeadCar:
	render_car_conti:
	addi $t0, $t0, -1
	addi $t1, $t1, 12
	bnez $t0, render_cars_loop
	
.end_macro

Direction:
#Skip these checks if there was no input
	bne $a0, ERROR, DIRCheckW
	jr $ra
	#Checking each key
	DIRCheckW:
	bne $a0, 'w', DIRCheckA
	li $v0, UP
	jr $ra
	DIRCheckA:
	
	bne $a0, 'a', DIRCheckD
	li $v0, LEFT
	jr $ra
	DIRCheckD:
		
	bne $a0, 'd', DIRCheckS
	li $v0, RIGHT
	jr $ra
	DIRCheckS:
		
	bne $a0, 's', DIRCheckDone
	li $v0, DOWN
	jr $ra
	#This means that the input did not match the avaliable inputs
	DIRCheckDone:
	li $v0, ERROR
	jr $ra

.macro move_player(%key, %speed)
	add $t1, $0, %key
	add $t2, $0, %speed

	lw $t0, PlayerPosition
	# We need to convert it back to virtual coordinates 
	#since our checks are based off of them
	decode_position($t0)	

	move $a0, $v0	#returning x
	move $a1, $v1	#returning y
	move $a2, $t2	#Speed
	move $a3, $t1	#key
	#Given the speed, key, and position, it will return a new x and y
	determine_new_position($a0, $a1, $a2, $a3)
	
	#Then check if we are in a border or not
	move $a2, $t2
	Check_Border($a0, $a1, $a2)	#This returns the modified positions if or if not the player has hit the border
	move $a0, $v0
	move $a1, $v1
	calculateByteAddress($a0, $a1)
	sw $v0, PlayerPosition	#Store the new player position
	
.end_macro
	
main:
	#Start Screen
	li $s0, 6 	#Speed
	li $s1, LEFT 	#Dir
	li $s5, LEFT 	#Facing direction
	#Load Level
	
	LevelStart_Generate:
	
	#Generate the level terrain
	lw $t0, Difficulty
	addi $t0, $t0, 1
	sw $t0, Difficulty
	
	lw $t0, CAR_AMOUNT
	addi $t0, $t0, 3
	#We need to check if it is over the amount of cars we have in the buffer
	bge $t0, 64, dontUpdateCarAmount
	sw $t0, CAR_AMOUNT	
	dontUpdateCarAmount:
	
	jal generate_lanes
	jal render_background
	#printLanes----Debug
	generate_Acorns	
	render_acorns	#Show acorns
	flush_cars	#Zeros out all car data
	
	
	#Draw the inital starting character
	li $a0, 27
	li $a1, 113
	calculateByteAddress($a0, $a1)
	sw $v0, PlayerPosition
	move $a0, $v0
	la $a1, LEFT_PLAYER_SPRITE
	Draw_Sprite($a0, $a1)
	
	
	
	
	Frame_Start:
	
#####  Check Keyboard Input  #####

	move $s4, $0		#Move zero out the s4 register
	jal PollKeyboard
	move $a0, $v0		#Get the returning key
	beq $a0, ERROR, NO_INPUT
		beq $a0, 'p', saveScore
		jal Direction
		move $s4, $v0	#Store the direction
	NO_INPUT:
	move $a0, $s4	#Key Input
	move $a1, $s0	#Speed
	
#####	Check Keyboard Input  #####
	move_player($a0, $a1)

##### CARS #####
	#This slows down the cars
	bne $s6, 30, skipCarMove
		Spawn_framework		#Spawn car
		move_cars		#move the virtual cars 
		render_cars		#render current cars while erasing past cars
		move $s6, $0
	skipCarMove:
	addi $s6, $s6, 1
##### CARS #####
	
	#Render
##### PLAYER START ######	
	and $t0, $s4, 12	#This is 1100 and represents left and right
				#We AND s4 (the register that holds the current position) to check if it has at least one of those directions.
	beqz $t0, no_got_left_right	#If it goes up or down, we don't change the facing direction, 
					# but if it is left or right, we change the sprite to that direction
	move $s5, $s4		
	no_got_left_right:
	
	bne $s5, LEFT, drawRight
		la $a3, LEFT_PLAYER_SPRITE
		j drawSprite
	drawRight:
		la $a3, RIGHT_PLAYER_SPRITE
	drawSprite:
	
	#load the position of the player
	lw $a0, PlayerPosition
	Draw_Sprite($a0, $a3)
	#Check if the player has moved or not
	lw $t0, PlayerPosition
	lw $t1, PlayerPosition + 4
	beq $t0, $t1, skipDrawIfNoMove
	
	#load the position of the player
	lw $a0, PlayerPosition + 4
	Entity_Update($a0, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_MASK_WORD)

	#Remove the previous player drawing
	lw $a0, PlayerPosition + 4
	li $a1, PLAYER_WIDTH	#X
	li $a2, PLAYER_HEIGHT	#Y
	li $a3, PLAYER_MASK
	
	EraseEntity($a0, $a1, $a2, $a3)
	skipDrawIfNoMove:
##### PLAYER END #####
	render_acorns()
	#Check for game stuff
	jal game_checks
	#If finishline go back up to load level
	
	j Frame_Start
	
	
	
DeathPopUp:
# $a0 = address of null-terminated string that is the message to user
#$a1 = the type of message to be displayed:
#0: error message, indicated by Error icon
#1: information message, indicated by Information icon
#2: warning message, indicated by Warning icon
#3: question message, indicated by Question icon
#other: plain message (no icon displayed)
	la $a0, deathMessage
	addi $a0, $a0, 33
	
	la $t0, digitBuffer2
	
	messageOngoing:
	lb $t1, 0($t0)	#Get the score digit from digitBuffer2
	sb $t1, 0($a0)	#Store the score digit into deathMessage
	
	addi $a0, $a0, 1
	addi $t0, $t0, 1
	bnez $t1, messageOngoing
	
	li $v0, 55
	la $a0, deathMessage
	li $a1, 2
	syscall
	jr $ra
test:
	jal generate_lanes
	jal render_background
	
	Spawn_framework
	
	j exit
reverseString:
	#for char in string
	#increment till we hit \0
	#then swap for everything in between
	la $t1, digitBuffer2
	reverse_String_Loop:
		lb $t0, 0($a0)
		sb $t0, 0($t1)
		
		addi $a0, $a0, -1
		addi $t1, $t1, 1
	bnez $t0 reverse_String_Loop
	jr $ra
saveScore:
### Save Score to File ###
	la $t1, digitBuffer
	lw $t0, Score
	#println($t0)
	sb $0, 0($t1)		#Store the null terminator
	addi $t1, $t1, 1	#Increment the one initially
	#The plan to convert the number into ascii is by walking backwards,
	#	We divide by 10 on the score every time and get the remainder
	#	Then 
	
	#
	integerToAscii:
	div $t0, $t0, 10	#Isolate the least significant number
	mfhi $t2		#Get least significant number
	addi $t2, $t2, 48	#Get its ascii representation
	sb $t2, 0($t1)		#Store it into digitBuffer
	
	addi $t1, $t1, 1	#Move to the next slot in the buffer
	bnez $t0, integerToAscii#If the quotient is 0, then that is the last digit
	move $a0, $t1
	addi $a0, $a0, -1
	jal reverseString
	
	
	li $v0 13
	la $a0 ScoreFile
	li $a1, 1
	syscall
	
	move $a0, $v0
	li $v0, 15 
	la $a1, digitBuffer2
	li $a2, 32
	syscall
	
	
	li $v0, 16
	syscall
	
	jal DeathPopUp	#Pop-up death message
### Save Score to File ###
exit:
	li $v0, 10
	syscall
