################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Pete Chen, 1007762832
# Student 2: Nicholas Jeremy Alves Pedro, 1008463618
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
    
 ##############################################################################
 # IN-GAME SETTINGS
 ##############################################################################
 .eqv number_of_multi_brick 5 # NUMBER OF BRICKS THAT REQUIRES MULTI HITS
 
 .eqv enable_unbreakable_brick 1 #Choose to whether enable unbreakable brick
 
 .eqv number_of_unbreakable_each_row 1
 
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# Paddle_length: 6

.eqv Left_boundary 3584  #for paddle

.eqv  Right_boundary 3708 #for paddle

.eqv GREEN 0x00ff00
.eqv BLACK 0x000000
.eqv BLUE 0x0000ff
.eqv ORANGE 0xffa500
.eqv PINK 0xf980d1
.eqv GREY 0x808080
.eqv RED 0xff0000
.eqv WHITE 0xFFFFFF
.eqv Paddle_length 5
.eqv multxByte 4
.eqv multyByte 128
.eqv number_of_hit_required 2  
.eqv PURPLE 0x6a329f

.eqv two_before_break_colour  0x416e29
.eqv one_before_break_colour 	0x00ff00
##############################################################################
# Mutable Data
##############################################################################
#
# .space gives the address
#
# to mutate values saved in .space
#
# 1. la $t0, paddle_left
#
# 2. sw $t1, 0($t0)
#
#########  PADDLE  ######
paddle_left_for_ball:
	.space 4 #store position of the left most point (for collision check)
paddle_left:
	.space 4 #store position of left most point 
paddle_right:
	.space 4 #store positin of right most point
paddle_left_old:
	.space 4 #store positin of right most point (old)
paddle_right_old:
	.space 4 #store positin of right most point (old)
########  BALL  #########
ball_move_status:
	.space 4 # During Initialization stage, this should be set to 0 (default status it got changed only when user first press a key)
############BLOCK ARRAYs#######
Left_array:
	.word 772, 784, 796, 808,820,832,844,856,868,880, 900, 912, 924, 936, 948, 960, 972, 984, 996, 1008, 1028, 1040,1052,1064,1076,1088,1100,1112,1124, 1136

Right_array:
	.word 780, 792, 804, 816,828,840,852,864,876,888
	.word 908, 920, 932, 944,956968,980,992,1004, 1016
	.word 1036, 1048, 1060, 1072, 1084, 1096, 1108,1120, 1132, 1144

Hit_counter:
	.space 120

### ===== !!!!!!!! NOTES FOR USED PRESERVED REGISTER SO FAR !!!!!!!!!! ===== ############# 



# @ $s1 : stage of movement 1

# @ $s3: stage of movement 3

# @ $s6: current X coordinate of the ball  

# @ $s7: current Y coordinate of the ball

# @$s4: current X speed of the ball  

# @$s5: current Y speed of the ball  

# @$s2: ball_current_direction

# @$s0: score accumulator

	
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
#################### reset paddle row / ball status ###############

		li $t9, BLACK 

		li $t0, 3584 #start point 
		li $t1, 3708 #end point

		reset_paddle :
		bgt $t0, $t1, end_of_reset
		lw $t2, ADDR_DSPL #bitmap gp
		add $t2, $t2, $t0 #add offset
		sw $t9, 0($t2) #paint
		addi $t0, $t0, 4 #increment by 4 bytes
		j reset_paddle
		end_of_reset:
		
		jal reset_hit_counter
		
		li $a0, number_of_hit_required
		li $a1, number_of_multi_brick
		
		jal generate_multi_hit_brick
		
		li $t7, enable_unbreakable_brick
		li $a1, number_of_unbreakable_each_row
		beqz $t7, initialization
			jal generate_unbreakbale_brick
	
	
	li $a0, 0
	li $a1, 632
	jal draw_score
	
	initialization:
