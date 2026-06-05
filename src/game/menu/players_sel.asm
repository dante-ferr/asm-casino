; FSM State: Select Number of Players Screen and Logic

Run_Num_Players:
    rcall Show_Num_Players_Menu
num_players_loop:
    rcall Wait_Button_Press
    push temp
    
    pop temp
    cpi temp, 1            ; Button A -> Increment players
    brne num_players_check_b
    
    ; Get current count from RAM_NUM_PLAYERS
    lds temp2, RAM_NUM_PLAYERS
    inc temp2
    cpi temp2, MAX_PLAYERS + 1
    brlo save_num_players_inc
    ldi temp2, MIN_PLAYERS           ; wrap-around to MIN_PLAYERS
save_num_players_inc:
    sts RAM_NUM_PLAYERS, temp2
    rjmp num_players_tick
    
num_players_check_b:
    cpi temp, 2            ; Button B -> Decrement players
    brne num_players_select
    
    lds temp2, RAM_NUM_PLAYERS
    dec temp2
    cpi temp2, MIN_PLAYERS
    brsh save_num_players_dec
    ldi temp2, MAX_PLAYERS           ; wrap-around to MAX_PLAYERS
save_num_players_dec:
    sts RAM_NUM_PLAYERS, temp2
    rjmp num_players_tick
    
num_players_tick:
    rcall Buzzer_Tick
    rcall Show_Num_Players_Menu
    rjmp num_players_loop
    
num_players_select:
    cpi temp, 3            ; Button Select -> Confirm selection
    brne num_players_loop
    
    rcall Buzzer_Beep
    ldi fsm_state, STATE_MAIN_MENU
    ret

; Show select players screen on LCD
Show_Num_Players_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Draw group icon on LED matrix
    ldi ZL, low(icon_group * 2)
    ldi ZH, high(icon_group * 2)
    rcall Matrix_Draw_Icon
    
    rcall LCD_Clear
    
    ; Line 0: "Qtd Jogadores:"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_num_players_title * 2)
    ldi ZH, high(msg_num_players_title * 2)
    rcall LCD_Print_Msg
    
    ; Line 1: "[Num]     (A/B/S)"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    lds r24, RAM_NUM_PLAYERS
    clr r25
    rcall LCD_Print_Dec16
    
    ldi ZL, low(msg_num_players_keys * 2)
    ldi ZH, high(msg_num_players_keys * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret
