#This file is used to draw sprites, the sprite color data is stored as static data.

.eqv DISPLAY_ADDRESS 0x10040000	#DISPLAY BASE ADDRESS
.eqv WIDTH 64			#THE INTENDED EFFECTIVE Width OF THE SCREEN
.eqv HEIGHT 128			#THE INTENDED EFFECTIVE HEIGHT OF THE SCREEN
.eqv WORD_SIZE 4
.eqv WIDTH_BYTE_SIZE 256

.data
	#we are going to have each sprite contain meta data about their width and height, 
	#first two words are going to be width and height respectively
	#w:7 h:7
	ACORN_SPRITE:		.word  	7, 7, 0, 0, 0x043c1e00, 0x043c1e00, 0x043c1e00, 0, 0, 0x0, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0x046f3800, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc4f00, 0x04bc4f00, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc4f00, 0x04bc4f00, 0, 0x04bc5f00, 0x04bc5f00, 0x04bc5f00, 0x04bc4f00, 0x04bc4f00, 0, 0, 0, 0x04bc5f00, 0x04bc4f00, 0x04bc4f00, 0, 0
	#h:5 w:9
	LEFT_CAR_SPRITE:	.word  	9, 5, 0, 0, 0x02aaaaaa, 0x02aaaaaa, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0, 0,0, 0, 0x02aaaaaa, 0x02aaaaaa, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0, 0,0x02ffce00, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02df2d20,
				0x029fc4ee, 0x02221122, 0x02221122, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02221122, 0x02221122, 0x029fc4ee,
				0, 0x02221122,, 0x02221122, 0, 0, 0, 0x02221122, 0x02221122, 0
	#h:5 w:9
	RIGHT_CAR_SPRITE:	.word   9, 5, 0, 0, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02aaaaaa, 0x02aaaaaa, 0, 0,
				0, 0, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02aaaaaa, 0x02aaaaaa, 0, 0,
				0x02df2d20, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02ffce00,
				0x029fc4ee,0x02221122, 0x02221122, 0x029fc4ee, 0x029fc4ee, 0x029fc4ee, 0x02221122, 0x02221122, 0x029fc4ee,
				0, 0x02221122,, 0x02221122, 0, 0, 0, 0x02221122, 0x02221122, 0
	#w:9 h:6
	LEFT_PLAYER_SPRITE:	.word  	9, 6, 0, 0, 0, 0, 0, 0, 0, 0x01660000, 0x01660000, 0, 0, 0, 0x01660000, 0, 0, 0, 0x01660000, 0, 0, 0x01aaaaaa, 0x01660000, 0, 0, 0, 0, 0, 0x01660000, 0x01221122, 0x01660000, 0x01660000, 0x01660000, 0x01392014, 0x01392014, 0x01392014, 0x01660000, 0x01660000, 0, 0, 0, 0x01392014, 0x01b45606, 0x01b45606, 0x01392014, 0, 0, 0, 0, 0x01392014, 0, 0, 0x01392014, 0, 0, 0
	#w:9 h:6
	RIGHT_PLAYER_SPRITE:	.word  9, 6, 0x01660000, 0x01660000, 0, 0, 0, 0, 0, 0, 0, 0x01660000, 0, 0, 0, 0, 0x01660000, 0, 0, 0, 0x01660000, 0, 0, 0, 0, 0, 0x01660000, 0x01aaaaaa, 0, 0x01660000, 0x01660000, 0x01392014, 0x01392014, 0x01392014, 0x01660000, 0x01660000, 0x01660000, 0x01221122, 0, 0, 0x01392014, 0x01b45606, 0x01b45606, 0x01392014, 0, 0, 0, 0, 0, 0, 0x01392014, 0, 0, 0x01392014, 0, 0
#memory_address: the location that the top left is going to go

.macro Draw_Sprite (%memory_address, %sprite)
    addi $sp, $sp, -24
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $t5, 20($sp)
    
    lw $t0, 0(%sprite) # Pixel width of sprite, col
    move $t5, $t0
    lw $t1, 4(%sprite) # Pixel height of sprite, row
   # move $t6, $t1
    mul $t4, $t0, WORD_SIZE	#This is used to subtract the pointer to reset the width later when we move to the next row
    addi  %sprite,  %sprite, 8	#Move to the next two words since the first two contain metadata
    # Loop through each row
    Draw_Sprite_Loop:
        beq $t1, 0, done_sprite  # Exit the loop after done drawing

	#Print on display 
        Print_Sprite:
            beq $t0, 0, Draw_Sprite_Next_Row 	# If end of row, move on to the next row. 
            lw $t2, 0(%sprite)   			# Load the current word (color) from the ACORN_MASK
            
            beqz $t2, Draw_Sprite_Next_Pixel	#Checks if its a "transparent" color 
            
            lb $t3, 3(%memory_address)	#Load the layer byte
            sll $t3, $t3, 24	#Sets the byte to length word
            or $t2, $t2, $t3	#Combine the color with the layer
            
            sw $t2, 0(%memory_address) 		# Print to display 
            
            Draw_Sprite_Next_Pixel:
           	addi %sprite, %sprite, 4		# Move to the next color
            	addi %memory_address, %memory_address, 4   		# Move to the next Pixel
            	subi $t0, $t0, 1		# col -1 
            	j Print_Sprite
            
        Draw_Sprite_Next_Row:
        	move $t0, $t5 	 # Reset width 
        	
       		#Next row
        	addi %memory_address, %memory_address, WIDTH_BYTE_SIZE
        	sub %memory_address, %memory_address, $t4
        
        	# row -1 
        	subi $t1, $t1, 1
        	j Draw_Sprite_Loop
	
	done_sprite:
	
   	lw $t0, 0($sp)
    	lw $t1, 4($sp)
    	lw $t2, 8($sp)
   	lw $t3, 12($sp)
    	lw $t4, 16($sp)
    	lw $t5, 20($sp)
	addi $sp, $sp, 24
.end_macro
#This one has a layer to ignore
.macro Draw_Sprite (%memory_address, %sprite, %layer_to_ignore)
    addi $sp, $sp, -28
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t4, 16($sp)
    sw $t5, 20($sp)
    sw $t6, 24($sp)
    
    lw $t0, 0(%sprite) # Pixel width of sprite, col
    move $t5, $t0
    lw $t1, 4(%sprite) # Pixel height of sprite, row
   # move $t6, $t1
    mul $t4, $t0, WORD_SIZE
    addi  %sprite,  %sprite, 8	#Move to the next two words since the first two contain metadata
    # Loop through each row
    Draw_Sprite_Loop:
        beq $t1, 0, done_sprite  # Exit the loop after done drawing

	#Print on display 
        Print_Sprite:
            beq $t0, 0, Draw_Sprite_Next_Row  # If end of row, move on to the next row. 
            lw $t2, 0(%sprite)   		# Load the current word (color) from the ACORN_MASK
            
            beqz $t2, Draw_Sprite_Next_Pixel	#Check if it is a "transparent" pixel or not
            
            lb $t3, 3(%memory_address)		#Load the layer byte
            and $t6, $t3, %layer_to_ignore	#Mask the byte so that we get a corresponding layer
            bnez $t6, Draw_Sprite_Next_Pixel	#Skipping the pixel drawing if it is on a layer we don't want
            sll $t3, $t3, 24			#Sets the layer byte to length of a word
            or $t2, $t2, $t3			#Combine the color with the layer
            
            sw $t2, 0(%memory_address) 		# Print to display 
            
            Draw_Sprite_Next_Pixel:
           	addi %sprite, %sprite, 4	# Move to the next color
            	addi %memory_address, %memory_address, 4   		# Move to the next Pixel
            	subi $t0, $t0, 1		# col -1 
            	j Print_Sprite
            
        Draw_Sprite_Next_Row:
        	move $t0, $t5 	 # Reset width 
        	
       		#Next row
        	addi %memory_address, %memory_address, WIDTH_BYTE_SIZE
        	sub %memory_address, %memory_address, $t4
        
        	# row -1 
        	subi $t1, $t1, 1
        	j Draw_Sprite_Loop
	
	done_sprite:
	lw $t0, 0($sp)
    	lw $t1, 4($sp)
    	lw $t2, 8($sp)
   	lw $t3, 12($sp)
    	lw $t4, 16($sp)
    	lw $t5, 20($sp)
    	lw $t6, 24($sp)
	addi $sp, $sp, 28
.end_macro
#test:

 #li $a0, 0x10040000
 #li $a1 8192
 #li $a2, 0x00ffffff
 #li $a3, 0x04
#SetToN($a0, $a1, $a2, $a3)
#la $a0, 0x10040000
#li $a1, 9
#li $a2, 12
#la $a3, LEFT_PLAYER_MASK
#Draw_Sprite($a0,$a1,$a2,$a3)
