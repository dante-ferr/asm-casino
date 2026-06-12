; Mapeia o índice de seleção para o tipo/alvo real de aposta
; Entradas:
;   temp = índice de seleção
; Saídas:
;   temp = tipo real de aposta (0 = Interna, 1 = Externa)
;   temp2 = alvo real da aposta
Map_Selection_To_Bet:
    cpi temp, FIRST_INTERNAL_IDX
    brsh map_internal
    
    ; Externa: Tipo = 1, Alvo = temp
    mov temp2, temp
    ldi temp, 1
    ret
    
map_internal:
    ; Interna: Tipo = 0, Alvo = temp - FIRST_INTERNAL_IDX
    mov temp2, temp
    subi temp2, FIRST_INTERNAL_IDX
    ldi temp, 0
    ret
