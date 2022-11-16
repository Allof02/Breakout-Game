################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
Paddle_length:
	.word 5
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
paddle_left:
	.space 4 #store position of left most point 
paddle_right:
	.space 4 #store positin of right most point
paddle_left_old:
	.space 4 #store positin of right most point (old)
paddle_right_old:
	.space 4 #store positin of right most point (old)
########  BALL  #########
ball_current_x:
	.space 4 # x * 4 gives the offset should be added to ADDR_DSPL to locate the current x_axis
ball_current_y:
	.space 4# y * 128 gives the offset should also be added to ADDR_DSPL to locatetbe current y_axis
ballx_current_speed:
	.space 4 
bally_current_speed:
	.space 4 
ball_current_direction:
	.space 4 # During Initialization stage, this should be set to 90 (default direction)
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
	
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:

######################### DRAW INITIALIZATIONS ##############################
	
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

	################$  PAINT  BLOCKS $############

##### BLOCK 1 ######

	li $t2, BLUE #Painter
	
#paint_block1:
#	beq $t1, $t0, end_of_paint_block1
#	la $t3, Left_array #first address where left_array is stored
#	add $t3, $t3, $t1 #increment address of left_array to access data coming after
#	lw $t4, 0($t3) # load offset to t4
#	lw $t5, ADDR_DSPL #load bitmap addr
#	add $t5, $t5, $t4 #add offset
#	sw $t2, 0($t5) #paint
#	addi $t1, $t1, 4 #increment counter
#	j paint_block1
#	end_of_paint_block1:

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

li $a0, 15 #load current_x_axis (since its initialization, we have not put value into current_x_axis yet)
jal find_ballX_axis_distance # call function : with return value $v0 = 15 * 4
li $t8, 0
add $t8, $t8, $v0 #save 15 * 4 into $t8

li $a0, 27 
jal find_ballY_axis_distance # call function : with return value $v0 = 27 * 128
li $t6, 0
add $t6, $t6, $v0 #save 27 * 128 into $t6

add $t8, $t8, $t6 # sum up t6 and t8 to get total bytes (offset)

lw $t0, ADDR_DSPL
add $t0, $t0, $t8# add

li $t9, WHITE
sw $t9, 0($t0)

li $t4, 15  # initial x coordinate of ball
li $t3, 27 #initial y coordinate of ball
la $t1, ball_current_x
la $t2, ball_current_y
sw $t4, 0($t1) #save to current_x
sw $t3, 0($t2) #save to current_y


	
game_loop:


# if input == s { moveDown();}	100, moveRight
# if input == d { moveRigth();}	97, moveLeft





# 1a. Check if key has been pressed
lw $t0 , ADDR_KBRD  # $t 0 = b a s e a d d r e s s f o r k e y b o a r d
lw $t8 , 0 ($t0)  # Load f i r s t word from k e y b o a r d
beq $t8 , 1 , keyboardinput # I f f i r s t word 1 , key i s p r e s s e d

b game_loop

# 1b. Check which key has been pressed
keyboardinput: # A key i s p r e s s e d
	lw $t2 , 4 ( $t0 ) # Load s e c o n d word from k e y b o a r d
	
	beq $t2,  97, update_paddle_move_left 
	beq $t2, 100, update_paddle_move_right
	
# 2a. Check for collisions






# 2b. Update locations (paddle, ball)

#######Update Ball #########



#######Update paddle###############


update_paddle_move_left:
	la $t8, paddle_left
	lw $t0, 0($t8) #load memory address of current left most position of paddle 
	lw $t1, 0($t8) #load memory address of  current left most position of paddle (copy)
	
	la $t9, paddle_right
	lw $t3, 0($t9)#load memory address of current right most position of paddle
	lw $t4, 0($t9)#load memory address of current right most position of paddle (copy)
	
	addi $t1, $t1, -4 # move left most poinr to left by 1
	addi $t4, $t4, -4 # move right most point of the paddle to left by 1
	
	
	#3584 is the left wall;
	li $t2, Left_boundary #load 3584 to t2
	lw $t5, ADDR_DSPL
	add $t5, $t5, $t2
	
	beq $t1, $t5, end_of_update_paddle_move_left #if t1 = t5, it means paddle will hit the wall, so don't update (move to left)
	
	
	# $t1 saved the most updated position of the paddle_left
	#$t4 saved the most updated position of the paddle_right
	
	#update the values in memory
	sw $t1, 0($t8)
	sw $t4, 0($t9)
	
	la $t7,  paddle_left_old
	la $t6, paddle_right_old
	
	sw $t0, 0($t7)
	sw $t3, ($t6)
	
	end_of_update_paddle_move_left:
	
	#THIS LINE IS ONLY FOR TEST
	j Update_paddle_left

update_paddle_move_right:
	la $t8, paddle_left
	lw $t0, 0($t8) #load memory address of current left most position of paddle 
	lw $t1, 0($t8) #load memory address of  current left most position of paddle (copy)
	
	la $t9, paddle_right
	lw $t3, 0($t9)#load memory address of current right most position of paddle
	lw $t4, 0($t9)#load memory address of current right most position of paddle (copy)
	
	addi $t1, $t1, 4 # move left most poinr to right by 1
	addi $t4, $t4, 4 # move right most point of the paddle to right by 1
	
	#3708 is the left wall;
	addi $t2, $zero, Right_boundary #load 3708 to t2
	lw $t5, ADDR_DSPL
	addi, $t5, $t5, Right_boundary
	
	beq $t4, $t5, end_of_update_paddle_move_right #if t4 = t2, it means paddle will hit the wall, so don't update (move to right)
	
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
	
	#THIS LINE IS ONLY FOR TEST
	j Update_paddle_right
	
	
	

	
	
	
# 3. Re-Draw the screen

##########UPDATE PADDLE#########################
#                                                                                                             #
#Method used: erase one spot paint one spot                               #
#                                                                                                             #
###############################################
Update_paddle_left:
	
	##Draw new paddle
	li $t1, GREEN # set to green
	li $t3, BLACK
	lw $t0, paddle_left # (Memory address)LOAD NEWEST LEFT POSITION OF THE PADDLE
	lw $t2, paddle_right_old
	
	sw $t1, 0($t0)
	sw $t3, 0($t2)
	
		
	 end_of_Update_paddle_left:
	 #this line just for test, need to jump to other section later
	 b sleep
	 

Update_paddle_right:

	li $t1, GREEN # set to green
	li $t3, BLACK
	lw $t0, paddle_right # (Memory address)LOAD NEWEST LEFT POSITION OF THE PADDLE
	lw $t2, paddle_left_old
	
	sw $t1, 0($t0)
	sw $t3, 0($t2)
	
	end_of_Update_paddle_right:
	#this line just for test, need to jump to other section later
	b sleep



	
	
# 4. Sleep
sleep: 
li $v0 , 32
li $a0 , 20
syscall


#5. Go back to 1
    b game_loop

###Functions###

## 4 * X ##
find_ballX_axis_distance:
	li $t0, 4
	li $v0, 0
	ballx_innerloop:
		beqz $a0, end_of_ballx_innerloop
		add $v0, $v0, $t0
		addi $a0, $a0, -1
		j ballx_innerloop
		end_of_ballx_innerloop:
		jr $ra

##128 * Y ##
find_ballY_axis_distance:
	li $t0, 128
	li $v0, 0
	bally_innerloop:
		beqz $a0, end_of_bally_innerloop
		add $v0, $v0, $t0
		addi $a0, $a0, -1
		j bally_innerloop
		end_of_bally_innerloop:
		jr $ra

