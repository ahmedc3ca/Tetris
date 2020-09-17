;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
  .equ LEDS, 0x2000                 ; LED address
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ BUTTONS, 0x2030              ; Buttons addresses

  ;; type enumeration
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04

  ;; GSA type
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

  ;; orientation enumeration
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4

  ;; collision boundaries
  .equ COL_X, 4
  .equ COL_Y, 3

  ;; Rotation enumeration
  .equ CLOCKWISE, 0
  .equ COUNTERCLOCKWISE, 1

  ;; Button enumeration
  .equ moveL, 0x01
  .equ rotL, 0x02
  .equ reset, 0x04
  .equ rotR, 0x08
  .equ moveR, 0x10
  .equ moveD, 0x20

  ;; Collision return ENUM
  .equ W_COL, 0
  .equ E_COL, 1
  .equ So_COL, 2
  .equ OVERLAP, 3
  .equ NONE, 4

  ;; start location
  .equ START_X, 6
  .equ START_Y, 1

  ;; game rate of tetrominoe falling down (in terms of game loop iteration)
  .equ RATE, 5

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8


  ;; TODO Insert your code here

addi sp, zero, LEDS
main:
addi s0, zero, RATE
call reset_game
first_loop:
	second_loop:
		addi s2, zero, 0 ; s2 = i
		third_loop:
			bge s2, s0, third_loop_exit
			call draw_gsa
			call display_score
			ldw a0, T_X(zero)
			ldw a1, T_Y(zero)
		addi a0, zero, NOTHING
		call draw_tetromino
			call wait 
			call get_input
			beq v0, zero, skip_act
			addi a0, v0, 0
			call act
			skip_act:	
			addi a0, zero, FALLING
			call draw_tetromino
			addi s2, s2, 1
			jmpi third_loop
		third_loop_exit:
		ldw a0, T_X(zero)
		ldw a1, T_Y(zero)
		addi a0, zero, NOTHING
		call draw_tetromino
		addi a0, zero, moveD
		call act
		addi a0, zero, FALLING
		call draw_tetromino
		beq v0 , zero, second_loop
	second_loop_exit:
	addi a0, zero, PLACED
	call draw_tetromino

	detect_full_line_loop:	
	call detect_full_line
	addi a0, v0, 0
	cmpeqi s5, v0, 8
	bne s5, zero, skip_remove_full_line
	addi a0, v0, 0
	call remove_full_line
	call increment_score
	call display_score
	jmpi detect_full_line_loop
	skip_remove_full_line:


	call generate_tetromino
	addi a0, zero, OVERLAP
	call detect_collision
	cmpeqi s6, v0, NONE
	beq s6, zero, skip_collision
	addi a0, zero, FALLING
	call draw_tetromino
	skip_collision:
	addi a0, zero, OVERLAP
	call detect_collision
	cmpeqi s1, v0, NONE
	bne s1, zero, first_loop  
exit_main:
jmpi main




; BEGIN:clear_leds
clear_leds:
stw zero, LEDS(zero)
stw zero, LEDS+4(zero)
stw zero, LEDS+8(zero)
ret
; END:clear_leds



; BEGIN:set_pixel
set_pixel:
addi sp, sp, -20
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)

andi s1, a0, 12; s1 = le nombre du LED (0, 4 ou 8)
slli s0, a0, 3 ; s0 = 8*x
andi s2, s0, 31; mask les 5 derniers bits => (8*x) % 32
add s2, s2, a1 ; bit = ((8*x)%32) + y 
addi s3, zero, 1
sll s3, s3, s2; s3 = s3 << s2
ldw s4, LEDS(s1); load the led
or s3, s4, s3; s3 = s3 || s4
stw s3, LEDS(s1)

ldw s4, 16(sp)
ldw s3, 12(sp)
ldw s2, 8(sp)
ldw s1, 4(sp)
ldw s0, 0(sp)
addi sp, sp, 20
ret
; END:set_pixel



; BEGIN:wait
wait:
addi sp, sp, -4
stw s0, 0(sp)

addi s0, zero, 1
slli s0, s0, 20
loop_wait:
	addi s0, s0, -1
	bne s0, zero, loop_wait

ldw s0, 0(sp)
addi sp, sp, 4
ret
; END:wait



