; Configura o LED RGB de acordo com o número da roleta em temp (0-36)
; Entradas:
;   temp = número sorteado (0-36)
RGB_Set_By_Number:
    push temp
    push ZL
    push ZH
    
    ; Apaga o LED antes
    rcall RGB_Clear
    
    ; Se o número for inválido, ignora
    cpi temp, ROULETTE_SLOTS
    brsh rgb_done
    
    ; Carrega o endereço da color_table na Flash em Z
    ldi ZL, low(color_table * 2)
    ldi ZH, high(color_table * 2)
    add ZL, temp
    clr temp
    adc ZH, temp
    
    lpm temp, Z ; Carrega o tipo de cor
    
    cpi temp, COLOR_GREEN
    breq rgb_set_g
    cpi temp, COLOR_RED
    breq rgb_set_r
    cpi temp, COLOR_BLACK
    breq rgb_set_b
    rjmp rgb_done
    
rgb_set_g:
    sbi PORTD, RGB_GREEN
    rjmp rgb_done
rgb_set_r:
    sbi PORTD, RGB_RED
    rjmp rgb_done
rgb_set_b:
    sbi PORTD, RGB_BLACK
    
rgb_done:
    pop ZH
    pop ZL
    pop temp
    ret

; Tabela de cores para os números da roleta
color_table:
    .db COLOR_GREEN, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK
    .db COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_BLACK, COLOR_RED, COLOR_BLACK
    .db COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_GREEN ; alinhado para tamanho par
