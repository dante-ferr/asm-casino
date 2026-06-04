; Betting Screens Layout and Rendering Logic

Show_Betting_Screen:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Update 7-segment display to show current player ID
    sts RAM_ROUND_NUM, active_plyr
    
    ; Update RGB LED color to match current player ID
    mov temp, active_plyr
    rcall RGB_Set_By_Player
    
    rcall LCD_Clear
    
    ; 1. Draw question mark icon on matrix
    ldi ZL, low(icon_question * 2)
    ldi ZH, high(icon_question * 2)
    rcall Matrix_Draw_Icon
    
    rcall Player_Get_Pointer
    ldd temp, Z+2           ; Load status
    sbrc temp, 0            ; Skip if NOT En Prison
    rjmp show_betting_prison
    
    ; Check which mode we are in (sys_flags: 0 = Target, 1 = Value, 2 = Confirm)
    mov temp, sys_flags
    andi temp, 0x7F         ; clear bit 7 (toggle bit) for mode comparison
    
    cpi temp, 2             ; Confirm mode?
    brne show_betting_normal
    rjmp show_betting_confirm
show_betting_normal:
    
    ; --- TARGET & VALUE EDIT MODES ---
    ; Line 0: "P[ID]: [Target] [Cursor]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    ldi temp, ':'
    rcall lcd_write_data
    ldi temp, ' '
    rcall lcd_write_data
    
    rcall Player_Get_Pointer
    ldd temp, Z+4           ; selection index (0-42)
    
    ; Display target name
    cpi temp, FIRST_INTERNAL_IDX
    brsh show_tgt_num
    
    ; External Target (0-5)
    ldi ZL, low(target_strings_table * 2)
    ldi ZH, high(target_strings_table * 2)
    add ZL, temp
    add ZL, temp            ; index * 2
    clr temp2
    adc ZH, temp2
    
    lpm temp, Z+
    lpm temp2, Z
    mov ZL, temp
    mov ZH, temp2
    rcall LCD_Print_Msg
    rjmp show_tgt_cursor_check
    
show_tgt_num:
    ; Print "NUM: [temp - FIRST_INTERNAL_IDX]"
    ldi ZL, low(msg_num_prefix * 2)
    ldi ZH, high(msg_num_prefix * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Pointer
    ldd r24, Z+4
    subi r24, FIRST_INTERNAL_IDX
    clr r25
    rcall LCD_Print_Dec16
    
show_tgt_cursor_check:
    ; Print cursor '<' if sys_flags (mode) is 0
    mov temp, sys_flags
    andi temp, 0x7F
    tst temp
    brne show_bet_val_line
    
    ldi temp, ' '
    rcall lcd_write_data
    ldi temp, '<'
    rcall lcd_write_data
    
show_bet_val_line:
    ; Line 1: "Apos: [Val] [Cursor] (A/B/S)"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi ZL, low(msg_bet_val_label * 2)
    ldi ZH, high(msg_bet_val_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Pointer
    ldd r25, Z+5
    ldd r24, Z+6
    rcall LCD_Print_Dec16
    
    ; Print cursor '<' if sys_flags (mode) is 1
    mov temp, sys_flags
    andi temp, 0x7F
    cpi temp, 1
    brne show_bet_val_keys
    
    ldi temp, ' '
    rcall lcd_write_data
    ldi temp, '<'
    rcall lcd_write_data
    
show_bet_val_keys:
    ldi ZL, low(msg_bet_keys_label * 2)
    ldi ZH, high(msg_bet_keys_label * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

show_betting_confirm:
    ; Line 0: "P[ID] Conf: [SIM / VOLTAR]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ; Print " Conf: "
    ldi ZL, low(msg_conf_prefix * 2)
    ldi ZH, high(msg_conf_prefix * 2)
    rcall LCD_Print_Msg
    
    ; Check if bit 7 of sys_flags is set (VOLTAR) or clear (SIM)
    sbrc sys_flags, 7
    rjmp show_conf_voltar
    
    ldi ZL, low(msg_conf_sim * 2)
    ldi ZH, high(msg_conf_sim * 2)
    rcall LCD_Print_Msg
    rjmp show_conf_val_line
    
show_conf_voltar:
    ldi ZL, low(msg_conf_voltar * 2)
    ldi ZH, high(msg_conf_voltar * 2)
    rcall LCD_Print_Msg
    
show_conf_val_line:
    ; Line 1: "Apos: [Val] (A/B/S)"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi ZL, low(msg_bet_val_label * 2)
    ldi ZH, high(msg_bet_val_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Pointer
    ldd r25, Z+5
    ldd r24, Z+6
    rcall LCD_Print_Dec16
    
    ldi ZL, low(msg_bet_keys_label * 2)
    ldi ZH, high(msg_bet_keys_label * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

show_betting_prison:
    ; Line 0: "P[ID]: PRISAO"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ldi ZL, low(msg_bet_prison_status * 2)
    ldi ZH, high(msg_bet_prison_status * 2)
    rcall LCD_Print_Msg
    
    ; Line 1: "Apos: [Val] (S)"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi ZL, low(msg_bet_val_label * 2)
    ldi ZH, high(msg_bet_val_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Pointer
    ldd r25, Z+5
    ldd r24, Z+6
    rcall LCD_Print_Dec16
    
    ldi ZL, low(msg_bet_prison_keys * 2)
    ldi ZH, high(msg_bet_prison_keys * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret
