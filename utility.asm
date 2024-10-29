.data
    # Constants for squared differences
    square_x: .float 0.0
    square_y: .float 0.0
    result: .word 0
    resultf: .float 0.0
    DistanceTestValues: .float 1.0, 1.0, 100, 100.0
    
#Inputs have to the the ADDRESS of the values
.macro Distance(%x1, %y1, %x2, %y2)
        
        # Calculate squared difference for x: (x2 - x1)^2
        l.s $f4, 0(%x2)    	# Load x2 into $f4
        l.s $f5, 0(%x1)    	# Load x1 into $f5
        sub.s $f4, $f4, $f5 	# Calculate x2 - x1
        mul.s $f4, $f4, $f4 	# Square the result
        s.s $f4, square_x  	# Store the result in square_x
        
        # Calculate squared difference for y: (y2 - y1)^2
        l.s $f4, 0(%y2)    	# Load y2 into $f4
        l.s $f5, 0(%y1)    	# Load y1 into $f5
        sub.s $f4, $f4, $f5	# Calculate y2 - y1
        mul.s $f4, $f4, $f4 	# Square the result
        s.s $f4, square_y  	# Store the result in square_y
        
        # Calculate sum of squared differences
        l.s $f4, square_x  	# Load squared difference for x into $f4
        l.s $f5, square_y  	# Load squared difference for y into $f5
        add.s $f6, $f4, $f5 	# Add both squared differences
        
        # Calculate square root of the sum (final distance)
        sqrt.s $f12, $f6    	# Calculate square root
        
        swc1 $f12, resultf	# Store the resultant distance in result float
        cvt.w.s $f12, $f12	# Convert the float to an integer
        swc1 $f12, result	# Store converted integer into result
        
.end_macro
.text
#la $a0, DistanceTestValues
#la $a1, DistanceTestValues + 4
#la $a2, DistanceTestValues + 8
#la $a3, DistanceTestValues + 12
#Distance($a0,$a1,$a2,$a3)
#li $v0, 1
#lw $a0, result
#syscall
