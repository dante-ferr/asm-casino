; Lógica da FSM para o giro e resolução do jogo

Run_Spin_Roulette:
    ; Exibe a mensagem de giro
    call LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    call LCD_Set_Cursor
    ldi ZL, low(msg_spinning * 2)
    ldi ZH, high(msg_spinning * 2)
    call LCD_Print_Msg
    
    ; Executa a sequência de animação do giro
    call Run_Roulette_Spin_Sequence ; retorna o número sorteado em temp2 e salva em RAM_ROUND_NUM
    
    ; Transiciona para a resolução
    ldi fsm_state, STATE_RESOLUTION
    ret

Run_Resolution:
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ldi active_plyr, 1 ; começa no jogador 1
resolution_plyr_loop:
    call Player_Get_Pointer ; Z aponta para o jogador
    
    ; Carrega os detalhes da aposta antes que Calculate_Payout os limpe
    ldd r23, Z+2 ; status
    ldd r22, Z+3 ; tipo
    ldd r20, Z+4 ; alvo
    ldd r19, Z+5 ; valor (byte alto)
    ldd r18, Z+6 ; valor (byte baixo)
    
    push r23
    push r22
    push r20
    push r19
    push r18
    
    call Calculate_Payout ; calcula o pagamento, atualiza saldo/status e limpa a aposta
    
    pop r18
    pop r19
    pop r23
    pop r22
    pop r20
    
    ; Limpa o LCD
    call LCD_Clear
    
    ; Imprime o identificador do jogador na linha 0
    ldi temp, 0
    ldi temp2, 0
    call LCD_Set_Cursor
    
    ldi temp, 'P'
    call lcd_write_data
    mov temp, active_plyr
    subi temp, -'0'
    call lcd_write_data
    
    ; Verifica se o valor da aposta foi 0
    mov temp, r18
    or temp, r19
    brne resolution_has_bet
    
    ; Sem aposta -> exibe que o jogador passou
    ldi ZL, low(msg_p_passed * 2)
    ldi ZH, high(msg_p_passed * 2)
    call LCD_Print_Msg
    rjmp resolution_show_balance
    
resolution_has_bet:
    ; Verifica se o jogador estava na prisão
    sbrc r20, 0
    rjmp resolution_was_prison
    
    ; Não estava na prisão -> verifica se foi para a prisão agora
    call Player_Get_Pointer
    ldd temp, Z+2
    sbrc temp, 0
    rjmp resolution_went_prison
    
    ; Verificação normal de vitória ou derrota
    lds r20, RAM_ROUND_NUM
    mov temp, r22 ; tipo
    mov temp2, r23 ; alvo
    call Check_Bet_Win ; retorna temp = 1 (Vitória) ou 0 (Derrota)
    tst temp
    breq resolution_normal_loss
    
    ; Vitória normal!
    call Buzzer_Success
    ldi ZL, low(msg_p_won_prefix * 2)
    ldi ZH, high(msg_p_won_prefix * 2)
    call LCD_Print_Msg
    
    ; Imprime o valor ganho
    cpi r22, 1 ; Externa?
    breq print_ext_win_val
    
    ; Vitória interna: multiplica o valor da aposta por 35
    mov r24, r18
    mov r25, r19
    clr r22
    clr r23
    ldi temp, MULTIPLIER_INTERNAL_PAYOUT
mul_35_loop:
    add r22, r24
    adc r23, r25
    dec temp
    brne mul_35_loop
    mov r24, r22
    mov r25, r23
    call LCD_Print_Dec16
    rjmp resolution_show_balance
    
print_ext_win_val:
    mov r24, r18
    mov r25, r19
    call LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_normal_loss:
    call Buzzer_Failure
    ldi ZL, low(msg_p_lost_prefix * 2)
    ldi ZH, high(msg_p_lost_prefix * 2)
    call LCD_Print_Msg
    mov r24, r18
    mov r25, r19
    call LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_went_prison:
    ldi ZL, low(msg_p_went_prison * 2)
    ldi ZH, high(msg_p_went_prison * 2)
    call LCD_Print_Msg
    rjmp resolution_show_balance
    
resolution_was_prison:
    ; Estava na prisão -> verifica se ganhou (libertado)
    lds r20, RAM_ROUND_NUM
    mov temp, r22 ; tipo
    mov temp2, r23 ; alvo
    call Check_Bet_Win
    tst temp
    breq resolution_prison_loss
    
    ; Libertado!
    call Buzzer_Success
    ldi ZL, low(msg_p_win_ext * 2)
    ldi ZH, high(msg_p_win_ext * 2)
    call LCD_Print_Msg
    mov r24, r18
    mov r25, r19
    call LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_prison_loss:
    call Buzzer_Failure
    ldi ZL, low(msg_p_lost_prison * 2)
    ldi ZH, high(msg_p_lost_prison * 2)
    call LCD_Print_Msg
    
resolution_show_balance:
    ; Linha 1
    ldi temp, 1
    ldi temp2, 0
    call LCD_Set_Cursor
    
    ldi ZL, low(msg_novo_bal * 2)
    ldi ZH, high(msg_novo_bal * 2)
    call LCD_Print_Msg
    
    call Player_Get_Balance ; retorna o saldo em r25:r24
    call LCD_Print_Dec16
    
    ; Aguarda um tempo dinâmico para os jogadores lerem o resultado
    push temp2
    ldi temp2, RESULT_DELAY_COUNT
resolution_delay_loop:
    ldi temp, 250
    call delay_ms
    dec temp2
    brne resolution_delay_loop
    pop temp2
    
    ; Loop para o próximo jogador
    inc active_plyr
    lds temp, RAM_NUM_PLAYERS
    inc temp
    cp active_plyr, temp
    brlo resolution_plyr_loop_jmp
    rjmp resolution_finished
    
resolution_plyr_loop_jmp:
    rjmp resolution_plyr_loop
    
resolution_finished:
    ldi active_plyr, 1 ; comecar no jogador 1
    ldi fsm_state, STATE_MAIN_MENU
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    ret

Run_En_Prison:
    ret

; Inclusão de subódulos
.include "game/resolution/spin_seq.asm"
.include "game/resolution/rules.asm"
.include "game/resolution/strings.asm"