######################### DRAW INITIALIZATIONS ##############################
	li $s0, 0 # reset score counter
	
	lw $t0, ADDR_DSPL	                                      # $t0 stores the base address for display
	li $t1, GREY	                                         # $t1 stores the red colour code
		      
	li $t2, 32                                                 #t2 is the counte
	addi $t0, $t0, 640
	draw_top_border:
		beqz $t2, end_of_top_border
		sw $t1, 0($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, -1
		j draw_top_border
	end_of_top_border:
	
	lw $t0, ADDR_DSPL                                         #reset t0
	addi $t0, $t0, 640 
	li $t2, 24                                                          #t2 is the counter
	draw_left_border:
		beqz $t2, end_of_left_border
		sw $t1, 0($t0)
		addi $t0, $t0, 128
		addi $t2, $t2, -1
		j draw_left_border 
	
	end_of_left_border:
	
	lw $t0, ADDR_DSPL                                  #reset t0
	addi $t0, $t0, 764
	li $t2, 24                                                   #t2 is the counter
	draw_right_border:
	
		beqz $t2, end_of_right_border
		sw $t1, 0($t0)
		addi $t0, $t0, 128
		addi $t2, $t2, -1
		j draw_right_border 
	
	end_of_right_border:
	
	li $t1, 0x00ff00 # set to green
	lw $t0, ADDR_DSPL #reset t0
	li $t2,  6 #counter
	
	addi $t0, $t0, 3636 #set t0 to where the original paddle should be (128 * 28 + 4 *13)
	
	draw_original_paddle:
	beqz $t2, end_of_draw_original_paddle
		sw $t1, 0($t0)  
		addi $t0, $t0, 4
		addi $t2, $t2, -1
		j draw_original_paddle
	end_of_draw_original_paddle:
	
	#3636, 3652
	lw $t0, ADDR_DSPL 
	addi $t0, $t0, 3636
	la $t9, paddle_left
	sw $t0, 0($t9) #store initial left point of paddle to memory
	
	lw $t1, ADDR_DSPL 
	addi $t1, $t1, 3656
	la $t8, paddle_right
	sw $t1, 0($t8) #store initial right point of paddle to memory
	
	la $t0, paddle_left_for_ball
	li $t1, 3636
	sw $t1, 0($t0)

	################$  PAINT  BLOCKS $############

##### BLOCK 1 ######

li $t2, BLUE #Painter

###FIRST ROW###
li $t9, BLUE #Painter
li $t0, 772 #start point 
li $t1, 888 #end point

paint_block1:
	bgt $t0, $t1, end_of_draw_block_first_row
	lw $t2, ADDR_DSPL #bitmap gp
	add $t2, $t2, $t0 #add offset
	sw $t9, 0($t2) #paint
	addi $t0, $t0, 4 #increment by 4 bytes
	j paint_block1
	end_of_draw_block_first_row:
	
###SECOND ROW###	
li $t9, ORANGE #Painter
li $t0, 900 #start point 
li $t1, 1016 #end point

paint_block2:
	bgt $t0, $t1, end_of_draw_block_second_row
	lw $t2, ADDR_DSPL #bitmap gp
	add $t2, $t2, $t0 #add offset
	sw $t9, 0($t2) #paint
	addi $t0, $t0, 4 #increment by 4 bytes
	j paint_block2
	end_of_draw_block_second_row:

###THIRD ROW ###
li $t9, RED #Painter
li $t0, 1028 #start point 
li $t1, 1144 #end point

paint_block3:
	bgt $t0, $t1, end_of_draw_block_third_row
	lw $t2, ADDR_DSPL #bitmap gp
	add $t2, $t2, $t0 #add offset
	sw $t9, 0($t2) #paint
	addi $t0, $t0, 4 #increment by 4 bytes
	j paint_block3
	end_of_draw_block_third_row:

####DRAW THE BALL AND INITIALIZE BALL_VARIABLES####
#initial: add + 3516
# x = 15 (15 * 4)
# y = 27 (27 * 128)

li $a1, 15 #load current_x_axis (since its initialization, we have not put value into current_x_axis yet)
li $a0, 27 #load current_y_axis (since its initialization, we have not put value into current_y_axis yet)
jal find_ball_offset #returns V0	

### using v0	
lw $t0, ADDR_DSPL
add $t0, $t0, $v0 # add

li $t9, WHITE
sw $t9, 0($t0)


li $5, 0
la $t6, ball_move_status
sw $t5, 0($t6) #Set ball_move_status to 0 (default)


### Initialize Stage counter for Movement 1 and movement 3


### Preserved Register ###
### These three only changes during Updating ball location:

li $s1, 0 # by default, it is at stage 0 (Movement 1)

li $s3, 0 # by default, it is at stage 0 (Movement 3)

li $s4, 0 # by default, the ball x speed is 0

li $s5, -1 # by default, the ball y speed is -1

li $s6, 15  #PRESERVED REGISTER:  initial x coordinate of ball 

li $s7, 27 #PRESERVED REGISTER: initial y coordinate of ball

li $s2, 0 #Set ball_current_direction to 0 (default: going straight up)

##################################	
game_loop:
##################################

jal check_victory
beq $v0, 1, victory_sound
b keyboard_check
	
victory_sound:
	
	addi $sp, $sp, -12
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
		
		
	li $v0 , 31
	li $a0 , 70
	li $a1 , 3000
	li $a2 , 9
	li $a3, 100
	syscall
		
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $a2, 8($sp)
	addi  $sp, $sp, 12
	#$a0 = pitch (0-127)
	#a1 = duration in milliseconds
	#$a2 = instrument (0-127)
	#$a3 = volume (0-127)
	
	
	j you_win




# if input == s { moveDown();}	100, moveRight
# if input == d { moveRigth();}	97, moveLeft

# 1a. Check if key has been pressed
keyboard_check: 
lw $t9 , ADDR_KBRD  # 
lw $t8 , 0 ($t9)  #
beq $t8 , 1 , keyboardinput # 

j Check_collisions

# 1b. Check which key has been pressed
keyboardinput: # A key i s p r e s s e d
	lw $t2 , 4 ( $t9 ) # Load s e c o n d word from k e y b o a r d
	
	beq $t2,  97, update_paddle_move_left 
	beq $t2, 100, update_paddle_move_right
	beq $t2, 116, exit_game
	beq $t2, 112, pause_game_loop
	
	resume_game:
	nop
	
# 2a. Check for collisions
Check_collisions:

add $a0, $s6, $zero #x coor
add $a1, $s7, $zero #y coor
jal paddle_collision

add $a0, $s6, $zero #x coor
add $a1, $s7, $zero #y coor
jal check_brick_collision

add $a0, $s6, $zero #x coor
add $a1, $s7, $zero #y coor
jal wall_collision_checker


jal paint_blk_black

end_of_check_collisions:
	nop
	j Update_ball_location #jump to update ball and redraw

### UPDATE paddle to left and redraw ###
update_paddle_move_left:
	la $t8, paddle_left
	lw $t0, 0($t8) #load memory address of current left most position of paddle 
	lw $t1, 0($t8) #load memory address of  current left most position of paddle (copy)
	
	la $t9, paddle_right
	lw $t3, 0($t9)#load memory address of current right most position of paddle
	lw $t4, 0($t9)#load memory address of current right most position of paddle (copy)
	
	addi $t1, $t1, -8 # move left most poinr to left by 1
	addi $t4, $t4, -8 # move right most point of the paddle to left by 1
	
	
	#3584 is the left wall;
	li $t2, Left_boundary #load 3584 to t2
	lw $t5, ADDR_DSPL
	add $t5, $t5, $t2
	
	sle $t2, $t1, $t5 # t2 = 1 if t1 <= t5
	li $t5, 1
	beq $t2, $t5, end_of_update_paddle_move_left 
	
	addi $sp , $sp, -8
	sw $t0, 4($sp) # save t0 value at 4(sp)
	sw $t1, 0($sp) # save t1 value at 0(sp)
	
	la $t0, paddle_left_for_ball #update paddle_left_for_ball -8
	lw $t1, 0($t0)
	addi $t1, $t1, -8
	sw $t1, 0($t0)
	
	lw $t1, 0($sp) # load back t1 value at 0(sp)
	lw $t0, 4($sp) # load back t0 value at 4(sp)
	addi $sp, $sp, 8
	
	# $t1 saved the most updated position of the paddle_left
	#$t4 saved the most updated position of the paddle_right
	
	#update the values in memory
	sw $t1, 0($t8)
	sw $t4, 0($t9)
	
	la $t7,  paddle_left_old
	la $t6, paddle_right_old
	
	sw $t0, 0($t7)
	sw $t3, 0($t6)
	
	end_of_update_paddle_move_left:
	
	Update_paddle_left:
	
	li $t1, GREEN # set to green
	li $t3, BLACK
	lw $t0, paddle_left # (Memory address)LOAD NEWEST LEFT POSITION OF THE PADDLE
	lw $t2, paddle_right_old
	
	li $t9, 6
	loop_paint_left_paddle:
		beqz $t9, end_loop_paint_left_paddle
		
		sw $t1, 0($t0)
		
		addi $t0, $t0, 4
		addi $t9, $t9, -1
		j loop_paint_left_paddle
	
	end_loop_paint_left_paddle: 
	sw $t3, 0($t2)
	sw $t3, -4($t2)
	
	
	 end_of_Update_paddle_left:
	
	li $5, 1
	la $t6, ball_move_status
	sw $t5, 0($t6) #Set ball_move_status to 1
	
	 j Check_collisions #Back to check collisions
	 
############################################	
############################################

### UPDATE	 paddle right and redraw###############
update_paddle_move_right:
	la $t8, paddle_left
	lw $t0, 0($t8) #load memory address of current left most position of paddle 
	lw $t1, 0($t8) #load memory address of  current left most position of paddle (copy)
	
	la $t9, paddle_right
	lw $t3, 0($t9)#load memory address of current right most position of paddle
	lw $t4, 0($t9)#load memory address of current right most position of paddle (copy)
	
	addi $t1, $t1, 8 # move left most poinr to right by 1
	addi $t4, $t4, 8 # move right most point of the paddle to right by 1
	
	#3708 is the left wall;
	lw $t5, ADDR_DSPL
	addi $t5, $t5, Right_boundary
	
	sge $t2, $t4, $t5 # t2 = 1 if t1 >= t5
	li $t5, 1
	beq $t2, $t5 , end_of_update_paddle_move_right 
	
	addi $sp , $sp, -8
	sw $t0, 4($sp) # save t0 value at 4(sp)
	sw $t1, 0($sp) # save t1 value at 0(sp)
	
	la $t0, paddle_left_for_ball #update paddle_left_for_ball -8
	lw $t1, 0($t0)
	addi $t1, $t1, 8
	sw $t1, 0($t0)
	
	lw $t1, 0($sp) # load back t1 value at 0(sp)
	lw $t0, 4($sp) # load back t0 value at 4(sp)
	addi $sp, $sp, 8
	
	# $t1 saved the most updated position of the paddle_left
	#$t4 saved the most updated position of the paddle_right
	
	#update the values in memory
	sw $t1, 0($t8)
	sw $t4, 0($t9)
	
	la $t7,  paddle_left_old
	la $t6, paddle_right_old
	
	sw $t0, 0($t7)
	sw $t3, 0($t6)
	
	end_of_update_paddle_move_right:
	
	Update_paddle_right:

	li $t1, GREEN # set to green
	li $t3, BLACK
	lw $t0, paddle_right # (Memory address)LOAD NEWEST LEFT POSITION OF THE PADDLE
	lw $t2, paddle_left_old
	
	li $t9, 6
	loop_paint_right_paddle:
		beqz $t9, end_loop_paint_right_paddle
		
		sw $t1, 0($t0)
		
		addi $t0, $t0, -4
		addi $t9, $t9, -1
		j loop_paint_right_paddle
	
	end_loop_paint_right_paddle: 
	
	sw $t3, 0($t2)
	sw $t3, 4($t2)
	
	
	end_of_Update_paddle_right:
	
	li $5, 1
	la $t6, ball_move_status
	sw $t5, 0($t6) #Set ball_move_status to 1

	j Check_collisions #Back to check collisions


#######Update Ball #########
Update_ball_location:
	
	### check move_status###
	la $t0, ball_move_status
	lw $t1, 0($t0)
	beqz $t1, end_update_ball_location # if move_status is 0, skip
	
	#paint original position black#
	
	li $a1, 0 # x argument 
	li $a0, 0  # y argument
	add $a1, $a1, $s6 #load  x coor  (to be painted)
	add $a0, $a0, $s7 #load y coor (to be painted)
		
	jal find_ball_offset #returns V0		
						
	### Paint next position using v0
	lw $t0, ADDR_DSPL
	add $t0, $t0, $v0# add

	li $t9, BLACK
	sw $t9, 0($t0)
	
	###FINISH paint original position black###

	## Check which move_method should be used based on given current_direction
	
	li $t2, 0 #straight up
	li $t3, 1 #second type
	li $t4, 2 #third type
	li $t5, 3 #fourth type
	
	beq $s2, $t2, update_ball_0
	beq $s2, $t3, update_ball_1
	beq $s2, $t4, update_ball_2
	beq $s2, $t5, update_ball_3

	###########################################	
	update_ball_0: #this makes ball moving 90 up/down 
				#NO STAGE
	##########################################
	
		add $s6, $s6, $s4 #UPDATE $S6 (X COOR)
		add $s7, $s7, $s5 # UPDATE $S7 (y coor)	
		
 		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)	
	
		end_of_0:
		j end_update_ball_location
	####################################################	
	update_ball_1: #this makes ball moving 75  
				# Stage 0: move vertically
				#Stage 1: move diagonally 
	####################################################	
		
		## $s1 only has two possible values: 0 and 1 representing stage 0 and stage 1 respectively
		
		beqz $s1, method1_stage0  # if current move stage is 0, then go to method1_stage0
		
		########################################
		#stage 1 move: move one spot diagonally
		#since diagonally, update X and Y both 
		add $s6, $s6, $s4 #UPDATE $S6 (X COOR)
		add $s7, $s7, $s5 # UPDATE $S7 (y coor)
		
		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)
		
		li $s1, 0
		j end_of_1 #end 
		##########################################
		
		#stage 0 move: move one spot vertically 
		#since vertically, update  Y ONLY
		method1_stage0: 
		
		add $s7, $s7, $s5 # UPDATE $S7 (y coor)
		
		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)
		
		li $s1, 1
		end_of_1: 
		j end_update_ball_location
	#####################################################	
	update_ball_2: #this makes ball moving 45 or ? up/down 
				# NO stage
	######################################################		
		add $s6, $s6, $s4 #UPDATE $S6 (X COOR)
		add $s7, $s7, $s5 # UPDATE $S7 (y coor)
		
		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)
		
	
		end_of_2:
		j end_update_ball_location
		
	####################################################	
	update_ball_3: #this makes ball moving 25
				# Stage 0: move horizontally
				#Stage 1: move diagonally 
	####################################################	
	
		## $s3 only has two possible values: 0 and 1 representing stage 0 and stage 1 respectively
		beqz $s3, method3_stage0  # if current move stage is 0, then go to method1_stage0
		
		########################################
		#stage 1 move: move one spot diagonally
		#since diagonally, update X and Y both 
		add $s6, $s6, $s4 #UPDATE $S6 (X COOR)
		add $s7, $s7, $s5 # UPDATE $S7 (y coor)
		
		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)
		
		li $s3, 0
		j end_of_3 #end 
		########################################
		#Stage 0 move: move one spot horizontally  
		#since horizontally, update  X ONLY
		
		method3_stage0:
		add $s6, $s6, $s4 #UPDATE $S6 (X COOR)
				
		### CALCULATE OFFSET (LOCATION)###
		li $a1, 0 # x argument 
		li $a0, 0  # y argument
		add $a1, $a1, $s6 #load  x coor  (to be painted)
		add $a0, $a0, $s7 #load y coor (to be painted)
		
		jal find_ball_offset #returns V0		
						
		### Paint next position using v0
		lw $t0, ADDR_DSPL
		add $t0, $t0, $v0# add

		li $t9, WHITE
		sw $t9, 0($t0)
		
		li $s3, 1
		end_of_3:
		j end_update_ball_location
	

