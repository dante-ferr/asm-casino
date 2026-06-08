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
    
    rcall RGB_Clear
    
    cpi temp, 1
    breq set_p1_color
    cpi temp, 2
    breq set_p2_color
    cpi temp, 3
    breq set_p3_color
    cpi temp, 4
    breq set_p4_color
    rjmp rgb_plyr_done
    
set_p1_color:
    sbi PORTD, RGB_RED
    rjmp rgb_plyr_done
set_p2_color:
    sbi PORTD, RGB_BLACK
    rjmp rgb_plyr_done
set_p3_color:
    sbi PORTD, RGB_GREEN
    rjmp rgb_plyr_done
set_p4_color:
    sbi PORTD, RGB_RED
    sbi PORTD, RGB_GREEN
    
rgb_plyr_done:
    pop temp
    ret