; BEGIN:in_gsa
in_gsa:
addi sp, sp, -12
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)

cmplt v0, a0, zero
cmpgei s0, a0, X_LIMIT
cmplt s1, a1, zero
cmpgei s2, a1, Y_LIMIT
or v0, v0, s0
or v0, v0, s1
or v0, v0, s2

ldw s2, 8(sp)
ldw s1, 4(sp)
ldw s0, 0(sp)
addi sp, sp, 12
ret
; END:in_gsa



; BEGIN:get_gsa
get_gsa:
addi sp, sp, -8
stw s0, 0(sp)
stw s1, 4(sp)

addi s0, zero, 0	;s0 = 0
add s1, zero, a0
loop_add_get:				;s0 = x * Y_LIMIT
beq s1, zero, next_get
addi s0, s0, Y_LIMIT
addi s1, s1, -1
jmpi loop_add_get
next_get:
add s0, s0, a1			;s0 = (x * Y_LIMIT) + y
slli s0, s0, 2
ldw v0, GSA(s0)

ldw s1, 4(sp)
ldw s0, 0(sp)
addi sp, sp, 8
ret 
; END:get_gsa



; BEGIN:set_gsa
set_gsa:
addi sp, sp, -8
stw s0, 0(sp)
stw s1, 4(sp)

addi s0, zero, 0	;s0 = 0
add s1, zero, a0
loop_add_set:				;s0 = x * Y_LIMIT
beq s1, zero, next_set
addi s0, s0, Y_LIMIT
addi s1, s1, -1
jmpi loop_add_set
next_set:
add s0, s0, a1			;s0 = (x * Y_LIMIT) + y
slli s0, s0, 2
stw a2, GSA(s0)

ldw s1, 4(sp)
ldw s0, 0(sp)
addi sp, sp, 8
ret 
; END:set_gsa



; BEGIN:draw_gsa
draw_gsa:
addi sp, sp, -12
stw ra, 0(sp)
stw s0, 4(sp)
stw s1, 8(sp)

call clear_leds
addi s0, zero, X_LIMIT 	;s0 := x loop
addi s0, s0, -1			;s0 = 11
addi s1, zero, Y_LIMIT	;s1 := y loop
addi s1, s1, -1 		;s1 = 7

loopx:
	blt s0, zero, fin

loopy:
	blt s1, zero, nextCol

	add a0, zero, s0
	add a1, zero, s1
	call get_gsa
	
	beq v0, zero, nextRow
	add a0, zero, s0
	add a1, zero, s1
	call set_pixel

nextRow:
	addi s1, s1, -1
	jmpi loopy

nextCol:
	addi s1, zero, Y_LIMIT
	addi s1, s1, -1
	addi s0, s0, -1
	jmpi loopx

fin:
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 12
	ret 
; END:draw_gsa


; BEGIN:draw_tetromino
draw_tetromino:
	addi sp, sp, -28
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp)
	stw s5, 24(sp)

	add s5, zero, a0
	ldw t0, T_type(zero) ;type
	ldw t1, T_orientation(zero) ;orientation
	slli s4, t0, 2
	add s4, s4, t1
	slli s4, s4, 2 ; decay
	ldw s0, T_X(zero)
	ldw s1, T_Y(zero)
	add a0, zero, s0
	add a1, zero, s1
	add a2, zero, s5
	call set_gsa

	ldw s2, DRAW_Ax(s4)
	ldw s3, DRAW_Ay(s4) 
	ldw t5, 0(s2); offset of x
	ldw t6, 0(s3); offset of y
	add a0, s0, t5
	add a1, s1, t6
	add a2, zero, s5
	call set_gsa

	addi s2, s2, 4
	addi s3, s3, 4
	ldw t5, 0(s2); offset of x
	ldw t6, 0(s3); offset of y
	add a0, s0, t5
	add a1, s1, t6
	add a2, zero, s5
	call set_gsa

	addi s2, s2, 4
	addi s3, s3, 4
	ldw t5, 0(s2); offset of x
	ldw t6, 0(s3); offset of y
	add a0, s0, t5
	add a1, s1, t6
	add a2, zero, s5
	call set_gsa

	ldw s4, 24(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 28
ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
	addi t0, zero, START_X
	stw t0, T_X(zero)
	addi t0, zero, START_Y
	stw t0, T_Y(zero)
	addi t0, zero, N
	stw t0, T_orientation(zero)
loop_until_correct:
	ldw t0, RANDOM_NUM(zero)
	addi t1, zero, 7
	and t0, t0, t1
	cmplti t1, t0, 5
	beq t1, zero, loop_until_correct
end:
	stw t0, T_type(zero)
	ret
; END:generate_tetromino

; BEGIN:detect_collision
detect_collision:
	addi sp, sp, -32 ; push to the stack	
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp)
	stw s5, 24(sp)
	stw s6, 28(sp)

	add s4, a0, zero			; Set s4 as a0
	addi s5, zero, PLACED			; Le nombre 1 
	cmpnei t0, a0, E_COL
	beq t0, zero, case_E_COL
	cmpnei t0, a0, W_COL
	beq t0, zero, case_W_COL
	cmpnei t0, a0, So_COL
	beq t0, zero, case_So_COL
	jmpi case_OVERLAP