end_update_ball_location:
	nop
	
	
# 4. Sleep
sleep: 
li $v0 , 32
li $a0 , 45
syscall


#5. Go back to 1
    b game_loop

you_win: 
	lw $t9 , ADDR_KBRD  
	lw $t8 , 0 ($t9)  
	beq $t8 , 1 , you_win_keyboardinput 
	
	# no input then keep
	b you_win
	
	you_win_keyboardinput :
	lw $t2 , 4 ( $t9 ) 
	beq $t2, 114, restart_game # if input is R then restart the game
	beq $t2, 116, exit_game # if input is T then exit the game
	b you_win # overwise still keep the game_over status
	
game_over:
	
	lw $t9 , ADDR_KBRD  
	lw $t8 , 0 ($t9)  
	beq $t8 , 1 , game_over_keyboardinput 
	
	# no input then keep
	b game_over
	
	game_over_keyboardinput:
	lw $t2 , 4 ( $t9 ) 
	beq $t2, 114, restart_game # if input is R then restart the game
	beq $t2, 116, exit_game # if input is T then exit the game
	b game_over # overwise still keep the game_over status
	
	restart_game:
		
		jal reset_hit_counter
		li $a0, number_of_hit_required
		li $a1, number_of_multi_brick
		jal generate_multi_hit_brick
		li $s0, 0 #reset score
		jal erase_score 
		b main
	
exit_game:
	li   $v0, 10
	syscall
	

pause_game_loop:
	lw $t9 , ADDR_KBRD  
	lw $t8 , 0 ($t9)  
	beq $t8 , 1 , pause_game_keyboardinput 
	b pause_game_loop
		pause_game_keyboardinput: 
		lw $t2 , 4 ( $t9 ) 
		beq $t2, 112, exit_pause
			b pause_game_loop
	exit_pause:
		j resume_game










###Functions###

find_ball_offset: 
	# Functoin, find_ball_offset, calculates and returns the total offset that should be added to ADDR_BITMAP (In other words, the exact position)
	#
	# IT takes TWO arguments:
	# @a0 : current Y coor of the ball
	# @ a1: current X coor of the ball
	#
	# IT returns  ONE value:
	# @v0: the total offset 
	#
	# Equavalent algorithm: 4 * X + 128 * Y
	
	sll 	$a1, $a1, 2		# x = x * 4
	sll 	$a0, $a0, 7             # y = y * 128
	
	add $v0, $a1, $a0
		
	jr $ra

wall_collision_checker: 
	#check wall collision
	#mutate x, y ball speed
	#input x,y coords, and ball_direction (non of them were mutated)
	
	# a0 = x coor, a1 = y coor
	# x>= 31, or x<= 0 indicated side wall collision
	# y<= 5	
	add $t0, $a0, $s4 # t0 = x coor + x speed
	li $t2, 31 # t2 = 31
	
	sle $t1, $t0, $zero # if t0 <= 0, set t1 to 1 else 0 
	bne $t1, $zero, flip_x # if t1 is 1, go to flip X spped
	
	sge $t1, $t0, $t2 # if t0 >= 31, set t1 to 1 else 0 
	bne $t1, $zero, flip_x # if t1 is 1, go to flip X spped
	
	j check_y # else no collision happens on X axis, directly go to check Y
	
	flip_x: 
		nor  $s4, $s4, $s4      #
		addi $s4, $s4, 1  # multiply x speed by -1 
		
		######### SOUND ###########
				addi $sp, $sp, -12
				sw $a0, 0($sp)
				sw $a1, 4($sp)
				sw $a2, 8($sp)
		
		
				li $v0 , 31
				li $a0 , 100
				li $a1 , 120
				li $a2 , 115
				li $a3, 100
				syscall
		
				lw $a0, 0($sp)
				lw $a1, 4($sp)
				lw $a2, 8($sp)
				addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
		
	check_y:
		add $t0, $a1, $s5 # t0 = y coord + yspeed
		li $t2, 5 # t2 = 5
		sle $t3, $t0, $t2 # if t0 <= 5, set t3 to 1 else 0
		bne $t3, $zero, flip_y # if t3 is 1, go to flip Y spped
		
		sge $t3, $t0, 33 # if t0 >= 64, set t3 to 1 else 0
		bne $t3, 0, end_the_game
		
		jr $ra
		
		flip_y: 
		nor $s5, $s5, $s5      #
		addi $s5, $s5, 1  # multiply y speed by -1 
		
		jr $ra
		
		end_the_game:
		
		
		li $v0 , 31
		li $a0 , 70
		li $a1 , 1000
		li $a2 , 20
		li $a3, 100
		syscall
		
		#$a0 = pitch (0-127)
		#$a1 = duration in milliseconds
		#$a2 = instrument (0-127)
		#$a3 = volume (0-127)
			j game_over

