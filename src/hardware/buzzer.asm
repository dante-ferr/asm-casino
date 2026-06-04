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

; Plays the currently selected music track and animates the LED matrix border.
; Returns temp = button code (1, 2, 3) if interrupted, 0 if finished playing
Buzzer_Play_Current_Track:
    push temp2
    push r18
    push r19
    push ZL
    push ZH
    
    ; Always load Ode to Joy
    ldi ZL, low(ode_to_joy_table * 2)
    ldi ZH, high(ode_to_joy_table * 2)
    ldi r19, ODE_TO_JOY_TEMPO_PAUSE
    
play_loop_start:
    push r19                ; Save pause duration on stack
    
ode_loop:
    lpm r18, Z+             ; r18 = pitch
    lpm r19, Z+             ; r19 = cycles
    
    ; check end marker
    tst r18
    breq ode_done
    
    ; Advance and render animation step on LED matrix
    lds temp2, RAM_BALL_IDX
    inc temp2
    cpi temp2, MATRIX_RING_SIZE
    brlo ball_no_wrap
    ldi temp2, 0
ball_no_wrap:
    sts RAM_BALL_IDX, temp2
    ldi temp, 0x80          ; center diamond pattern
    rcall Matrix_Render_Frame
    
    ; Play note
    mov temp, r18
    mov temp2, r19
    rcall Buzzer_Play_Tone
    
play_done:
    ; Pause while checking buttons
    pop r19                 ; restore pause duration
    push r19
    
    mov temp, r19
    clr temp2
div_10_loop:
    subi temp, 10
    brcs div_10_done
    inc temp2
    rjmp div_10_loop
div_10_done:
    tst temp2
    breq pause_loop_done
    mov temp, temp2         ; loop counter
pause_loop:
    push temp
    rcall Read_Buttons
    tst temp
    breq pause_no_press
    
    ; Button pressed! Save button code in r18
    mov r18, temp
    pop temp                ; clean up loop counter
    pop r19                 ; clean up pause duration
    mov temp, r18           ; return button code in temp
    rjmp ode_exit
    
pause_no_press:
    ldi temp, 10
    rcall delay_ms
    pop temp
    dec temp
    brne pause_loop
pause_loop_done:
    rjmp ode_loop

ode_done:
    pop r19                 ; clean up pause duration
    ldi temp, 0             ; return 0 (no button pressed)
ode_exit:
    pop ZH
    pop ZL
    pop r19
    pop r18
    pop temp2
    ret

; Include individual tracks
.include "game/music/ode_to_joy.asm"
; .include "game/music/badinerie.asm" ; Left as a file for future use



