; Loops e tratadores da FSM para a fase de apostas

Run_Choose_Cat:
    call Show_Betting_Screen
betting_phase_loop:
    call Wait_Button_Press
    push temp
    
    ; Verifica se o jogador ativo está na prisão
    call Player_Get_Pointer
    ldd temp, Z+2
    sbrc temp, 0 ; pula se NÃO estiver na prisão
    rjmp betting_phase_prison_handlers
    
    pop temp
    
    ; temp contém o botão pressionado (1 = A, 2 = B, 3 = Select)
    
    cpi sys_flags, 0 ; Modo 0: Edita o alvo
    breq handle_mode_target
    
    mov temp2, sys_flags
    andi temp2, 0x7F
    cpi temp2, 1 ; Modo 1: Edita o valor
    breq handle_mode_value
    
    ; Modo 2: Confirmação
    rjmp handle_mode_confirm

handle_mode_target:
    cpi temp, 1 ; Botão A -> decrementa o índice do alvo
    brne target_check_b
    
    call Player_Get_Pointer
    ldd temp2, Z+4 ; índice de seleção atual
    tst temp2
    brne target_dec_no_wrap
    ldi temp2, NUM_BET_TARGETS
target_dec_no_wrap:
    dec temp2
    std Z+4, temp2
    rjmp betting_phase_tick
    
target_check_b:
    cpi temp, 2 ; Botão B -> incrementa o índice do alvo
    brne target_check_select
    
    call Player_Get_Pointer
    ldd temp2, Z+4
    inc temp2
    cpi temp2, NUM_BET_TARGETS
    brlo target_inc_save
    ldi temp2, 0
target_inc_save:
    std Z+4, temp2
    rjmp betting_phase_tick
    
target_check_select:
    cpi temp, 3 ; Botão Select -> transiciona para o Modo 1 (Edita valor)
    brne target_loop_jmp
    
    call Buzzer_Beep
    ldi sys_flags, 1 ; define o modo como 1
    rjmp betting_phase_tick

target_loop_jmp:
    rjmp betting_phase_loop

handle_mode_value:
    cpi temp, 2 ; Botão B -> incrementa valor (+100)
    brne value_check_b
    
    ; Lê o saldo do jogador em r19:r18
    call Player_Get_Balance ; retorna saldo em r25:r24
    mov r18, r24
    mov r19, r25 ; r19:r18 = saldo
    
    ; Lê o valor da aposta atual em r25:r24
    call Player_Get_Pointer ; Z aponta para o jogador
    ldd r25, Z+5
    ldd r24, Z+6 ; valor atual da aposta
    
    ; Se a aposta atual for maior ou igual ao saldo, impede o incremento
    cp r24, r18
    cpc r25, r19
    brsh value_tick_beep ; bipe de erro se já atingiu o saldo
    
    ; Adiciona o passo de aposta
    ldi temp2, low(BET_STEP)
    add r24, temp2
    ldi temp2, high(BET_STEP)
    adc r25, temp2
    
    ; Verifica se ultrapassa o saldo
    cp r18, r24
    cpc r19, r25
    brsh value_save_new ; saldo >= aposta -> salva
    
    ; Caso ultrapasse, limita ao valor do saldo
    mov r24, r18
    mov r25, r19
    
value_save_new:
    call Player_Get_Pointer
    std Z+5, r25
    std Z+6, r24
    rjmp betting_phase_tick

value_tick_beep:
    call Buzzer_Failure
    rjmp betting_phase_loop

value_check_b:
    cpi temp, 1 ; Botão A -> decrementa valor (-100)
    brne value_check_select
    
    call Player_Get_Pointer
    ldd r25, Z+5
    ldd r24, Z+6
    
    ; Se o valor for 0, impede o decremento
    mov temp2, r24
    or temp2, r25
    breq value_tick_beep
    
    ; Subtrai o passo de aposta
    ldi temp2, low(BET_STEP)
    sub r24, temp2
    ldi temp2, high(BET_STEP)
    sbc r25, temp2
    
    call Player_Get_Pointer
    std Z+5, r25
    std Z+6, r24
    rjmp betting_phase_tick
    
value_check_select:
    cpi temp, 3 ; Botão Select -> transiciona para o Modo 2 (Confirmar)
    brne value_loop_jmp
    
    call Buzzer_Beep
    ldi sys_flags, 2 ; define o modo como 2
    rjmp betting_phase_tick

value_loop_jmp:
    rjmp betting_phase_loop

