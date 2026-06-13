; Layout das telas de apostas e lógica de renderização

Show_Betting_Screen:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Atualiza o display de 7 segmentos com o ID do jogador atual
    sts RAM_ROUND_NUM, active_plyr
    
    ; Atualiza a cor do LED RGB correspondente ao ID do jogador
    mov temp, active_plyr
    call RGB_Set_By_Player
    
    call LCD_Clear
    
    ; Desenha o ícone de interrogação na matriz
    ldi ZL, low(icon_question * 2)
    ldi ZH, high(icon_question * 2)
    call Matrix_Draw_Icon
    
    call Player_Get_Pointer
    ldd temp, Z+2 ; lê o byte de status
    sbrc temp, 0 ; pula se NÃO estiver na prisão
    rjmp show_betting_prison
    
    ; Verifica o modo de edição (0 = Alvo, 1 = Valor, 2 = Confirmação)
    mov temp, sys_flags
    andi temp, 0x7F ; limpa o bit 7 para comparação de modo
    
    cpi temp, 2 ; Modo confirmação?
    brne show_betting_normal
    rjmp show_betting_confirm
    show_betting_normal:
        
        ; --- MODOS DE EDIÇÃO DE ALVO E VALOR ---
        ; Linha 0: "P[ID]: [Target] [Cursor]"
        ; Posiciona o cursor no início da linha 0
        ldi temp, 0
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ; Escreve "P[ID]: " no display LCD
        ldi temp, 'P'
        call lcd_write_data ; Escreve o caractere 'P'
        mov temp, active_plyr
        subi temp, -'0'
        call lcd_write_data ; Escreve o ID do jogador ativo convertido em caractere
        ldi temp, ':'
        call lcd_write_data ; Escreve ':'
        ldi temp, ' '
        call lcd_write_data ; Escreve o espaço em branco
        
        call Player_Get_Pointer
        ldd temp, Z+4 ; índice de seleção
        
        ; Exibe o nome do alvo
        cpi temp, FIRST_INTERNAL_IDX
        brsh show_tgt_num
        
        ; Alvo externo
        ldi ZL, low(target_strings_table * 2)
        ldi ZH, high(target_strings_table * 2)
        add ZL, temp
        add ZL, temp ; multiplica índice por 2
        clr temp2
        adc ZH, temp2
        
        lpm temp, Z+
        lpm temp2, Z
        mov ZL, temp
        mov ZH, temp2
        call LCD_Print_Msg
        rjmp show_tgt_cursor_check
        
    show_tgt_num:
        ; Imprime o prefixo do número interno
        ldi ZL, low(msg_num_prefix * 2)
        ldi ZH, high(msg_num_prefix * 2)
        call LCD_Print_Msg
        
        call Player_Get_Pointer
        ldd r24, Z+4
        subi r24, FIRST_INTERNAL_IDX
        clr r25
        call LCD_Print_Dec16
        
    show_tgt_cursor_check:
        ; Imprime o cursor '<' se o modo for 0 (Edição de Alvo)
        mov temp, sys_flags
        andi temp, 0x7F
        tst temp
        brne show_bet_val_line
        
        ldi temp, ' '
        call lcd_write_data
        ldi temp, '<'
        call lcd_write_data
        
    show_bet_val_line:
        ; Linha 1: "Aposta: [Val] [Cursor] (A/B/S)"
        ldi temp, 1
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ldi ZL, low(msg_bet_val_label * 2)
        ldi ZH, high(msg_bet_val_label * 2)
        call LCD_Print_Msg
        
        call Player_Get_Pointer
        ldd r25, Z+5
        ldd r24, Z+6
        call LCD_Print_Dec16
        
        ; Imprime o cursor '<' se o modo for 1 (Edição de Valor)
        mov temp, sys_flags
        andi temp, 0x7F
        cpi temp, 1
        brne show_bet_val_keys
        
        ; Escreve o cursor " <" para indicar o campo ativo de valor
        ldi temp, ' '
        call lcd_write_data
        ldi temp, '<'
        call lcd_write_data
        
    show_bet_val_keys:
        ldi ZL, low(msg_bet_keys_label * 2)
        ldi ZH, high(msg_bet_keys_label * 2)
        call LCD_Print_Msg
        
        pop ZH
        pop ZL
        pop r25
        pop r24
        pop temp2
        pop temp
        ret
     
    show_betting_confirm:
        ; Linha 0: "P[ID] Conf: [SIM / VOLTAR]"
        ; Posiciona o cursor no início da linha 0 para confirmação
        ldi temp, 0
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ; Escreve "P[ID]" no início da tela de confirmação
        ldi temp, 'P'
        call lcd_write_data
        mov temp, active_plyr
        subi temp, -'0'
        call lcd_write_data
        
        ; Imprime o prefixo de confirmação
        ldi ZL, low(msg_conf_prefix * 2)
        ldi ZH, high(msg_conf_prefix * 2)
        call LCD_Print_Msg
        
        ; Verifica o bit 7 de sys_flags (VOLTAR ou SIM)
        sbrc sys_flags, 7
        rjmp show_conf_voltar
        
        ldi ZL, low(msg_conf_sim * 2)
        ldi ZH, high(msg_conf_sim * 2)
        call LCD_Print_Msg
        rjmp show_conf_val_line
        
    show_conf_voltar:
        ldi ZL, low(msg_conf_voltar * 2)
        ldi ZH, high(msg_conf_voltar * 2)
        call LCD_Print_Msg
        
    show_conf_val_line:
        ; Linha 1: "Aposta: [Val] (A/B/S)"
        ldi temp, 1
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ldi ZL, low(msg_bet_val_label * 2)
        ldi ZH, high(msg_bet_val_label * 2)
        call LCD_Print_Msg
        
        call Player_Get_Pointer
        ldd r25, Z+5
        ldd r24, Z+6
        call LCD_Print_Dec16
        
        ldi ZL, low(msg_bet_keys_label * 2)
        ldi ZH, high(msg_bet_keys_label * 2)
        call LCD_Print_Msg
        
        pop ZH
        pop ZL
        pop r25
        pop r24
        pop temp2
        pop temp
        ret
     
    show_betting_prison:
        ; Linha 0: "P[ID]: PRISÃO"
        ; Posiciona o cursor no início da linha 0 para o estado de prisão
        ldi temp, 0
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ; Escreve "P[ID]" no cabeçalho
        ldi temp, 'P'
        call lcd_write_data
        mov temp, active_plyr
        subi temp, -'0'
        call lcd_write_data
        
        ldi ZL, low(msg_bet_prison_status * 2)
        ldi ZH, high(msg_bet_prison_status * 2)
        call LCD_Print_Msg
        
        ; Linha 1: "Aposta: [Val] (S)"
        ldi temp, 1
        ldi temp2, 0
        call LCD_Set_Cursor
        
        ldi ZL, low(msg_bet_val_label * 2)
        ldi ZH, high(msg_bet_val_label * 2)
        call LCD_Print_Msg
        
        call Player_Get_Pointer
        ldd r25, Z+5
        ldd r24, Z+6
        call LCD_Print_Dec16
        
        ldi ZL, low(msg_bet_prison_keys * 2)
        ldi ZH, high(msg_bet_prison_keys * 2)
        call LCD_Print_Msg
        
        pop ZH
        pop ZL
        pop r25
        pop r24
        pop temp2
        pop temp
        ret
