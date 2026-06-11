; Toca a música atual e anima as bordas da matriz de LED.
; Retorna o código do botão pressionado em temp se for interrompido, ou 0 se terminar a música
Buzzer_Play_Current_Track:
    push temp2
    push r18
    push r19
    push ZL
    push ZH
    
    lds temp, RAM_CURRENT_TRACK
    cpi temp, 0
    brne track_check_1
    
    ; Música 0: Ode à Alegria
    ldi ZL, low(ode_to_joy_table * 2)
    ldi ZH, high(ode_to_joy_table * 2)
    ldi r19, ODE_TO_JOY_TEMPO_PAUSE
    rjmp play_loop_start
    
track_check_1:
    cpi temp, 1
    brne track_check_2
    
    ; Música 1: Minueto em Sol
    ldi ZL, low(minuet_g_table * 2)
    ldi ZH, high(minuet_g_table * 2)
    ldi r19, MINUET_G_TEMPO_PAUSE
    rjmp play_loop_start
    
track_check_2:
    cpi temp, 2
    brne track_check_3
    
    ; Música 2: Tema do Tetris
    ldi ZL, low(tetris_table * 2)
    ldi ZH, high(tetris_table * 2)
    ldi r19, TETRIS_TEMPO_PAUSE
    rjmp play_loop_start

track_check_3:
    cpi temp, 3
    brne track_check_4
    
    ; Música 3: Marcha Imperial (Star Wars)
    ldi ZL, low(star_wars_table * 2)
    ldi ZH, high(star_wars_table * 2)
    ldi r19, STAR_WARS_TEMPO_PAUSE
    rjmp play_loop_start

track_check_4:
    ; Música 4: Tema do Super Mario Bros
    ldi ZL, low(mario_table * 2)
    ldi ZH, high(mario_table * 2)
    ldi r19, MARIO_TEMPO_PAUSE
    
play_loop_start:
    push r19 ; Salva o tempo de pausa na pilha
    
play_note_loop:
    lpm r18, Z+ ; r18 = tom
    lpm r19, Z+ ; r19 = ciclos
    
    ; Verifica fim da música (tom e ciclos zerados)
    tst r18
    brne play_note_start
    tst r19
    brne play_not_done
    rjmp play_track_done
play_not_done:
play_note_start:
    
    ; Avança e desenha a animação na matriz de LED
    lds temp2, RAM_BALL_IDX
    inc temp2
    cpi temp2, MATRIX_RING_SIZE
    brlo ball_no_wrap
    ldi temp2, 0
ball_no_wrap:
    sts RAM_BALL_IDX, temp2
    ldi temp, 0x80 ; padrão de diamante no centro
    call Matrix_Render_Frame
    
    ; Toca a nota em pequenos pedaços para não travar os botões
    mov temp2, r19
    
    ; Se for a Música 0 (Ode à Alegria)
    lds temp, RAM_CURRENT_TRACK
    tst temp
    breq start_chunk_loop ; Ode à Alegria: usa contagem de 8 bits completa
    
    ; Outras músicas: ignora o bit 7 que indica se deve pausar
    andi temp2, 0x7F
    
    ; Se for a Música 1 (Minueto em Sol) -> diminui a velocidade em 25%
    cpi temp, 1
    brne start_chunk_loop
    
    ; Desacelera o Minueto: temp2 = temp2 + temp2 / 4
    push r20
    mov r20, temp2
    lsr r20
    lsr r20
    add temp2, r20
    pop r20
    
start_chunk_loop:
    ; Toca blocos de até 16 ciclos e checa os botões no intervalo
play_chunk_loop:
    tst temp2
    breq play_chunk_done
    
    mov temp, temp2
    cpi temp, 16
    brlo play_chunk_small
    ldi temp, 16
play_chunk_small:
    sub temp2, temp
    
    push temp2 ; Salva ciclos restantes
    mov temp2, temp ; temp2 = ciclos deste bloco
    mov temp, r18 ; temp = tom
    call Buzzer_Play_Tone
    pop temp2 ; Restaura ciclos restantes
    
    ; Verifica se algum botão foi pressionado
    call Read_Buttons
    tst temp
    breq play_chunk_loop ; nenhum botão -> continua a nota
    
    ; Botão pressionado! Sai retornando o código do botão
    mov r18, temp ; Salva código do botão
    pop temp ; Limpa a pilha
    mov temp, r18
    rjmp play_exit ; Sai mais cedo
    
play_chunk_done:
    ; Fim da nota. Verifica se deve pausar antes da próxima
    ; Verifica flag de sem pausa (bit 7) para outras músicas
    lds temp, RAM_CURRENT_TRACK
    tst temp
    breq do_pause ; Ode à Alegria sempre pausa
    
    sbrc r19, 7 ; Pula se o bit 7 estiver zerado
    rjmp play_note_loop ; Bit 7 ativo -> toca a próxima sem pausa
    
do_pause:
    ; Pause while checking buttons
    pop r19 ; restaura duração da pausa
    push r19
    
    mov temp, r19
    clr temp2
div_10_loop:
    subi temp, 10
    brcs div_10_done
    inc temp2
    rjmp div_10_loop
div_10_done:
    tst temp2
    breq pause_loop_done
    mov temp, temp2 ; contador do loop
pause_loop:
    push temp
    call Read_Buttons
    tst temp
    breq pause_no_press
    
    ; Botão pressionado! Salva o código em r18
    mov r18, temp
    pop temp ; limpa contador
    pop r19 ; limpa duração da pausa
    mov temp, r18 ; retorna código do botão
    rjmp play_exit
    
pause_no_press:
    ldi temp, 10
    call delay_ms
    pop temp
    dec temp
    brne pause_loop
pause_loop_done:
    rjmp play_note_loop

play_track_done:
    pop r19 ; limpa duração da pausa
    ldi temp, 0 ; retorna 0 (nenhum botão pressionado)
play_exit:
    pop ZH
    pop ZL
    pop r19
    pop r18
    pop temp2
    ret
