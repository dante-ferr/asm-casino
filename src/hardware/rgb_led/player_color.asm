; Configura a cor do LED RGB com base no jogador ativo (de 1 a 4)
; Entradas:
;   temp = jogador ativo (de 1 a 4)
; Cores correspondentes:
;   Jogador 1: Vermelho
;   Jogador 2: Azul (mapeado no pino RGB_BLACK)
;   Jogador 3: Verde
;   Jogador 4: Amarelo (Vermelho + Verde)
RGB_Set_By_Player:
    push temp
    
    ; Apaga todas as cores do LED RGB antes de definir a nova cor
    rcall RGB_Clear
    
    ; Verifica qual é o ID do jogador ativo para definir a cor
    cpi temp, 1
    breq set_p1_color ; Jogador 1 -> Vermelho
    cpi temp, 2
    breq set_p2_color ; Jogador 2 -> Azul/Preto
    cpi temp, 3
    breq set_p3_color ; Jogador 3 -> Verde
    cpi temp, 4
    breq set_p4_color ; Jogador 4 -> Amarelo
    rjmp rgb_plyr_done
    
    set_p1_color:
        ; Liga o LED Vermelho
        sbi PORTD, RGB_RED
        rjmp rgb_plyr_done
    set_p2_color:
        ; Liga o LED Azul/Preto
        sbi PORTD, RGB_BLACK
        rjmp rgb_plyr_done
    set_p3_color:
        ; Liga o LED Verde
        sbi PORTD, RGB_GREEN
        rjmp rgb_plyr_done
    set_p4_color:
        ; Liga o LED Vermelho e o LED Verde (produz Amarelo)
        sbi PORTD, RGB_RED
        sbi PORTD, RGB_GREEN
        
    rgb_plyr_done:
        pop temp
        ret
