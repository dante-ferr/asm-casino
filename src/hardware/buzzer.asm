; Buzzer driver for sound effects and alerts
; Uses PD4 for toggling the buzzer

; Emit a short tick sound (used for matrix spin steps)
Buzzer_Tick:
    push temp
    push temp2
    ldi temp, TONE_TICK_PITCH
    ldi temp2, TONE_TICK_LEN
    rcall Buzzer_Play_Tone
    pop temp2
    pop temp
    ret

; Emit a standard confirmation beep
Buzzer_Beep:
    push temp
    push temp2
    ldi temp, TONE_BEEP_PITCH
    ldi temp2, TONE_BEEP_LEN
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
    push r18
    push r19
    
    sbi DDRD, BUZZER_PIN    ; Set buzzer pin as output
    
    mov r18, temp           ; r18 = half-period delay
    mov r19, temp2          ; r19 = toggle cycle counter
buzzer_tone_loop:
    sbi PORTD, BUZZER_PIN   ; PD4 = 1
    mov temp, r18
    rcall buzzer_delay_loop
    
    cbi PORTD, BUZZER_PIN   ; PD4 = 0
    mov temp, r18
    rcall buzzer_delay_loop
    
    dec r19
    brne buzzer_tone_loop
    
    cbi DDRD, BUZZER_PIN    ; Restore buzzer pin as input
    cbi PORTD, BUZZER_PIN   ; Ensure pull-up is disabled
    
    pop r19
    pop r18
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
