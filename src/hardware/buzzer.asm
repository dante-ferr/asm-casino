; Buzzer driver for sound effects and alerts
; Uses PD4 for toggling the buzzer

; Emit a short tick sound (used for matrix spin steps)
Buzzer_Tick:
    push temp
    push temp2
    ldi temp, 50            ; 250us half-period (2 kHz tone)
    ldi temp2, 10           ; 10 cycles (~5ms duration)
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Emit a standard confirmation beep
Buzzer_Beep:
    push temp
    push temp2
    ldi temp, 100           ; 500us half-period (1 kHz tone)
    ldi temp2, 80           ; 80 cycles (~80ms duration)
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Success sound effect (3 rising notes)
Buzzer_Success:
    push temp
    push temp2
    
    ldi temp, 100           ; 1 kHz note
    ldi temp2, 60
    rcall Buzzer_Play_Tone
    
    ldi temp, 20            ; short pause
    rcall delay_ms
    
    ldi temp, 77            ; ~1.3 kHz note
    ldi temp2, 80
    rcall Buzzer_Play_Tone
    
    ldi temp, 20            ; short pause
    rcall delay_ms
    
    ldi temp, 50            ; 2 kHz note
    ldi temp2, 120
    rcall Buzzer_Play_Tone
    
    pop temp2
    pop temp
    ret

; Failure/error sound effect (low pitch buzz)
Buzzer_Failure:
    push temp
    push temp2
    ldi temp, 250           ; 1.25ms half-period (400 Hz tone)
    ldi temp2, 120          ; 120 cycles (~300ms duration)
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; General tone generator
; Inputs:
;   temp  = half-period delay count (determines pitch/frequency)
;   temp2 = total toggle cycles (determines duration)
Buzzer_Play_Tone:
    push temp
    push temp2
    push r20
    push r21
    
    mov r20, temp           ; r20 = half-period delay
    mov r21, temp2          ; r21 = toggle cycle counter
buzzer_tone_loop:
    sbi PORTD, BUZZER_PIN   ; PD4 = 1
    mov temp, r20
    rcall buzzer_delay_loop
    
    cbi PORTD, BUZZER_PIN   ; PD4 = 0
    mov temp, r20
    rcall buzzer_delay_loop
    
    dec r21
    brne buzzer_tone_loop
    
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Calibrated delay loop: each unit of 'temp' is approx 5 microseconds at 16MHz
buzzer_delay_loop:
    push temp2
buzzer_delay_outer:
    ldi temp2, 26           ; 26 * 3 cycles = 78 cycles (~4.8us + loop overhead)
buzzer_delay_inner:
    dec temp2
    brne buzzer_delay_inner
    
    dec temp
    brne buzzer_delay_outer
    pop temp2
    ret
