; FSM State: Welcome Splash Screen and Logic
; Shows the name of the game on LCD, and animates a spinning roulette on the matrix.
; Transitions to STATE_NUM_PLAYERS upon any button press.

Run_Welcome:
    push r18
    push r19
    push r22
    push r23
    
welcome_restart_melody:
    rcall Show_Welcome_Screen
    
welcome_melody_loop:
    rcall Buzzer_Play_Current_Track
    tst temp
    breq welcome_melody_loop          ; if finished normally, loop/restart it!
    
    ; Button was pressed!
    cpi temp, 3                       ; Select button?
    brne welcome_button_pressed       ; A or B -> transition to player selection
    
    ; Wait for Select to be released
wait_select_release:
    rcall Read_Buttons
    tst temp
    brne wait_select_release

    ; Select released -> Toggle track index (0 -> 1 -> 0)
    lds temp2, RAM_CURRENT_TRACK
    inc temp2
    cpi temp2, 2                      ; 2 tracks
    brlo save_track
    ldi temp2, 0
save_track:
    sts RAM_CURRENT_TRACK, temp2
    
    ; Play switch track confirmation sound
    rcall Buzzer_Beep
    
    rjmp welcome_restart_melody

welcome_button_pressed:
    ; Wait for the button to be released
wait_welcome_release:
    rcall Read_Buttons
    tst temp
    brne wait_welcome_release

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


