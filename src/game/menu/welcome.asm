; FSM State: Welcome Splash Screen and Logic
; Shows the name of the game on LCD, and animates a spinning roulette on the matrix.
; Transitions to STATE_NUM_PLAYERS upon any button press.

Run_Welcome:
    push r18
    push r19
    push r22
    push r23
    
    rcall Show_Welcome_Screen
    
    ; Start ball position L = 0
    ldi r18, 0
    
welcome_main_loop:
    ; Draw a random number of steps for Phase 1 to vary the final stop position
    rcall PRNG_Spin         ; returns 0-36 in temp2
    mov r19, temp2          ; r19 = 0-36
    subi r19, -40           ; r19 = 40 + (0 to 36) = 40 to 76 steps
    
    ; --- PHASE 1: SPIN FAST (r19 steps, 40ms delay) ---
spin_fast_loop:
    mov temp2, r18
    ldi temp, 0x80          ; center diamond
    rcall Matrix_Render_Frame
    
    ldi temp, 40            ; 40 ms delay
    rcall welcome_delay_and_check
    tst temp
    brne welcome_button_pressed
    
    inc r18
    cpi r18, 20
    brlo spin_fast_no_wrap
    ldi r18, 0
spin_fast_no_wrap:
    dec r19
    brne spin_fast_loop
    
    ; --- PHASE 2: DECELERATE (20 steps, delay increases from 40ms to 320ms) ---
    ldi r19, 20             ; Step counter
    ldi r22, 40             ; Initial delay (40ms)
spin_decel_loop:
    mov temp2, r18
    ldi temp, 0x80
    rcall Matrix_Render_Frame
    
    mov temp, r22
    rcall welcome_delay_and_check
    tst temp
    brne welcome_button_pressed
    
    inc r18
    cpi r18, 20
    brlo spin_decel_no_wrap
    ldi r18, 0
spin_decel_no_wrap:
    subi r22, -14           ; delay = delay + 14 ms
    dec r19
    brne spin_decel_loop
    
    ; --- PHASE 3: STOPPED (1 second delay) ---
    ; Decrement r18 to go back to the exact rest position (r18 - 1, with wrap-under)
    subi r18, 1
    brcc welcome_decel_no_underflow
    ldi r18, 19
welcome_decel_no_underflow:
    
    ; Render static stopped position at the rest slot
    mov temp2, r18
    ldi temp, 0x80
    rcall Matrix_Render_Frame
    
    ; Delay 1000 ms (1 second) while checking buttons in blocks of 10ms
    ldi r23, 100            ; 100 * 10 ms = 1000 ms
stop_delay_loop:
    ldi temp, 10
    rcall welcome_delay_and_check
    tst temp
    brne welcome_button_pressed
    dec r23
    brne stop_delay_loop
    
    ; Repeat welcome spin main loop
    rjmp welcome_main_loop

welcome_button_pressed:
    ; Play confirmation beep
    rcall Buzzer_Beep
    
    ; Transition state to STATE_NUM_PLAYERS
    ldi fsm_state, STATE_NUM_PLAYERS
    
    pop r23
    pop r22
    pop r19
    pop r18
    ret

Show_Welcome_Screen:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    rcall LCD_Clear
    
    ; Line 0: "Roleta Francesa"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_welcome_title * 2)
    ldi ZH, high(msg_welcome_title * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

; Helper: delay for N ms while polling buttons
; Input: temp = delay duration in ms
; Output: temp = pressed button code (0 if none)
welcome_delay_and_check:
    push temp2
    mov temp2, temp         ; temp2 = remaining ms
welcome_delay_loop:
    rcall Read_Buttons      ; read buttons (returns 0-3 in temp)
    tst temp
    brne welcome_delay_exit ; if a button is pressed, return immediately!
    
    ldi temp, 10
    rcall delay_ms
    
    subi temp2, 10
    brcc welcome_delay_loop ; loop until temp2 < 10
    
    ldi temp, 0             ; return 0 (no button pressed)
welcome_delay_exit:
    pop temp2
    ret
