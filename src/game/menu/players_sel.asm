; Estado da FSM: Tela e lógica de seleção do número de jogadores

Run_Num_Players:
    rcall Show_Num_Players_Menu
num_players_loop:
    rcall Wait_Button_Press
    push temp
    
    pop temp
    cpi temp, 2 ; Botão B -> incrementa jogadores
    brne num_players_check_b
    
    ; Lê a quantidade atual de jogadores
    lds temp2, RAM_NUM_PLAYERS
    inc temp2
    cpi temp2, MAX_PLAYERS + 1
    brlo save_num_players_inc
    ldi temp2, MIN_PLAYERS ; retorna para o mínimo
save_num_players_inc:
    sts RAM_NUM_PLAYERS, temp2
    rjmp num_players_tick
    
num_players_check_b:
    cpi temp, 1 ; Botão A -> decrementa jogadores
    brne num_players_select
    
    lds temp2, RAM_NUM_PLAYERS
    dec temp2
    cpi temp2, MIN_PLAYERS
    brsh save_num_players_dec
    ldi temp2, MAX_PLAYERS ; retorna para o máximo
save_num_players_dec:
    sts RAM_NUM_PLAYERS, temp2
    rjmp num_players_tick
    
num_players_tick:
    rcall Buzzer_Tick
    rcall Show_Num_Players_Menu
    rjmp num_players_loop
    
num_players_select:
    cpi temp, 3 ; Botão Select -> confirma a seleção
    brne num_players_loop
    
    rcall Buzzer_Beep
    ldi fsm_state, STATE_MAIN_MENU
    ret

; Exibe a tela de seleção de jogadores no LCD
Show_Num_Players_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Desenha o ícone do grupo na matriz de LEDs
    ldi ZL, low(icon_group * 2)
    ldi ZH, high(icon_group * 2)
    rcall Matrix_Draw_Icon
    
    rcall LCD_Clear
    
    ; Linha 0
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_num_players_title * 2)
    ldi ZH, high(msg_num_players_title * 2)
    rcall LCD_Print_Msg
    
    ; Linha 1
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
