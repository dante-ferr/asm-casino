; Regras do jogo de Roleta Francesa e cálculo de pagamentos ("En Prison")
; Controla a verificação de vitórias, pagamentos normais e regras da prisão.

; Calcula vitória/derrota e atualiza o saldo do jogador com base no resultado
; Entradas: Nenhuma (lê active_plyr, RAM_ROUND_NUM e dados do jogador na SRAM)
; Saídas: Atualiza o saldo do jogador e status da prisão na SRAM.
Calculate_Payout:
    push temp
    push temp2
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ; Obtém o ponteiro do jogador ativo na SRAM (Z)
    rcall Player_Get_Pointer
    
    ; Verifica se o jogador está atualmente na prisão (bit 0 do status)
    ldd temp, Z+2 ; carrega o byte de status
    sbrc temp, 0 ; pula se o bit 0 for 0 (não está na prisão)
    rjmp resolution_prison
    
    ; --- RESOLUÇÃO NORMAL ---
    lds r20, RAM_ROUND_NUM ; número sorteado (0-36)
    
    ; Lê o valor da aposta
    ldd r25, Z+5 ; parte alta da aposta
    ldd r24, Z+6 ; parte baixa da aposta
    mov temp, r24
    or temp, r25
    brne normal_resolution_start
    rjmp resolution_done ; se o valor for 0, encerra sem resolver
    normal_resolution_start:
        
        ; Verifica se o número sorteado é 0
        tst r20
        brne check_normal_win
        
        ; Zero sorteado em aposta externa -> vai para a prisão se for Chance Simples
        ldd temp, Z+3 ; tipo de aposta
        cpi temp, 1 ; Externa?
        brne zero_internal_check
        
        ldd temp, Z+4 ; alvo da aposta
        cpi temp, 6
        brsh zero_doz_col_lose ; dúzias e colunas perdem no 0
        
        ; Prende a aposta (ativa flag da prisão)
        ldd temp, Z+2
        ori temp, 1 ; ativa o bit 0
        std Z+2, temp
        rjmp resolution_done ; o valor da aposta fica retido
     
    zero_doz_col_lose:
        rjmp clear_bet_after_spin
        
    zero_internal_check:
        ; Zero sorteado em aposta interna -> verifica se o alvo é o número 0
        ldd temp2, Z+4 ; alvo da aposta
        tst temp2
        breq win_internal_zero ; alvo é 0 -> vitória
        rjmp clear_bet_after_spin ; alvo não é 0 -> derrota
    win_internal_zero:
        rjmp win_internal_35to1
        
    check_normal_win:
        ldd temp, Z+3 ; tipo de aposta
        ldd temp2, Z+4 ; alvo da aposta
        rcall Check_Bet_Win ; retorna temp = 1 (Vitória) ou 0 (Derrota)
        
        tst temp
        brne check_normal_win_won
        rjmp clear_bet_after_spin ; derrota -> limpa a aposta
    check_normal_win_won:
        
        ; Vitória! Determina o multiplicador com base no tipo de aposta
        ldd temp, Z+3
        cpi temp, 1 ; Externa?
        brne win_internal_35to1
        
        ; Vitória externa: verifica se é Chance Simples ou Dúzia/Coluna
        ldd temp, Z+4 ; alvo da aposta
        cpi temp, 6
        brsh win_external_2to1 ; alvo >= 6 -> pagamento de 2 para 1
        rjmp win_external_1to1 ; senão, pagamento de 1 para 1
        
    win_internal_35to1:
        ; Pagamento de 35 para 1: adiciona 36 vezes o valor apostado
        ldd r25, Z+5
        ldd r24, Z+6 ; valor apostado
        
        clr r22
        clr r23 ; acumulador da multiplicação
        ldi temp, MULTIPLIER_INTERNAL_TOTAL
    payout_mul_loop:
        add r22, r24
        adc r23, r25
        dec temp
        brne payout_mul_loop
        
        ; Adiciona ao saldo do jogador
        rcall Player_Get_Balance ; retorna o saldo em r25:r24
        add r24, r22
        adc r25, r23
        rcall Player_Set_Balance
        rjmp clear_bet_after_spin
        
    win_external_1to1:
        ; Pagamento de 1 para 1: adiciona 2 vezes o valor apostado
        ldd r25, Z+5
        ldd r24, Z+6
        lsl r24
        rol r25 ; multiplica por 2
        
        mov r22, r24
        mov r23, r25
        
        rcall Player_Get_Balance ; retorna o saldo em r25:r24
        add r24, r22
        adc r25, r23
        rcall Player_Set_Balance
        rjmp clear_bet_after_spin
     
    win_external_2to1:
        ; Pagamento de 2 para 1: adiciona 3 vezes o valor apostado
        ldd r25, Z+5
        ldd r24, Z+6 ; valor apostado
        
        mov r22, r24
        mov r23, r25 ; valor apostado
        lsl r22
        rol r23 ; multiplica por 2
        add r22, r24
        adc r23, r25 ; soma mais uma vez
        
        rcall Player_Get_Balance ; retorna o saldo em r25:r24
        add r24, r22
        adc r25, r23
        rcall Player_Set_Balance
        rjmp clear_bet_after_spin
        
        ; --- RESOLUÇÃO DA PRISÃO ---
    resolution_prison:
        ; Lê os detalhes da aposta
        ldd temp, Z+3 ; tipo da aposta (Externa)
        ldd temp2, Z+4 ; alvo da aposta
        ldd r23, Z+5 ; parte alta da aposta
        ldd r22, Z+6 ; parte baixa da aposta
        
        ; Verifica se o número sorteado ganha a aposta
        lds r20, RAM_ROUND_NUM
        rcall Check_Bet_Win ; retorna temp = 1 (Vitória) ou 0 (Derrota)
        
        tst temp
        breq prison_lost
        
        ; Vitória na Prisão: devolve o valor apostado para o saldo
        rcall Player_Get_Balance ; retorna o saldo em r25:r24
        add r24, r22
        adc r25, r23
        rcall Player_Set_Balance
        
    prison_lost:
        ; Limpa o estado de prisão: desativa flag e limpa valor da aposta
        ldd temp, Z+2
        andi temp, ~1 ; desativa o bit 0
        std Z+2, temp
        
    clear_bet_after_spin:
        ; Limpa o valor da aposta atual
        ldi temp, 0
        std Z+5, temp
        std Z+6, temp
        
    resolution_done:
        pop ZH
        pop ZL
        pop r25
        pop r24
        pop r23
        pop r22
        pop r21
        pop r20
        pop temp2
        pop temp
        ret

