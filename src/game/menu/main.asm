; Game Main Menu Module

Run_Main_Menu:
    rcall Show_Player_Menu

test_button_loop:
    rcall Wait_Button_Press
    push temp

    pop temp
    cpi temp, 1            ; Button A -> Switch active player
    brne check_btn_b
    
; Cycle player ID (1 -> 2 -> ... -> RAM_NUM_PLAYERS -> 1)
    mov temp2, active_plyr
    inc temp2
    lds temp, RAM_NUM_PLAYERS
    inc temp
    cp temp2, temp
    brlo update_active_plyr
    ldi temp2, MIN_PLAYERS
update_active_plyr:
    mov active_plyr, temp2
    
    ; Update 7-segment display to show active player ID (01-04)
    sts RAM_ROUND_NUM, active_plyr
    
    ; Update RGB LED color to match player ID
    mov temp, active_plyr
    rcall RGB_Set_By_Player
    
    ; Play click sound
    rcall Buzzer_Tick
    
    ; Refresh LCD display
    rcall Show_Player_Menu
    rjmp test_button_loop

check_btn_b:
    cpi temp, 2            ; Button B -> Enter credit setting screen
    brne check_btn_select
    
    ; Switch FSM state and exit Run_Main_Menu
    ldi fsm_state, STATE_SET_CREDITS
    ret

check_btn_select:
    cpi temp, 3            ; Button Select -> Enter betting phase
    brne test_button_loop
    
    ; Play confirmation beep
    rcall Buzzer_Beep
    
    ; Initialize FSM state to STATE_CHOOSE_CAT (Betting Phase) for Player 1
    ldi fsm_state, STATE_CHOOSE_CAT
    ldi active_plyr, 1      ; Start with Player 1
    ret

; Show player ID and balance on LCD
Show_Player_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Update 7-segment display to show active player ID
    sts RAM_ROUND_NUM, active_plyr
    
    ; Update RGB LED color to match player ID
    mov temp, active_plyr
    rcall RGB_Set_By_Player
    
    ; Draw avatar icon on LED matrix
    ldi ZL, low(icon_avatar * 2)
    ldi ZH, high(icon_avatar * 2)
    rcall Matrix_Draw_Icon
    
    rcall LCD_Clear
    
    ; Line 0: "P[ID] Bal: [Value]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ; Check if active player is in prison
    rcall Player_Get_Pointer
    ldd temp, Z+2           ; Z+2 = status byte
    sbrc temp, 0            ; Skip printing indicator if not in prison (bit 0 is 0)
    rjmp print_prison_indicator
    rjmp print_bal_label_msg
    
print_prison_indicator:
    ; Print prison indicator
    ldi temp, '('
    rcall lcd_write_data
    ldi temp, 'P'
    rcall lcd_write_data
    ldi temp, ')'
    rcall lcd_write_data
    
print_bal_label_msg:
    ldi ZL, low(msg_bal_label * 2)
    ldi ZH, high(msg_bal_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    rcall LCD_Print_Dec16
    
    ; Line 1: "A:Mudar B:Cred S:Gira"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_menu_line1 * 2)
    ldi ZH, high(msg_menu_line1 * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

; Submodule Inclusions
.include "game/menu/credits.asm"
.include "game/menu/players_sel.asm"
.include "game/menu/welcome.asm"
.include "game/menu/strings.asm"

