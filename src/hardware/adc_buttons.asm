; Analog keyboard driver using ADC0 (pin PC0) with a resistor ladder
; Detects three buttons: Button A (Next), Button B (History), and Select

; Reads current analog value and returns raw button code in temp (r16)
; Codes: 0 = None, 1 = Button A, 2 = Button B, 3 = Select
Read_Buttons:
    ; Start ADC conversion (set ADSC bit in ADCSRA)
    lds temp, ADCSRA
    ori temp, (1 << ADSC)
    sts ADCSRA, temp

wait_adc:
    ; Poll ADSC bit until conversion completes (hardware clears it to 0)
    lds temp, ADCSRA
    sbrc temp, ADSC
    rjmp wait_adc

    ; Read ADC data registers (LSB must be read first)
    lds r24, ADCL
    lds r25, ADCH

    ; Threshold comparison (cascade logic from highest to lowest voltage)
    
    ; None: ADC >= 900
    cpi r24, low(900)
    ldi temp, high(900)
    cpc r25, temp
    brsh btn_none

    ; Select: ADC >= 650 (covers 650 to 899)
    cpi r24, low(650)
    ldi temp, high(650)
    cpc r25, temp
    brsh btn_select

    ; Button B (History): ADC >= 450 (covers 450 to 649)
    cpi r24, low(450)
    ldi temp, high(450)
    cpc r25, temp
    brsh btn_b

    ; Button A (Next): ADC < 150
    cpi r24, 150
    ldi temp, 0
    cpc r25, temp
    brlo btn_a

btn_none:
    ldi temp, 0
    ret
btn_select:
    ldi temp, 3
    ret
btn_b:
    ldi temp, 2
    ret
btn_a:
    ldi temp, 1
    ret

; Waits for a button to be pressed and then fully released
; Returns the pressed button code in temp
Wait_Button_Press:
    rcall Read_Buttons
    tst temp
    breq Wait_Button_Press
    push temp
wait_release:
    rcall Read_Buttons
    tst temp
    brne wait_release
    pop temp
    ret