case_E_COL:
	addi t1, zero, 1	; x ~ 1
	addi t2, zero, 0	; y ~ 0
	jmpi cases_COL
case_W_COL:
	addi t1, zero, -1	; x ~ -1
	addi t2, zero, 0	; y ~ 0
	jmpi cases_COL
case_So_COL:
	addi t1, zero, 0	; x ~ 0
	addi t2, zero, 1	; y ~ -1
	jmpi cases_COL
case_OVERLAP: 			; PAS SÛR: Overlap <=> Au moins un bloc du tetromino est PLACED (0x01) ?
	addi t1, zero, 0	; x ~ 0
	add t2, zero, zero	; y ~ 0

cases_COL:

	ldw t4, T_type(zero) 			; Type
	ldw t5, T_orientation(zero) 	; Orientation	
	slli s6, t4, 2
	add s6, s6, t5
	slli s6, s6, 2 					; Decay

	ldw a0, T_X(zero)
	ldw a1, T_Y(zero)	; Current position of anchor point
	add s2, a0, t1
	add s3, a1, t2		; Position after motion in intended direction
	add a0, zero, s2
	add a1, zero, s3
	call in_gsa
	bne v0, zero, collision_occ ; test if it's in bounds
	add a0, zero, s2
	add a1, zero, s3
	call get_gsa		; Get its location
	beq v0, s5, collision_occ

	
	ldw s0, DRAW_Ax(s6)
	ldw s1, DRAW_Ay(s6) 
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6		; Current position of other point
	call in_gsa
	bne v0, zero, collision_occ ; test if it's in bounds
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6
	call get_gsa
	beq v0, s5, collision_occ


	addi s0, s0, 4
	addi s1, s1, 4
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6		; Current position of other point
	call in_gsa
	bne v0, zero, collision_occ  ; test if it's in bounds
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6
	call get_gsa
	beq v0, s5, collision_occ 


	addi s0, s0, 4
	addi s1, s1, 4
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6		; Current position of other point
	call in_gsa
	bne v0, zero, collision_occ ; test if it's in bounds
	ldw t5, 0(s0)		; Offset of x
	ldw t6, 0(s1)		; Offset of y
	add a0, s2, t5
	add a1, s3, t6
	call get_gsa
	beq v0, s5, collision_occ

	jmpi no_collision

collision_occ:
	add v0, zero, s4
	jmpi col_fin

no_collision:
	addi v0, zero, 4	; Set v0 to NONE (0x04)

col_fin:
	ldw s6, 28(sp)
	ldw s5, 24(sp)
	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 32 ; pull form the stack
	ret
; END:detect_collision


; BEGIN:rotate_tetromino
rotate_tetromino:
	addi sp, sp, -8
	stw ra, 0(sp)
	stw s0, 4(sp)

	addi s0, zero, rotR
	beq a0, s0, right_rotation
left_rotation:
	ldw s0, T_orientation(zero)
	addi s0, s0, -1
	andi s0, s0, 3
	stw s0, T_orientation(zero)
	jmpi end_rotate_tetromino

right_rotation:
	ldw s0, T_orientation(zero)
	addi s0, s0, 1
	andi s0, s0, 3
	stw s0, T_orientation(zero)

end_rotate_tetromino:
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 8
ret

; END:rotate_tetromino


; BEGIN:act
act:
	addi sp, sp, -24
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp)

	add s0, zero, a0
	addi t0, zero, moveD
	addi t1, zero, moveR
	addi t2, zero, moveL
	addi t3, zero, rotR
	addi t4, zero, rotL
	addi t5, zero, reset
	beq a0, t0, move_down
	beq a0, t1, move_right
	beq a0, t2, move_left
	beq a0, t3, rotate
	beq a0, t4, rotate
	beq a0, t5, gotoRESET ;go accordingly to the command

gotoRESET:
	call reset_game
	addi v0, zero, 0
	br end_act
move_down:
	addi s3, zero, So_COL
	addi a0, s3, 0
	call detect_collision ;check for south collision
	beq v0, s3, cant_move
	
	ldw t0, T_Y(zero)
	addi t0, t0, 1
	stw t0, T_Y(zero)
	addi v0, zero, 0 ;if no collision move down
	
	br end_act
	
move_right:
	addi s3, zero, E_COL
	addi a0, s3, 0
	call detect_collision; check for east collision
	beq v0, s3, cant_move

	ldw t0, T_X(zero)
	addi t0, t0, 1
	stw t0, T_X(zero)
	addi v0, zero, 0 ; if no collision move right
	
	br end_act

move_left:
	addi s3, zero, W_COL
	addi a0, s3, 0
	call detect_collision ; check for west collision
	beq v0, s3, cant_move
	
	ldw t0, T_X(zero)
	addi t0, t0, -1
	stw t0, T_X(zero)
	addi v0, zero, 0 ; if no collision move left

	br end_act

rotate:
	ldw s1, T_X(zero)
	ldw s2, T_Y(zero); store the initial coordinates in case of a rotation failure
	ldw s4, T_orientation(zero)
	
	call rotate_tetromino	
	addi a0, zero, OVERLAP
	call detect_collision ; rotate the tetromino and check for collision


	cmpeqi t0, v0, OVERLAP
	beq t0, zero, can_move ; if v0 != overlap then it's fine


	cmplti t0, s1,6 ; if (x < 6) t0 = 1
	beq t0, zero, center_from_right1 	;else move to the center
	
center_from_left1:
	addi t0, s1, 1
	stw t0, T_X(zero)
	br rotate_continued1
center_from_right1:
	addi t0, s1, -1
	stw t0, T_X(zero)

rotate_continued1:

	addi a0, zero, OVERLAP
	call detect_collision ; rotate the tetromino and check for collision


	cmpeqi t0, v0, OVERLAP
	beq t0, zero, can_move ; if v0 != overlap then it's fine

	cmplti t0, s1,6 ; if (x < 6) t0 = 1
	beq t0, zero, center_from_right2 	;else move to the center

center_from_left2:
	addi t0, s1, 2
	stw t0, T_X(zero)
	br rotate_continued2


center_from_right2:
	addi t0, s1, -2
	stw t0, T_X(zero)


rotate_continued2:
	addi a0, zero, OVERLAP
	call detect_collision
	cmpeqi t0, v0, OVERLAP	
	bne t0, zero, cant_rotate ; if still overlapping accept defeat

	br can_move ; else it's fine	

cant_rotate:
	stw s1, T_X(zero)
	stw s2, T_Y(zero)
	stw s4, T_orientation(zero)
cant_move:
	addi v0, zero, 1
	br end_act
can_move:
	addi v0, zero, 0
end_act:
	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 24
	ret
; END:act

; BEGIN:get_input
get_input:
	addi v0, zero, 0	; Default value
	addi t0, zero, 4	; Le nombre 4
	addi t1, zero, 0	; Loop
	ldw t2, BUTTONS+4(zero)

check_buttons:
	blt t0, t1, buttons_end			; If 4 < #Loop, out of loop
	andi t3, t2, 1
	bne t3, zero, button_pressed
	srli t2, t2, 1
	addi t1, t1, 1
	jmpi check_buttons

button_pressed:
	cmpeqi t4, t1, 0		; If t0 = 0 => moveL
	bne t4, zero, bp_moveL
	cmpeqi t4, t1, 1		; If t0 = 1 => rotL
	bne t4, zero, bp_rotL
	cmpeqi t4, t1, 2		; If t0 = 2 => reset
	bne t4, zero, bp_reset	
	cmpeqi t4, t1, 3		; If t0 = 3 => rotR
	bne t4, zero, bp_rotR
	cmpeqi t4, t1, 4		; If t0 = 4 => moveR
	bne t4, zero, bp_moveR

	bp_moveL:
	addi v0, zero, moveL
	jmpi buttons_end
	bp_rotL:
	addi v0, zero, rotL
	jmpi buttons_end
	bp_reset:
	addi v0, zero, reset
	jmpi buttons_end
	bp_rotR:
	addi v0, zero, rotR
	jmpi buttons_end
	bp_moveR:
	addi v0, zero, moveR
	jmpi buttons_end

buttons_end:
	stw zero, BUTTONS+4(zero)
	ret
; END:get_input



; BEGIN:detect_full_line
detect_full_line:
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)

	addi s0, zero, 0 ; y counter
	addi s1, zero, 0; x counter
	addi s2, zero, 1 ; the register used to check all leds are 1 (by and operators)

outer_loop:
	cmpeqi t0, s0, Y_LIMIT
	bne t0, zero, end_detect_full_line;if we reach the final line we exit the loop

inner_loop:
	cmpgei t0, s1, X_LIMIT
	bne t0, zero, inner_loop_exit ; if we reach the final colomn we go to the next line
	add a0, zero, s1
	add a1, zero, s0
	call get_gsa
	and s2, s2, v0
	addi s1, s1, 1 ; ++s1
	jmpi inner_loop 

inner_loop_exit:
	bne s2, zero, end_detect_full_line ; if s2 == 1 we found the line we wanted
	addi s2, zero ,1 ; else reset s2 to 1
	addi s0, s0, 1 ; increment s0 (the y counter)
	addi s1, zero, 0 ; reset s1 to 0 (the x counter)
	jmpi outer_loop
	 
end_detect_full_line:
	add v0 ,zero, s0
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 16
ret

; END:detect_full_line



; BEGIN:remove_full_line
remove_full_line:
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)

	addi s2, a0, 0
	
	addi a0, s2, 0
	addi a1, zero, NOTHING
	call set_gsa_line ; off
	call draw_gsa
	call wait

	addi a0, s2, 0
	addi a1, zero, PLACED
	call set_gsa_line ; on
	call draw_gsa
	call wait

	addi a0, s2, 0
	addi a1, zero, NOTHING
	call set_gsa_line ; off
	call draw_gsa
	call wait

	addi a0, s2, 0
	addi a1, zero, PLACED
	call set_gsa_line ; on
	call draw_gsa
	call wait

	addi a0, s2, 0
	addi a1, zero, NOTHING
	call set_gsa_line ; off
	call draw_gsa
	call wait



	add s0, zero, s2 ;y counter
	addi s1, zero, 0 ;x counter

remove_outer:
	beq s0, zero, remove_outer_exit ;this loop keeps going till the removed line
remove_inner:
	cmpgei t0, s1, X_LIMIT
	bne t0, zero, remove_inner_exit ; if we reach the final colomn we go to the next line
	
	add a0, zero, s1 ; set a0 to x
	
	addi a1, s0, -1
	call get_gsa
; we did this to retrieve the info of the above line then return s0 to its normal value

	add a0, zero, s1 ; set a0 to x
	addi a1, s0, 0

	add a2, zero ,v0
	call set_gsa
	
	addi s1, s1, 1 ; ++s1	

	jmpi  remove_inner

remove_inner_exit:
	addi s0, s0, -1 ; decrement s0 (the y counter)
	addi s1, zero, 0 ; reset s1 to 0 (the x counter)
	jmpi remove_outer

remove_outer_exit:
	addi a0, zero, 0
	addi a1, zero, NOTHING
	call set_gsa_line ;after a line deletion the first line is always empty

	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 16
ret

; END:remove_full_line


; BEGIN:helper
set_gsa_line: ;a0 = line's coords a1 = the state to be changed to
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)

	addi s0, zero, 0 ; x counter
	addi s2, a1, 0; constant p(state)
	addi s1, a0, 0; constant y
set_gsa_line_loop:
	cmpeqi t0, s0, X_LIMIT
	bne t0, zero, set_gsa_line_end
	add a0, zero, s0 ; x = x counter
	add a1, zero, s1
	add a2, zero, s2
	call set_gsa
	addi s0, s0, 1
	jmpi set_gsa_line_loop
	