paddle_collision:
		# a0 = x coord
		# a1 = y coord
		bne $s5, 1, end_collide_with_paddle
		
		la $t0, paddle_left_for_ball 
		lw $t6, 0 ($t0)
		li $t0, 0
		add $t0, $t6, $zero  # t0 store left most posision of the paddle (total offset)
		addi $t1, $t0, 4 # 2nd 
		addi $t2, $t1, 4 # 3rd
		addi $t3, $t2, 4 # 4th
		addi $t4, $t3, 4 # 5th
		addi $t5, $t4, 4 # 6th
	
		add $t6, $s5, $s7 # (y + y speed)
		sll $t6, $t6, 7 # (y + y speed ) * 128
		sll $t7, $s6, 2 # x * 4
	
		add $t6, $t6, $t7 # total offset to the top ball position


		paddle_collision_step_2: 
		
				beq $t6, $t0, paddel_c0
				beq $t6, $t1, paddel_c1
				beq $t6, $t2, paddel_c2
				beq $t6, $t3, paddel_c3
				beq $t6, $t4, paddel_c4
				beq $t6, $t5, paddel_c5
				
				jr $ra # no collision
				
				paddel_c0:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, -1 # set X speed to -1 (go left)
					li $s2, 3 #set to 4th direction 
					li $s3, 0 # set stage to 0 
					
					addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
				jr $ra
				paddel_c1:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, -1 # set X speed to -1 (go left)
					li $s2, 2 #set to 3rd direction 
					
					addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
				
				
				
				jr $ra
				paddel_c2:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, -1 # set X speed to -1 (go left)
					li $s2, 1 #set to 2nd direction 
					
					li $s1, 0 #set to stage 0 
					
					addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
				
				
				
				jr $ra
				paddel_c3:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, 1 # set X speed to 1 (go right)
					li $s2, 1 #set to 2nd direction 
					li $s1, 0 #set to stage 0 
				
				addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
				
				jr $ra
				paddel_c4:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, 1 # set X speed to 1 (go right)
					li $s2, 2 #set to 3rd direction 
				
				addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
				
				jr $ra
				paddel_c5:
					li $s5, -1 # set Y speed to -1 (go up)
					li $s4, 1 # set X speed to 1 (go right)
					li $s2, 3 #set to 4th direction 
					li $s3, 0 # set stage to 0 
					
				addi $sp, $sp, -12
					sw $a0, 0($sp)
					sw $a1, 4($sp)
					sw $a2, 8($sp)
		
		
					li $v0 , 31
					li $a0 , 100
					li $a1 , 120
					li $a2 , 116
					li $a3, 100
					syscall
		
					lw $a0, 0($sp)
					lw $a1, 4($sp)
					lw $a2, 8($sp)
					addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
				
		end_collide_with_paddle: 
				jr $ra

		
						
