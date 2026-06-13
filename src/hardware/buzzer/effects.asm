; Toca um bipe curto (usado nos giros da matriz)
Buzzer_Tick:
    push temp
    push temp2
    ldi temp, TONE_TICK_PITCH
    ldi temp2, TONE_TICK_LEN
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Toca um bipe padrão de confirmação
Buzzer_Beep:
    push temp
    push temp2
    ldi temp, TONE_BEEP_PITCH
    ldi temp2, TONE_BEEP_LEN
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Efeito sonoro de sucesso (3 notas ascendentes)
Buzzer_Success:
    push temp
    push temp2
    
    ldi temp, 100 ; nota de 1 kHz
    ldi temp2, 60
    rcall Buzzer_Play_Tone
    
    ldi temp, 20 ; pausa curta
    rcall delay_ms
    
    ldi temp, 77 ; nota de ~1.3 kHz
    ldi temp2, 80
    rcall Buzzer_Play_Tone
    
    ldi temp, 20 ; pausa curta
    rcall delay_ms
    
    ldi temp, 50 ; nota de 2 kHz
    ldi temp2, 120
    rcall Buzzer_Play_Tone
    
    pop temp2
    pop temp
    ret

; Efeito sonoro de erro (zumbido grave)
Buzzer_Failure:
    push temp
    push temp2
    ldi temp, 250 ; meio período de 1.25ms (tom de 400 Hz)
    ldi temp2, 120 ; 120 ciclos (duração de ~300ms)
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Gerador de tom geral
; Entradas:
;   temp  = valor de atraso do meio período (determina a frequência)
;   temp2 = total de ciclos de alternância (determina a duração)
Buzzer_Play_Tone:
    push temp
    push temp2
    push r18
    push r19
    
    tst temp ; a frequência é 0 (pausa)?
    breq buzzer_rest ; sim -> trata em silêncio
    
    sbi DDRD, BUZZER_PIN ; configura pino do buzzer como saída
    
    mov r18, temp ; r18 = atraso do meio período
    mov r19, temp2 ; r19 = contador de ciclos
    buzzer_tone_loop:
        sbi PORTD, BUZZER_PIN ; PD4 = 1
        mov temp, r18
        rcall buzzer_delay_loop
        
        cbi PORTD, BUZZER_PIN ; PD4 = 0
        mov temp, r18
        rcall buzzer_delay_loop
        
        dec r19
        brne buzzer_tone_loop
        
        cbi DDRD, BUZZER_PIN ; restaura pino do buzzer como entrada
        cbi PORTD, BUZZER_PIN ; garante pull-up desativado
        rjmp buzzer_play_exit

    buzzer_rest:
        ldi r18, 0 ; 0 mapeia para 256 no loop de atraso
        mov r19, temp2 ; r19 = contador de ciclos
    buzzer_rest_loop:
        mov temp, r18
        rcall buzzer_delay_loop
        mov temp, r18
        rcall buzzer_delay_loop
        dec r19
        brne buzzer_rest_loop

    buzzer_play_exit:
        pop r19
        pop r18
        pop temp2
        pop temp
        ret

; Loop de atraso calibrado: cada unidade de temp é aprox 5 microssegundos a 16MHz
buzzer_delay_loop:
    push temp2
    buzzer_delay_outer:
        ldi temp2, 26 ; delay interno
    buzzer_delay_inner:
        dec temp2
        brne buzzer_delay_inner
        
        dec temp
        brne buzzer_delay_outer
        pop temp2
        ret
