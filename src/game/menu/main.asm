; Módulo do menu principal do jogo

Run_Main_Menu:
    rcall Show_Player_Menu

    test_button_loop:
        rcall Wait_Button_Press
        push temp

        pop temp
        cpi temp, 1 ; Botão A -> troca o jogador ativo
        brne check_btn_b
        
        ; Alterna o ID do jogador (1 até o número de jogadores ativos)
        mov temp2, active_plyr
        inc temp2
        lds temp, RAM_NUM_PLAYERS
        inc temp
        cp temp2, temp
        brlo update_active_plyr
        ldi temp2, MIN_PLAYERS
    update_active_plyr:
        mov active_plyr, temp2
        
        ; Atualiza o display de 7 segmentos com o ID do jogador ativo
        sts RAM_ROUND_NUM, active_plyr
        
        ; Atualiza a cor do LED RGB correspondente ao ID do jogador
        mov temp, active_plyr
        rcall RGB_Set_By_Player
        
        ; Toca som de clique
        rcall Buzzer_Tick
        
        ; Atualiza o display LCD
        rcall Show_Player_Menu
        rjmp test_button_loop

    check_btn_b:
        cpi temp, 2 ; Botão B -> entra na tela de configuração de créditos
        brne check_btn_select
        
        ; Altera o estado da FSM e retorna
        ldi fsm_state, STATE_SET_CREDITS
        ret

check_btn_select:
    cpi temp, 3 ; Botão Select -> entra na fase de apostas
    brne test_button_loop
    
    ; Toca bipe de confirmação
    rcall Buzzer_Beep
    
    ; Inicializa as apostas de todos os jogadores para começar limpo
    rcall Init_Players_Bets_For_Round
    
    ; Define o estado da FSM como STATE_CHOOSE_CAT para o jogador 1
    ldi fsm_state, STATE_CHOOSE_CAT
    ldi active_plyr, 1 ; começa no jogador 1
    ret

; Exibe o ID do jogador e o saldo no LCD
Show_Player_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    ; Atualiza o display de 7 segmentos
    sts RAM_ROUND_NUM, active_plyr
    
    ; Atualiza a cor do LED RGB
    mov temp, active_plyr
    rcall RGB_Set_By_Player
    
    ; Desenha o ícone do avatar na matriz de LEDs
    ldi ZL, low(icon_avatar * 2)
    ldi ZH, high(icon_avatar * 2)
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
    
    ; Verifica se o jogador ativo está na prisão
    rcall Player_Get_Pointer
    ldd temp, Z+2 ; status byte no offset 2
    sbrc temp, 0 ; pula a impressão se não estiver na prisão
    rjmp print_prison_indicator
    rjmp print_bal_label_msg
    
    print_prison_indicator:
        ; Imprime o indicador de prisão "(P)" caractere por caractere
        ldi temp, '('
        rcall lcd_write_data ; Escreve '('
        ldi temp, 'P'
        rcall lcd_write_data ; Escreve 'P'
        ldi temp, ')'
        rcall lcd_write_data ; Escreve ')'
        
    print_bal_label_msg:
        ldi ZL, low(msg_bal_label * 2)
        ldi ZH, high(msg_bal_label * 2)
        rcall LCD_Print_Msg
        
        rcall Player_Get_Balance ; retorna o saldo em r25:r24
        rcall LCD_Print_Dec16
        
        ; Linha 1
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

; Inclusão de subódulos
.include "game/menu/credits.asm"
.include "game/menu/players_sel.asm"
.include "game/menu/welcome.asm"
.include "game/menu/strings.asm"