set_gsa_line_end:
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 16
ret

divide_by_10:
	addi sp, sp, -24
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp)

	addi s0, a0, 0 ; s0 = n
	srli s1, s0, 1 ; (n >> 1)
	srli s2, a0, 2 ; (n >> 2)
	add s3, s1 , s2 ; q = (n >> 1) + (n >> 2)
	srli s1, s3, 4 ; (q  >> 4)
	add s2, s1, s3 ; q = q + (q >> 4)
	srli s3, s2, 8 ; (q >> 8)
	add s1, s2, s3 ; q = q + (q >> 8)
	srli s3, s1, 3 ; q = q >> 3
	slli s2, s3, 2; (q << 2)
	add s1, s3, s2 ; ((q << 2) + q)
	slli s1, s1, 1 ; (((q << 2) + q) << 1)
	sub s4, s0, s1 ; r = n - (((q << 2) + q) << 1)
	cmpgei s4, s4, 10 ; (r >= 10 === r > 9)
	add v0 , s4, s3

	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 24
	ret
; END:helper

; BEGIN:increment_score
increment_score:
	ldw t0, SCORE(zero)
	cmpeqi t1, t0, 9999
	bne t1, zero, increment_score_skipped
	addi t0, t0, 1
	stw t0, SCORE(zero)
increment_score_skipped:
	ret
; END:increment_score	

; BEGIN:display_score
display_score:
	addi sp, sp, -20
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)

	addi s3, zero, SEVEN_SEGS ; s3 = seven_segs
	ldw s0, SCORE(zero) ;s0 = score

	addi a0, s0, 0 ; a0 = score
	call divide_by_10
	slli s1, v0, 3
	slli s2, v0, 1
	add s1, s1, s2 ; s1 = (v0 // 10) * 10
	sub s2, s0, s1  ;(SCORE % 10)
	slli s2, s2, 2 ; *4 to lookup in fontdata
	ldw s2, font_data(s2) ;hex value to store in the seven seg
	stw s2, 12(s3) ; store in seven segs

	addi s0, v0, 0
	addi a0, s0, 0
	call divide_by_10 ; score // 100
	slli s1, v0, 3
	slli s2, v0, 1
	add s1, s1, s2 ; s1 = (v0 // 10) * 10
	sub s2, s0, s1 ;(SCORE/ 10 % 10)
	slli s2, s2, 2 ; *4 to lookup in fontdata
	ldw s2, font_data(s2) ;hex value to store in the seven seg
	stw s2, 8(s3) ; store in seven segs

	addi s0, v0, 0
	addi a0 ,s0 ,0
	call divide_by_10 ; score // 1000
	slli s1, v0, 3
	slli s2, v0, 1
	add s1, s1, s2 ; s1 = (v0 // 10) * 10
	sub s2, s0, s1 ;(SCORE/ 100 % 10)
	slli s2, s2, 2 ; *4 to lookup in fontdata
	ldw s2, font_data(s2) ;hex value to store in the seven seg
	stw s2, 4(s3) ; store in seven segs


	addi s0, v0, 0
	addi a0 ,s0 ,0
	call divide_by_10 ; score // 1000
	slli s1, v0, 3
	slli s2, v0, 1
	add s1, s1, s2 ; s1 = (v0 // 10) * 10
	sub s2, s0, s1 ;(SCORE/ 100 % 10)
	slli s2, s2, 2 ; *4 to lookup in fontdata
	ldw s2, font_data(s2) ;hex value to store in the seven seg
	stw s2, 0(s3) ; store in seven segs
	
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 20
	ret	
; END:display_score

; BEGIN:reset_game
reset_game:
	addi sp, sp, -12
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	

	addi s0, zero, 0
	addi s1, zero, Y_LIMIT
reset_lines_loop:
	bge s0, s1, reset_lines_end
	add a0, s0, zero
	addi a1, zero, NOTHING
	call set_gsa_line
	addi s0, s0, 1
	jmpi reset_lines_loop

reset_lines_end:

	stw zero, SCORE(zero)
	call display_score	

	call generate_tetromino

	addi a0, zero, FALLING
	call draw_tetromino

	call draw_gsa

	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 12

	ret
; END:reset_game

font_data:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y