check_brick_collision: 
	# a0 = current x coord
	# a1 = current y coord
	
	li $t0, 0 # counter from 0
	li $t1, 120 # upper bound of loop
	la $t8, Left_array
	la $t7, Hit_counter
	
	add $t3, $s4, $s6 # (x + x speed)
	sll $t3, $t3, 2 # (x + x speed ) * 4 
	sll $t2, $s7, 7 # (y * 128)
		
	add $t2, $t3, $t2 # total offset to the left ball position
	
	add $t3, $s5, $s7 # (y + y speed)
	sll $t3, $t3, 7 # (y + y speed ) * 128
	sll $t4, $s6, 2 # x * 4
	
	add $t3, $t3, $t4 # total offset to the top ball position
		 	 
	brick_collision_loop:
	
		# t2 = left/right; t3 = top
		beq $t0, $t1, end_of_brick_collision
		
		lw $t4, 0($t8) #load the offset of the first block
		addi $t5, $t4, 12 
		
		i_brick_collision_loop: 
				beq $t4, $t5, end_i_brick_collision_loop
		
				beq  $t4, $t2, collide_brick_horizontal
			v1: 
				beq  $t4, $t3, collide_brick_veritical
			v2: 
				addi $t4, $t4, 4 # increment t4 by 4 (next block)
				b i_brick_collision_loop
				
		end_i_brick_collision_loop: 
				addi $t8, $t8, 4 # increment t8 by 4 left array
				addi $t7, $t7, 4 # increment t7 by 4 hit counter
				addi $t0, $t0, 4 # increment t0 by 4				
				b brick_collision_loop
		
		collide_brick_horizontal: 
				lw $t6, 0($t7) # load hit_counter value (corresponding to the current index) 
				beqz $t6, v1
				
				nor  $s4, $s4, $s4      #
				addi $s4, $s4, 1  # multiply x speed by -1 
				
				addi $t6, $t6, -1 # hit counter -1
				sw $t6, 0($t7)
				
				
				######### SOUND ###########
				addi $sp, $sp, -12
				sw $a0, 0($sp)
				sw $a1, 4($sp)
				sw $a2, 8($sp)
		
		
				li $v0 , 31
				li $a0 , 100
				li $a1 , 60
				li $a2 , 121
				li $a3, 100
				syscall
		
				lw $a0, 0($sp)
				lw $a1, 4($sp)
				lw $a2, 8($sp)
				addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
			bne $t6, 0, end_add_score_one
				addi $sp, $sp, -32
				sw $t0, 0($sp)
				sw $t1, 4($sp)
				sw $t2, 8($sp)
				sw $t3, 12($sp)
				sw $a0, 16($sp)
				sw $a1, 20($sp)
				sw $ra, 24($sp)
				sw $a2, 28($sp)
				
				
				addi $a0, $s0, 1
				jal draw_score
				addi $s0, $s0, 1
						
				lw $t0, 0($sp)
				lw $t1, 4($sp)
				lw $t2, 8($sp)
				lw $t3, 12($sp)
				lw $a0, 16($sp)
				lw $a1, 20($sp)
				lw $ra, 24($sp)
				lw $a2, 28($sp)
				addi $sp, $sp, 32
		end_add_score_one: 	
				b v1
		
		collide_brick_veritical: 
				lw $t6, 0($t7) # load hit_counter value (corresponding to the current index) 
				beqz $t6, v2
				
				nor  $s5, $s5, $s5      #
				addi $s5, $s5, 1  # multiply y speed by -1 
				
				addi $t6, $t6, -1 # hit counter -1
				sw $t6, 0($t7)
				
				######### SOUND ###########
				addi $sp, $sp, -12
				sw $a0, 0($sp)
				sw $a1, 4($sp)
				sw $a2, 8($sp)
		
		
				li $v0 , 31
				li $a0 , 100
				li $a1 , 60
				li $a2 , 121
				li $a3, 100
				syscall
		
				lw $a0, 0($sp)
				lw $a1, 4($sp)
				lw $a2, 8($sp)
				addi  $sp, $sp, 12
				#$a0 = pitch (0-127)
				#$a1 = duration in milliseconds
				#$a2 = instrument (0-127)
				#$a3 = volume (0-127)
			bne $t6, 0, end_add_score_two
				addi $sp, $sp, -32
				sw $t0, 0($sp)
				sw $t1, 4($sp)
				sw $t2, 8($sp)
				sw $t3, 12($sp)
				sw $a0, 16($sp)
				sw $a1, 20($sp)
				sw $ra, 24($sp)
				sw $a2, 28($sp)
				
				
				addi $a0, $s0, 1
				jal draw_score
				addi $s0, $s0, 1
						
				lw $t0, 0($sp)
				lw $t1, 4($sp)
				lw $t2, 8($sp)
				lw $t3, 12($sp)
				lw $a0, 16($sp)
				lw $a1, 20($sp)
				lw $ra, 24($sp)
				lw $a2, 28($sp)
				addi $sp, $sp, 32
		end_add_score_two:	
				b v2
				

