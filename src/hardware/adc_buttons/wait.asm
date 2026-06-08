; Espera um botão ser pressionado e solto
; Retorna o código do botão pressionado em temp
Wait_Button_Press:
    rcall Read_Buttons
    tst temp
    breq Wait_Button_Press
    
    push temp
    
    ; Debounce do clique: espera 20ms
    ldi temp, 20
    call delay_ms
    
wait_release:
    rcall Read_Buttons
    tst temp
    brne wait_release
    
    ; Debounce da soltura: espera 20ms
    ldi temp, 20
    call delay_ms
    
    pop temp
    ret

