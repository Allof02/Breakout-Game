

.data
	displayAddress:	.word	0x10008000
	
.text
	lw $t0, displayAddress	# $t0 stores the base address for display
	li $t1, 0xff0000	# $t1 stores the red colour code
	
	
	
	li $t2, 32 #t2 is the counte
	addi $t0, $t0, 640
	draw_top_border:
		beqz $t2, end_of_top_border
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, -1
		j draw_top_border
	end_of_top_border:
	
	lw $t0, displayAddress #reset t0
	addi $t0, $t0, 640 
	li $t2, 24#t2 is the counter
	draw_left_border:
		beqz $t2, end_of_left_border
		sw $t1, 0($t0)
		addi $t0, $t0, 128
		addi $t2, $t2, -1
		j draw_left_border 
	
	end_of_left_border:
	
	lw $t0, displayAddress #reset t0
	addi $t0, $t0, 764
	li $t2, 24#t2 is the counter
	draw_right_border:
	
		beqz $t2, end_of_right_border
		sw $t1, 0($t0)
		addi $t0, $t0, 128
		addi $t2, $t2, -1
		j draw_right_border 
	
	end_of_right_border:
	nop
	
	li $t1, 0xFFFF00
	draw_original_paddle:
		
		
		sw $t1, 3112($t0)   
		
		
	
	
	
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
		
	
	

	
	
		
