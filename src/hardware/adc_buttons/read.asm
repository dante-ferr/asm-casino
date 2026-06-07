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
    
    ; None: ADC >= BTN_THRES_NONE
    cpi r24, low(BTN_THRES_NONE)
    ldi temp, high(BTN_THRES_NONE)
    cpc r25, temp
    brsh btn_none

    ; Select: ADC >= BTN_THRES_SELECT
    cpi r24, low(BTN_THRES_SELECT)
    ldi temp, high(BTN_THRES_SELECT)
    cpc r25, temp
    brsh btn_select

    ; Button B (History): ADC >= BTN_THRES_B
    cpi r24, low(BTN_THRES_B)
    ldi temp, high(BTN_THRES_B)
    cpc r25, temp
    brsh btn_b

    ; Button A (Next): Any value < BTN_THRES_B (no gap)
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