end_of_brick_collision: 
	jr $ra	


paint_blk_black:
	li $t0, 0 # counter from 0
	li $t1, 120 # upper bound of loop
	la $t8, Left_array
	la $t7, Hit_counter
	
	
	paint_loop_2: 
		beq $t0, $t1, end_of_paint_blk_black
		lw $t6, 0($t7) # corresponding hit counter value
		lw $t5, 0($t8) # left most point of blk
		
		addi $t8, $t8, 4
		addi $t7, $t7, 4
		addi $t0, $t0, 4
		
		beqz $t6, erase_blk
		beq $t6, 2, deduce_colour_to_2
		beq $t6, 1, back_to_its_original_colour
		beq $t6, -1, unbreakable_colour
		
		b paint_loop_2
		
		erase_blk:
			li $t2, BLACK
			lw $t3, ADDR_DSPL
			add $t3, $t3, $t5 # position of left most point of blk
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
		b paint_loop_2
		
		deduce_colour_to_2: 
			li $t2, two_before_break_colour
			lw $t3, ADDR_DSPL
			add $t3, $t3, $t5 # position of left most point of blk
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
		b paint_loop_2
		
		back_to_its_original_colour: 
		
			addi $sp , $sp, -12
			sw $ra, 8($sp) 
			sw $t1, 4($sp) 
			sw $a0, 0($sp) 
			
			addi $a0, $t0, -4		
			jal check_original_colour
			
			lw $a0, 0($sp)
			lw $t1, 4($sp) 
			lw $ra, 8($sp) 
			addi $sp, $sp, 12	
	
			addi $t2, $v0, 0
			lw $t3, ADDR_DSPL
			add $t3, $t3, $t5 # position of left most point of blk
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
		b paint_loop_2
		
	unbreakable_colour:
			li $t2, PURPLE
			lw $t3, ADDR_DSPL
			add $t3, $t3, $t5 # position of left most point of blk
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
			addi $t3, $t3, 4
			sw $t2, 0($t3)
		b paint_loop_2
			
	
	end_of_paint_blk_black:
		jr $ra 
	
	
	
reset_hit_counter: 
	la $t0, Hit_counter
	
	li $t4, 1 
	
	li $t1, 120
	reset_hit_loop:
		beqz $t1, end_of_reset_loop	
	
		sw $t4, 0($t0)
		
	
		addi $t1, $t1, -4
		addi $t0, $t0, 4
		
		j reset_hit_loop
	end_of_reset_loop:
	
	jr $ra


generate_multi_hit_brick:
	# a0 indicates how many hit is required to break a brick
	# a1 indicates how many such brick is wanted
	
	generate_loop:
		
		beqz $a1, end_of_generate_loop
		
		la $t0, Hit_counter
		
		addi $sp , $sp, -12
		sw $ra, 8($sp) # save ra value at 8(sp)
		sw $a1, 4($sp) # save a1 value at 4(sp)
		sw $a0, 0($sp) # save a0 value at 0(sp)
		
		jal generate_random_0_30
		add $t0, $t0, $a0 # obtain the address of a brick hitcounter
		
		lw $a0, 0($sp) # load back a0 value at 0(sp)
		
		sw $a0, 0($t0)
	
	
		lw $a1, 4($sp) # load back a1 value at 4(sp)
		lw $ra, 8($sp) # load ra value at 8(sp)
		addi $sp, $sp, 12	
		
		addi $a1, $a1, -1
		
		b generate_loop
		
	end_of_generate_loop:
		jr $ra


generate_random_0_30:
	# it returns a0 stored a random value between 0 to 30
	li $v0 , 42
	li $a0 , 0
	li $a1 , 31
	syscall
	
	sll $a0, $a0, 2
	jr $ra
	
	

check_original_colour:
	#a0: index in hit counter where the brick is 
	#returns v0 that stores the original colour of a brick
	
	li $t1, 0
	sle $t1, $a0, 116
	sge $t1, $a0, 80
	beq $t1, 1, return_red
	
	li $t1, 0
	sle $t1, $a0, 76
	sge $t1, $a0, 40
	beq $t1, 1, return_orange
	
	li $v0, BLUE
	jr $ra
	
	return_red:
	li $v0, RED
	jr $ra
	
	return_orange:
	li $v0, ORANGE
	jr $ra

generate_random_unbreakable_index_row1:
	# it returns a0 stored a random value between 0 to 9
	li $v0 , 42
	li $a0 , 0
	li $a1 , 10
	syscall
	
	sll $a0, $a0, 2
	jr $ra

