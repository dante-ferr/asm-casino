; Lê o valor analógico atual e retorna o código do botão no temp (r16)
; Códigos: 0 = Nenhum, 1 = Botão A, 2 = Botão B, 3 = Selecionar
Read_Buttons:
    ; Inicia a conversão do ADC
    lds temp, ADCSRA
    ori temp, (1 << ADSC)
    sts ADCSRA, temp

wait_adc:
    ; Espera a conversão terminar (o hardware zera o bit ADSC)
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp wait_adc

    ; Lê os registradores de dados do ADC
    lds r24, ADCL
    lds r25, ADCH

    ; Compara com os thresholds (do maior para o menor valor)
    
    ; Nenhum botão: ADC >= BTN_THRES_NONE
    cpi r24, low(BTN_THRES_NONE)
    ldi temp, high(BTN_THRES_NONE)
    cpc r25, temp
    brsh btn_none

    ; Botão Select: ADC >= BTN_THRES_SELECT
    cpi r24, low(BTN_THRES_SELECT)
    ldi temp, high(BTN_THRES_SELECT)
    cpc r25, temp
    brsh btn_select

    ; Botão B (Histórico): ADC >= BTN_THRES_B
    cpi r24, low(BTN_THRES_B)
    ldi temp, high(BTN_THRES_B)
    cpc r25, temp
    brsh btn_b

    ; Botão A (Avançar): Qualquer valor abaixo do threshold do B
    ldi temp, 1
    ret

btn_none:
    ldi temp, 0
    ret
btn_select:
    ldi temp, 3
    ret
btn_b:
    ldi temp, 2
    ret
