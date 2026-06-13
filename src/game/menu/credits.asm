; Estado da FSM: Tela e lógica de configuração de créditos

Run_Set_Credits:
    rcall Show_Credits_Menu
    set_credits_loop:
        rcall Wait_Button_Press
        push temp
        
        pop temp
        cpi temp, 2 ; Botão B -> adiciona 100 pontos
        brne set_credits_b
        
        ; Lê o saldo atual (r25:r24)
        rcall Player_Get_Balance
        
        ; Verifica o limite máximo
        cpi r24, low(CREDIT_MAX_LIMIT)
        ldi temp2, high(CREDIT_MAX_LIMIT)
        cpc r25, temp2
        brsh set_credits_tick ; ignora a adição se já estiver no limite máximo
        
        ; Adiciona os pontos do passo de crédito
        ldi temp2, low(CREDIT_STEP)
        add r24, temp2
        ldi temp2, high(CREDIT_STEP)
        adc r25, temp2
        rcall Player_Set_Balance
        
    set_credits_tick:
        rcall Buzzer_Tick
        rcall Show_Credits_Menu
        rjmp set_credits_loop
        
    set_credits_b:
        cpi temp, 1 ; Botão A -> subtrai 100 pontos
        brne set_credits_select
        
        ; Lê o saldo atual (r25:r24)
        rcall Player_Get_Balance
        
        ; Verifica o limite mínimo
        cpi r24, low(CREDIT_MIN_LIMIT)
        ldi temp2, high(CREDIT_MIN_LIMIT)
        cpc r25, temp2
        breq set_credits_tick ; ignora a subtração se já estiver no limite mínimo
        
        ; Subtrai os pontos do passo de crédito
        ldi temp2, low(CREDIT_STEP)
        sub r24, temp2
        ldi temp2, high(CREDIT_STEP)
        sbc r25, temp2
        rcall Player_Set_Balance
        rjmp set_credits_tick
        
    set_credits_select:
        cpi temp, 3 ; Botão Select -> confirma e retorna ao Menu Principal
        brne set_credits_loop
        
        ; Toca o bipe de confirmação
        rcall Buzzer_Beep
        
        ; Retorna para o estado do Menu Principal
        ldi fsm_state, STATE_MAIN_MENU
        ret

; Exibe a tela de configuração de créditos do jogador
Show_Credits_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Desenha o ícone de cifrão na matriz de LEDs
    ldi ZL, low(icon_dollar * 2)
    ldi ZH, high(icon_dollar * 2)
    rcall Matrix_Draw_Icon
    
    rcall LCD_Clear
    
    ; Linha 0
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
    
    rcall Player_Get_Balance ; retorna o saldo em r25:r24
    rcall LCD_Print_Dec16
    
    ; Linha 1
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
