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
    
    tst temp                ; Is pitch 0 (rest)?
    breq buzzer_rest        ; Yes -> handle silently
    
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
    rjmp buzzer_play_exit

buzzer_rest:
    ldi r18, 0              ; 0 maps to 256 in delay loop
    mov r19, temp2          ; r19 = cycle counter
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
    
    lds temp, RAM_CURRENT_TRACK
    cpi temp, 0
    brne track_check_1
    
    ; Track 0: Ode to Joy
    ldi ZL, low(ode_to_joy_table * 2)
    ldi ZH, high(ode_to_joy_table * 2)
    ldi r19, ODE_TO_JOY_TEMPO_PAUSE
    rjmp play_loop_start
    
track_check_1:
    cpi temp, 1
    brne track_check_2
    
    ; Track 1: Minuet in G
    ldi ZL, low(minuet_g_table * 2)
    ldi ZH, high(minuet_g_table * 2)
    ldi r19, MINUET_G_TEMPO_PAUSE
    rjmp play_loop_start
    
track_check_2:
    cpi temp, 2
    brne track_check_3
    
    ; Track 2: Tetris Theme
    ldi ZL, low(tetris_table * 2)
    ldi ZH, high(tetris_table * 2)
    ldi r19, TETRIS_TEMPO_PAUSE
    rjmp play_loop_start

track_check_3:
    cpi temp, 3
    brne track_check_4
    
    ; Track 3: Star Wars Imperial March
    ldi ZL, low(star_wars_table * 2)
    ldi ZH, high(star_wars_table * 2)
    ldi r19, STAR_WARS_TEMPO_PAUSE
    rjmp play_loop_start

track_check_4:
    ; Track 4: Super Mario Bros Theme
    ldi ZL, low(mario_table * 2)
    ldi ZH, high(mario_table * 2)
    ldi r19, MARIO_TEMPO_PAUSE
    
play_loop_start:
    push r19                ; Save tempo pause on stack
    
play_note_loop:
    lpm r18, Z+             ; r18 = pitch
    lpm r19, Z+             ; r19 = cycles
    
    ; check end marker (both pitch and cycles must be 0)
    tst r18
    brne play_note_start
    tst r19
    brne play_not_done
    rjmp play_track_done
play_not_done:
play_note_start:
    
    ; Advance and render animation step on LED matrix
    lds temp2, RAM_BALL_IDX
    inc temp2
    cpi temp2, MATRIX_RING_SIZE
    brlo ball_no_wrap
    ldi temp2, 0
ball_no_wrap:
    sts RAM_BALL_IDX, temp2
    ldi temp, 0x80          ; center diamond pattern
    call Matrix_Render_Frame
    
    ; Play note in responsive chunks
    mov temp2, r19
    
    ; Check if this is Track 0 (Ode to Joy)
    lds temp, RAM_CURRENT_TRACK
    tst temp
    breq start_chunk_loop   ; Ode to Joy: use full 8-bit cycle count, do not mask bit 7
    
    ; Non-Ode to Joy tracks: strip bit 7 (no-pause flag) from cycle count
    andi temp2, 0x7F
    
    ; Check if this is Track 1 (Minuet in G) -> Scale tempo (slow down by 25%)
    cpi temp, 1
    brne start_chunk_loop
    
    ; Slow down Minuet in G by 25%: temp2_scaled = temp2 + temp2 / 4
    push r20
    mov r20, temp2
    lsr r20
    lsr r20
    add temp2, r20
    pop r20
    
start_chunk_loop:
    ; Play the note cycles in chunks of max 16, reading buttons in between
play_chunk_loop:
    tst temp2
    breq play_chunk_done
    
    mov temp, temp2
    cpi temp, 16
    brlo play_chunk_small
    ldi temp, 16
play_chunk_small:
    sub temp2, temp
    
    push temp2              ; Save remaining cycles
    mov temp2, temp         ; temp2 = chunk cycles
    mov temp, r18           ; temp = pitch
    call Buzzer_Play_Tone
    pop temp2               ; Restore remaining cycles
    
    ; Check if a button is pressed
    call Read_Buttons
    tst temp
    breq play_chunk_loop    ; No press -> continue playing this note
    
    ; Button pressed! Exit immediately returning button code in temp
    mov r18, temp           ; Save button code
    pop temp                ; Clean up pause duration from stack
    mov temp, r18
    rjmp play_exit          ; Exit early
    
play_chunk_done:
    ; Note finished playing. Now check if we should pause between notes
    ; Check no-pause flag (bit 7 of cycles) for tracks other than Ode to Joy
    lds temp, RAM_CURRENT_TRACK
    tst temp
    breq do_pause           ; Ode to Joy: always pause
    
    sbrc r19, 7             ; Skip if bit 7 of cycles is clear
    rjmp play_note_loop     ; Bit 7 is set -> play next note immediately without pausing
    
do_pause:
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
    call Read_Buttons
    tst temp
    breq pause_no_press
    
    ; Button pressed! Save button code in r18
    mov r18, temp
    pop temp                ; clean up loop counter
    pop r19                 ; clean up pause duration
    mov temp, r18           ; return button code in temp
    rjmp play_exit
    
pause_no_press:
    ldi temp, 10
    call delay_ms
    pop temp
    dec temp
    brne pause_loop
pause_loop_done:
    rjmp play_note_loop

play_track_done:
    pop r19                 ; clean up pause duration
    ldi temp, 0             ; return 0 (no button pressed)
play_exit:
    pop ZH
    pop ZL
    pop r19
    pop r18
    pop temp2
    ret

; Music tracks relocated to main.asm to prevent relative address overflows