; Verifica se o número sorteado ganha a aposta
; Entradas:
;   r20 = número sorteado (0-36)
;   temp = tipo de aposta (0 = Interna, 1 = Externa)
;   temp2 = alvo da aposta (número 0-36 ou categoria 0-5)
; Saídas:
;   temp = 1 se ganhar, 0 se perder
Check_Bet_Win:
    push temp2
    push r21
    push r22
    
    cpi temp, 0 ; Interna?
    brne check_external
    
    ; Aposta interna: ganha se o número sorteado (r20) for igual ao alvo (temp2)
    cp r20, temp2
    brne jump_lose_int
    rjmp bet_win
    jump_lose_int:
        rjmp bet_lose
        
    check_external:
        ; Categorias de apostas externas (temp2 de 0 a 11)
        cpi temp2, 0 ; Vermelho?
        brne check_black
        
        ; Vermelho: verifica se a cor do número sorteado é Vermelho
        mov r21, r20
        rcall get_number_color ; retorna a cor em r21
        cpi r21, COLOR_RED ; Vermelho?
        brne jump_lose_red
        rjmp bet_win
    jump_lose_red:
        rjmp bet_lose
        
    check_black:
        cpi temp2, 1 ; Azul/Preto?
        brne check_even
        
        ; Preto: verifica se a cor do número sorteado é Preto
        mov r21, r20
        rcall get_number_color
        cpi r21, COLOR_BLACK ; Preto?
        brne jump_lose_black
        rjmp bet_win
    jump_lose_black:
        rjmp bet_lose
        
    check_even:
        cpi temp2, 2 ; Par?
        brne check_odd
        
        ; Par: N é par e N > 0
        tst r20
        breq jump_lose_even
        mov r21, r20
        andi r21, 1
        brne jump_lose_even ; LSB igual a 1 significa ímpar -> perde
        rjmp bet_win
    jump_lose_even:
        rjmp bet_lose
        
    check_odd:
        cpi temp2, 3 ; Ímpar?
        brne check_low
        
        ; Ímpar: N é ímpar e N > 0
        tst r20
        breq jump_lose_odd
        mov r21, r20
        andi r21, 1
        breq jump_lose_odd ; LSB igual a 0 significa par -> perde
        rjmp bet_win
    jump_lose_odd:
        rjmp bet_lose
        
    check_low:
        cpi temp2, 4 ; Baixo (1-18)?
        brne check_high
        
        ; Baixo: 1 <= N <= 18
        tst r20
        breq jump_lose_low
        cpi r20, 19
        brsh jump_lose_low ; >= 19 -> perde
        rjmp bet_win
    jump_lose_low:
        rjmp bet_lose
        
    check_high:
        cpi temp2, 5 ; Alto (19-36)?
        brne check_doz1
        
        ; Alto: 19 <= N <= 36
        cpi r20, 19
        brlo jump_lose_high ; < 19 -> perde
        rjmp bet_win
    jump_lose_high:
        rjmp bet_lose

    check_doz1:
        cpi temp2, 6 ; primeira dúzia (1-12)?
        brne check_doz2
        
        ; primeira dúzia: 1 <= N <= 12
        tst r20
        breq jump_lose_doz1
        cpi r20, 13
        brsh jump_lose_doz1 ; >= 13 -> perde
        rjmp bet_win
    jump_lose_doz1:
        rjmp bet_lose

    check_doz2:
        cpi temp2, 7 ; segunda dúzia (13-24)?
        brne check_doz3
        
        ; segunda dúzia: 13 <= N <= 24
        cpi r20, 13
        brlo jump_lose_doz2 ; < 13 -> perde
        cpi r20, 25
        brsh jump_lose_doz2 ; >= 25 -> perde
        rjmp bet_win
    jump_lose_doz2:
        rjmp bet_lose

    check_doz3:
        cpi temp2, 8 ; terceira dúzia (25-36)?
        brne check_col1
        
        ; terceira dúzia: 25 <= N <= 36
        cpi r20, 25
        brlo jump_lose_doz3 ; < 25 -> perde
        cpi r20, 37
        brsh jump_lose_doz3 ; >= 37 -> perde
        rjmp bet_win
    jump_lose_doz3:
        rjmp bet_lose

    check_col1:
        cpi temp2, 9 ; Coluna 1?
        brne check_col2
        ldi r22, 1
        rjmp check_col_generic

    check_col2:
        cpi temp2, 10 ; Coluna 2?
        brne check_col3
        ldi r22, 2
        rjmp check_col_generic

    check_col3:
        cpi temp2, 11 ; Coluna 3?
        brne jump_lose_col
        ldi r22, 0
        rjmp check_col_generic
    jump_lose_col:
        rjmp bet_lose

    check_col_generic:
        tst r20
        breq jump_lose_colg
        mov r21, r20
        cp r21, r22
        brlo jump_lose_colg
        sub r21, r22
    check_col_mod3:
        cpi r21, 3
        brlo check_col_mod3_done
        subi r21, 3
        rjmp check_col_mod3
    check_col_mod3_done:
        tst r21
        brne jump_lose_colg ; not zero -> lose
        rjmp bet_win
    jump_lose_colg:
        rjmp bet_lose
        
    bet_win:
        ldi temp, 1
        rjmp check_win_ret
    bet_lose:
        ldi temp, 0
    check_win_ret:
        pop r22
        pop r21
        pop temp2
        ret

; Lê a cor do número na tabela de cores na Flash
; Entradas:
;   r21 = número (0-36)
; Saídas:
;   r21 = cor (0 = Verde, 1 = Vermelho, 2 = Preto/Azul)
get_number_color:
    push ZL
    push ZH
    push temp
    
    ldi ZL, low(color_table * 2)
    ldi ZH, high(color_table * 2)
    add ZL, r21
    clr temp
    adc ZH, temp
    lpm r21, Z
    
    pop temp
    pop ZH
    pop ZL
    ret