handle_mode_confirm:
    cpi temp, 1 ; Botão A -> alterna a seleção
    breq toggle_confirm
    cpi temp, 2 ; Botão B -> alterna a seleção
    breq toggle_confirm
    
    cpi temp, 3 ; Botão Select -> confirma a ação
    brne confirm_loop_jmp
    
    ; Verifica se confirmou ou se retornou
    sbrc sys_flags, 7
    rjmp return_to_target ; se o bit 7 estiver ativo, retorna para Edição de Alvo
    
    ; CONFIRMADO!
    call Buzzer_Beep
    
    ; Mapeia o índice de seleção para o tipo/alvo real de aposta
    call Player_Get_Pointer
    ldd temp, Z+4 ; índice de seleção
    call Map_Selection_To_Bet ; retorna o tipo em temp e o alvo em temp2
    
    call Player_Get_Pointer
    std Z+3, temp ; salva o tipo real da aposta
    std Z+4, temp2 ; salva o alvo real da aposta
    
    ; Deduz o valor da aposta do saldo do jogador
    ldd r19, Z+5
    ldd r18, Z+6 ; valor da aposta
    
    call Player_Get_Balance ; retorna o saldo em r25:r24
    sub r24, r18
    sbc r25, r19 ; subtrai o valor da aposta
    call Player_Set_Balance ; salva o novo saldo
    
    ldi sys_flags, 0 ; reinicia o modo para o próximo jogador
    rjmp betting_phase_next_player
    
toggle_confirm:
    call Buzzer_Tick
    ldi temp2, 0x80
    eor sys_flags, temp2 ; inverte o bit 7 do sys_flags
    rjmp betting_phase_tick
    
return_to_target:
    call Buzzer_Beep
    ldi sys_flags, 0 ; reinicia o modo para Edição de Alvo
    rjmp betting_phase_tick

confirm_loop_jmp:
    rjmp betting_phase_loop

betting_phase_tick:
    call Buzzer_Tick
    call Show_Betting_Screen
    rjmp betting_phase_loop

betting_phase_next_player:
    ; Avança para o próximo jogador
    inc active_plyr
    lds temp, RAM_NUM_PLAYERS
    inc temp
    cp active_plyr, temp
    brsh betting_phase_done
    
    ; Vai para a tela de aposta do próximo jogador
    call Show_Betting_Screen
    rjmp betting_phase_loop
    
betting_phase_done:
    call Check_Any_Bets ; retorna temp = 1 (tem apostas) ou 0 (sem apostas)
    tst temp
    brne proceed_to_spin
    
    ; ERRO: Nenhuma aposta realizada!
    call LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    call LCD_Set_Cursor
    ldi ZL, low(msg_err_no_bets * 2)
    ldi ZH, high(msg_err_no_bets * 2)
    call LCD_Print_Msg
    
    ldi temp, 1
    ldi temp2, 0
    call LCD_Set_Cursor
    ldi ZL, low(msg_err_return_menu * 2)
    ldi ZH, high(msg_err_return_menu * 2)
    call LCD_Print_Msg
    
    call Buzzer_Failure
    
    ; Aguarda 4 segundos
    ldi temp, 16
wait_loop_no_bets:
    push temp
    ldi temp, 250
    call delay_ms
    pop temp
    dec temp
    brne wait_loop_no_bets
    
    ldi active_plyr, 1 ; começar no jogador 1
    ldi fsm_state, STATE_MAIN_MENU ; retorna ao menu
    ret

proceed_to_spin:
    ldi active_plyr, 1 ; começar no jogador 1
    ldi fsm_state, STATE_SPIN_ROULET ; inicia o giro
    ret

; Função auxiliar: verifica se há pelo menos uma aposta não zerada
; Saídas: temp = 1 (tem apostas), 0 (não tem apostas)
Check_Any_Bets:
    push temp2
    push r20
    push r21
    push ZL
    push ZH
    
    ldi r21, 1 ; inicia a verificação pelo jogador 1
check_bets_loop:
    ; Verifica se r21 > quantidade de jogadores ativos
    lds temp, RAM_NUM_PLAYERS
    cp temp, r21
    brlo no_bets_found ; se RAM_NUM_PLAYERS < r21, encerra a busca
    
    ; Define temporariamente active_plyr para obter o ponteiro
    push active_plyr
    mov active_plyr, r21
    call Player_Get_Pointer ; Z aponta para o jogador
    pop active_plyr
    
    ldd temp, Z+5 ; parte alta da aposta
    ldd temp2, Z+6 ; parte baixa da aposta
    or temp, temp2
    brne bet_found ; aposta encontrada!
    
    inc r21
    rjmp check_bets_loop

bet_found:
    ldi temp, 1
    rjmp check_bets_done

no_bets_found:
    ldi temp, 0

check_bets_done:
    pop ZH
    pop ZL
    pop r21
    pop r20
    pop temp2
    ret

betting_phase_prison_handlers:
    pop temp
    cpi temp, 3 ; Botão Select?
    breq betting_phase_select_prison
    
    ; A ou B pressionado na prisão -> toca som de erro e ignora
    call Buzzer_Failure
    rjmp betting_phase_loop
    
betting_phase_select_prison:
    ; Confirma a aposta travada da prisão e passa para o próximo
    call Buzzer_Beep
    rjmp betting_phase_next_player

Run_Choose_Bet:
    ret

Run_Confirm_Bet:
    ret

; Inclusão de subódulos
.include "game/betting/screen.asm"
.include "game/betting/map.asm"
.include "game/betting/strings.asm"