generate_random_unbreakable_index_row2:
	# it returns a0 stored a random value between 10 to 19
	li $v0 , 42
	li $a0 , 10
	li $a1 , 19
	syscall
	
	sll $a0, $a0, 2
	jr $ra

generate_random_unbreakable_index_row3:
	# it returns a0 stored a random value between 20 to 29
	li $v0 , 42
	li $a0 , 20
	li $a1 , 30
	syscall
	
	sll $a0, $a0, 2
	jr $ra

generate_unbreakbale_brick:
	#a1 : number of unbreakable each row
	li $t1, -1
	rows:
		beqz $a1, end_of_generation
		addi $sp , $sp, -8
		sw $ra, 4($sp) # save ra value at 4(sp)
		sw $a1, 0($sp) # save a1 value at 0(sp)
		
		### generate UB for row1
		jal generate_random_unbreakable_index_row1
		la $t0, Hit_counter
		add $t0, $t0, $a0
		sw $t1, 0($t0)
		
		### generate UB for row2
		jal generate_random_unbreakable_index_row2
		la $t0, Hit_counter
		add $t0, $t0, $a0
		sw $t1, 0($t0)
		### generate UB for row3
		jal generate_random_unbreakable_index_row3
		la $t0, Hit_counter
		add $t0, $t0, $a0
		sw $t1, 0($t0)
		
		
		lw $ra, 4($sp) 
		lw $a1, 0($sp) 
		addi $sp , $sp, 8
		
		addi $a1, $a1, -1
		b rows
	
	end_of_generation:
		jr $ra

draw_number:
	
		
	lw $t0, ADDR_DSPL
	li $t1, BLACK
	li $t2, WHITE
	
	# a0: 0<= number <= 9
	# a1: position to draw
	
	beq $a0, 0, draw_zero
	beq $a0, 1, draw_one
	beq $a0, 2, draw_two
	beq $a0, 3, draw_three
	beq $a0, 4, draw_four
	beq $a0, 5, draw_five
	beq $a0, 6, draw_six
	beq $a0, 7, draw_seven
	beq $a0, 8, draw_eight

	draw_nine:
		
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	#white
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 #blk
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
	b end_of_draw_number
	
	draw_zero:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	#white
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 #blk
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
		
	draw_one:
	
		add $t0, $a1, $t0 #start point 
		sw $t1, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		b end_of_draw_number
		
	draw_two:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
		
	draw_three:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
		
	draw_four:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t1, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
	
	draw_five:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
		
	draw_six:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
	
	draw_seven:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t1, 0($t0) # end of second col
		
		addi $t0, $t0, -4 
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
	
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t1, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
		
	draw_eight:
	
		add $t0, $a1, $t0 #start point 
		sw $t2, 0($t0)	#white
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white 
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128#white
		sw $t2, 0($t0)
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128 #blk
		sw $t1, 0($t0)
		
		addi $t0, $t0, 128
		sw $t2, 0($t0)
		
		addi $t0, $t0, 128
		sw $t1, 0($t0)  
		
		addi $t0, $t0, 128
		sw $t2, 0($t0) # end of second col
		
		addi $t0, $t0, -4 #white
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
	
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		addi $t0, $t0, -128
		sw $t2, 0($t0)
		
		b end_of_draw_number
	
end_of_draw_number: 
	
	jr $ra

draw_score:
	# a0: new score
	li $t1, 10
	
	div $s0, $t1	
	mflo $t2
	
	div $a0, $t1
	mflo $t3
	mfhi $a0
	
	addi $sp, $sp, -16
	sw $t1,  0($sp)
	sw $t2,  4($sp)
	sw $t3,  8($sp)
	sw $ra,  12($sp)
	
	li $a1, 632
	jal draw_number
	

	lw $t1,  0($sp)
	lw $t2,  4($sp)
	lw $t3,  8($sp)
	lw $ra,  12($sp)
	addi $sp, $sp, 16

	######################################	
	beq $t3, $t2, end_draw_score
	
	div $t2, $t1	
	mflo $t2
	
	div $t3, $t1
	mflo $t3
	mfhi $a0
	
	addi $sp, $sp, -16
	sw $t1,  0($sp)
	sw $t2,  4($sp)
	sw $t3,  8($sp)
	sw $ra,  12($sp)
	
	addi $a1, $a1, -16
	jal draw_number
	

	lw $t1,  0($sp)
	lw $t2,  4($sp)
	lw $t3,  8($sp)
	lw $ra,  12($sp)
	addi $sp, $sp, 16
	


end_draw_score:
 	jr $ra	


erase_score: 
	li $t0, BLACK
	lw $t1, ADDR_DSPL
	
	li $t2, 320
	erase_score_loop:	
		beqz $t2, end_of_erase_score
		sw $t0, 0($t1)
		addi $t1, $t1, 4
		addi $t2, $t2, -1
		b erase_score_loop
		
	end_of_erase_score:
	jr $ra


check_victory:
		la $t0, Hit_counter
		
		li $t1, 30
		li $v0, 1
		loop_through:
			beqz $t1, end_of_check_victory
			lw $t2, 0($t0)
			
			bge $t2, 1, no_win
			
			
			
			addi $t0, $t0, 4
			addi $t1, $t1, -1
			b loop_through
		
		no_win:
			li $v0, 0		
										
		end_of_check_victory:
			jr $ra	
		
								
		
