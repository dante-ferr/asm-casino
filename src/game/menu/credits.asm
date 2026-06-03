; FSM State: Set Credits Screen and Logic

Run_Set_Credits:
    rcall Show_Credits_Menu
set_credits_loop:
    rcall Wait_Button_Press
    push temp
    
    pop temp
    cpi temp, 1            ; Button A -> Add 100 points
    brne set_credits_b
    
    ; Get current balance (r25:r24)
    rcall Player_Get_Balance
    
    ; Check maximum limit (9900 points)
    cpi r24, low(9900)
    ldi temp2, high(9900)
    cpc r25, temp2
    brsh set_credits_tick   ; Skip addition if already >= 9900
    
    ; Add 100 points
    ldi temp2, 100
    add r24, temp2
    ldi temp2, 0
    adc r25, temp2
    rcall Player_Set_Balance
    
set_credits_tick:
    rcall Buzzer_Tick
    rcall Show_Credits_Menu
    rjmp set_credits_loop
    
set_credits_b:
    cpi temp, 2            ; Button B -> Subtract 100 points
    brne set_credits_select
    
    ; Get current balance (r25:r24)
    rcall Player_Get_Balance
    
    ; Check minimum limit (0 points)
    cpi r24, 0
    ldi temp2, 0
    cpc r25, temp2
    breq set_credits_tick   ; Skip subtraction if already 0
    
    ; Subtract 100 points
    ldi temp2, 100
    sub r24, temp2
    ldi temp2, 0
    sbc r25, temp2
    rcall Player_Set_Balance
    rjmp set_credits_tick
    
set_credits_select:
    cpi temp, 3            ; Button Select -> Confirm and return to Main Menu
    brne set_credits_loop
    
    ; Play confirmation beep
    rcall Buzzer_Beep
    
    ; Switch state back to Main Menu
    ldi fsm_state, STATE_MAIN_MENU
    ret

; Show player credit configuration screen
Show_Credits_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Draw dollar sign icon on LED matrix
    ldi ZL, low(icon_dollar * 2)
    ldi ZH, high(icon_dollar * 2)
    rcall Matrix_Draw_Icon
    
    rcall LCD_Clear
    
    ; Line 0: "P[ID] Set Bal: [Val]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ldi ZL, low(msg_set_bal_label * 2)
    ldi ZH, high(msg_set_bal_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    rcall LCD_Print_Dec16
    
    ; Line 1: "A:+100 B:-100 S:OK"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_credits_line1 * 2)
    ldi ZH, high(msg_credits_line1 * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret
