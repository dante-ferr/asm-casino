; 7-segment display multiplexed driver
; Uses PORTD (PD5-PD7) for segments A, B, C
; Uses PORTB (PB0-PB3) for segments D, E, F, G
; Uses PB4 for Tens digit cathode and PB5 for Units digit cathode

; Timer 0 ISR for multiplexing 7-segment displays (runs every 2ms)
TIMER0_ISR:
    push temp
    in temp, SREG
    push temp
    push temp2
    push r23
    push r24
    push r25
    push ZL
    push ZH

    ; Read the current round number to display
    lds temp, RAM_ROUND_NUM

    ; Separate tens and units via successive subtraction
    ldi temp2, 0
div_loop:
    cpi temp, 10
    brlo div_done
    subi temp, 10
    inc temp2
    rjmp div_loop
div_done:
    ; temp = units, temp2 = tens

    ; Read current cathode state in PORTB to determine which digit to update
    in r23, PORTB
    sbrs r23, DISP_DEC    ; if tens cathode is off (PB4=1), skip to show tens
    rjmp show_units       ; if tens cathode is on (PB4=0), show units next

show_tens:
    ; Switch off units cathode (active low)
    sbi PORTB, DISP_UNI
    
    ; Load tens digit value
    mov temp, temp2

    ; Fetch segment bits for PORTD
    clr temp2
    ldi ZL, low(table_portd * 2)
    ldi ZH, high(table_portd * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r24, Z            ; r24 contains segments A, B, C (PD7-PD5)

    ; Fetch segment bits for PORTB
    ldi ZL, low(table_portb * 2)
    ldi ZH, high(table_portb * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r25, Z            ; r25 contains segments D, E, F, G (PB3-PB0)

    ; Write segments to PORTD (preserving PD0-PD4)
    in temp, PORTD
    andi temp, 0x1F
    or temp, r24
    out PORTD, temp

    ; Write segments to PORTB (preserving PB4-PB5)
    in temp, PORTB
    andi temp, 0xF0
    or temp, r25
    out PORTB, temp

    ; Switch on tens cathode (active low)
    cbi PORTB, DISP_DEC
    rjmp isr_exit

show_units:
    ; Switch off tens cathode (active low)
    sbi PORTB, DISP_DEC

    ; Fetch segment bits for PORTD
    clr temp2
    ldi ZL, low(table_portd * 2)
    ldi ZH, high(table_portd * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r24, Z

    ; Fetch segment bits for PORTB
    ldi ZL, low(table_portb * 2)
    ldi ZH, high(table_portb * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r25, Z

    ; Write segments to PORTD (preserving PD0-PD4)
    in temp, PORTD
    andi temp, 0x1F
    or temp, r24
    out PORTD, temp

    ; Write segments to PORTB (preserving PB4-PB5)
    in temp, PORTB
    andi temp, 0xF0
    or temp, r25
    out PORTB, temp

    ; Switch on units cathode (active low)
    cbi PORTB, DISP_UNI

isr_exit:
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop temp2
    pop temp
    out SREG, temp
    pop temp
    reti

; Segment mapping tables stored in Flash
; table_portd maps digits 0-9 to PD7-PD5 (segments A, B, C)
table_portd:
    .db 0xE0, 0xC0, 0x60, 0xE0, 0xC0, 0xA0, 0xA0, 0xE0, 0xE0, 0xE0

; table_portb maps digits 0-9 to PB3-PB0 (segments D, E, F, G)
table_portb:
    .db 0x07, 0x00, 0x0B, 0x09, 0x0C, 0x0D, 0x0F, 0x00, 0x0F, 0x0D
