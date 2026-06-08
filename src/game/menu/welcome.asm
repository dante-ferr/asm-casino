; Estado da FSM: Tela de boas-vindas e lógica
; Exibe o nome do jogo no LCD e anima uma roleta girando na matriz.
; Transiciona para STATE_NUM_PLAYERS ao pressionar qualquer botão.

Run_Welcome:
    push r18
    push r19
    push r22
    push r23
    
welcome_restart_melody:
    rcall Show_Welcome_Screen
    
welcome_melody_loop:
    call Buzzer_Play_Current_Track
    tst temp
    breq welcome_melody_loop ; se a música terminar, reinicia em loop
    
    ; Botão pressionado!
    cpi temp, 3 ; Botão Select?
    brne welcome_button_pressed ; A ou B -> transiciona para a seleção de jogadores
    
    ; Aguarda a liberação do botão Select
wait_select_release:
    call Read_Buttons
    tst temp
    brne wait_select_release

    ; Select liberado -> altera o índice da música
    lds temp2, RAM_CURRENT_TRACK
    inc temp2
    cpi temp2, 5 ; total de 5 faixas
    brlo save_track
    ldi temp2, 0
save_track:
    sts RAM_CURRENT_TRACK, temp2
    
    ; Toca som de confirmação de troca de faixa
    call Buzzer_Beep
    
    rjmp welcome_restart_melody
 
welcome_button_pressed:
    ; Aguarda a liberação do botão
wait_welcome_release:
    call Read_Buttons
    tst temp
    brne wait_welcome_release

    ; Toca bipe de confirmação
    call Buzzer_Beep
    
    ; Transiciona para STATE_NUM_PLAYERS
    ldi fsm_state, STATE_NUM_PLAYERS
    
    pop r23
    pop r22
    pop r19
    pop r18
    ret

Show_Welcome_Screen:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    call LCD_Clear
    
    ; Linha 0
    ldi temp, 0
    ldi temp2, 0
    call LCD_Set_Cursor
    ldi ZL, low(msg_welcome_title * 2)
    ldi ZH, high(msg_welcome_title * 2)
    call LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret


