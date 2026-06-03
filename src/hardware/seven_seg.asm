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

    ; 1. Check if we are in STATE_NUM_PLAYERS or STATE_WELCOME for soft PWM and display animation
    cpi r20, STATE_NUM_PLAYERS
    breq isr_players_sel
    cpi r20, STATE_WELCOME
    breq isr_players_sel
    rjmp isr_normal_seg

isr_players_sel:
    ; --- BACKGROUND SOFT PWM ---
    lds temp, RAM_PWM_COUNTER
    inc temp
    andi temp, 0x07        ; modulo 8
    sts RAM_PWM_COUNTER, temp
    
    ; Compute RGB LED bits in r23 (PD1=G, PD2=R, PD3=B)
    clr r23
    
    ; Red channel (PD2)
    lds temp2, RAM_PWM_RED
    cp temp, temp2
    brlo pwm_red_bit_on
    rjmp pwm_check_green_bit
pwm_red_bit_on:
    ori r23, (1 << RGB_RED)
    
pwm_check_green_bit:
    ; Green channel (PD1)
    lds temp2, RAM_PWM_GREEN
    cp temp, temp2
    brlo pwm_green_bit_on
    rjmp pwm_check_black_bit
pwm_green_bit_on:
    ori r23, (1 << RGB_GREEN)
    
pwm_check_black_bit:
    ; Blue channel (PD3)
    lds temp2, RAM_PWM_BLACK
    cp temp, temp2
    brlo pwm_black_bit_on
    rjmp pwm_bits_done
pwm_black_bit_on:
    ori r23, (1 << RGB_BLACK)

pwm_bits_done:
    rjmp pwm_tick_fade

pwm_tick_fade:
    ; --- TICK FADE & ANIMATION UPDATE (Every 100ms / 50 interrupts) ---
    lds temp, RAM_PWM_TICK
    inc temp
    cpi temp, 50
    brsh pwm_update_fade
    rjmp pwm_save_fade_tick
pwm_update_fade:
    ; Trigger update:
    ldi temp, 0
    sts RAM_PWM_TICK, temp
    
    ; Step display animation frame (RAM_ROUND_NUM goes 0-7)
    lds temp2, RAM_ROUND_NUM
    inc temp2
    cpi temp2, 8
    brlo pwm_save_anim_frame
    ldi temp2, 0
pwm_save_anim_frame:
    sts RAM_ROUND_NUM, temp2
    
    ; Update fading colors
    lds temp, RAM_FADE_STATE
    cpi temp, 0
    breq pwm_fade_r_to_b
    cpi temp, 1
    breq pwm_fade_b_to_g
    
    ; fade_g_to_r: Green down, Red up
    lds temp2, RAM_PWM_GREEN
    tst temp2
    breq pwm_g_to_r_done
    dec temp2
    sts RAM_PWM_GREEN, temp2
    
    lds temp2, RAM_PWM_RED
    inc temp2
    sts RAM_PWM_RED, temp2
    rjmp isr_anim_render
pwm_g_to_r_done:
    ldi temp, 0             ; state goes to 0 (R to B)
    sts RAM_FADE_STATE, temp
    rjmp isr_anim_render
    
pwm_fade_r_to_b:
    ; Red down, Blue/Black up
    lds temp2, RAM_PWM_RED
    tst temp2
    breq pwm_r_to_b_done
    dec temp2
    sts RAM_PWM_RED, temp2
    
    lds temp2, RAM_PWM_BLACK
    inc temp2
    sts RAM_PWM_BLACK, temp2
    rjmp isr_anim_render
pwm_r_to_b_done:
    ldi temp, 1             ; state goes to 1 (B to G)
    sts RAM_FADE_STATE, temp
    rjmp isr_anim_render

pwm_fade_b_to_g:
    ; Blue/Black down, Green up
    lds temp2, RAM_PWM_BLACK
    tst temp2
    breq pwm_b_to_g_done
    dec temp2
    sts RAM_PWM_BLACK, temp2
    
    lds temp2, RAM_PWM_GREEN
    inc temp2
    sts RAM_PWM_GREEN, temp2
    rjmp isr_anim_render
pwm_b_to_g_done:
    ldi temp, 2             ; state goes to 2 (G to R)
    sts RAM_FADE_STATE, temp
    rjmp isr_anim_render

pwm_save_fade_tick:
    sts RAM_PWM_TICK, temp

isr_anim_render:
    ; --- RENDER 7-SEGMENT ANIMATION FRAME ---
    lds temp, RAM_ROUND_NUM ; load current animation step (0-7)
    
    ; Read current cathode state in PORTB (use temp2, NOT r23!)
    in temp2, PORTB
    sbrs temp2, DISP_DEC    ; if PB4 is off, skip to show units
    rjmp show_units_anim
    
show_tens_anim:
    sbi PORTB, DISP_UNI   ; turn off units cathode (PB5=1)
    
    clr temp2
    ldi ZL, low(anim_table_portd_left * 2)
    ldi ZH, high(anim_table_portd_left * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r24, Z            ; r24 = PORTD segments (bits 5, 6, 7)
    
    ldi ZL, low(anim_table_portb_left * 2)
    ldi ZH, high(anim_table_portb_left * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r25, Z            ; r25 = PORTB segments (bits 0, 1, 2, 3)
    
    ; Combine segments (r24) and RGB bits (r23) for PORTD, preserving PD4 (Buzzer) and PD0
    andi r24, 0xE0        ; Keep only segment bits (PD5-PD7)
    andi r23, 0x0E        ; Keep only RGB LED bits (PD1-PD3)
    in temp, PORTD
    andi temp, 0x11       ; Keep PD0 (RX) and PD4 (Buzzer)
    or r24, temp          ; Merge in preserved bits
    or r24, r23           ; Merge in RGB LED bits
    out PORTD, r24
    
    ; Write segments to PORTB (preserving PB4-PB5)
    in temp, PORTB
    andi temp, 0xF0
    or temp, r25
    out PORTB, temp
    
    cbi PORTB, DISP_DEC   ; turn on tens cathode (PB4=0)
    rjmp isr_exit
    
show_units_anim:
    sbi PORTB, DISP_DEC   ; turn off tens cathode (PB4=1)
    
    clr temp2
    ldi ZL, low(anim_table_portd_right * 2)
    ldi ZH, high(anim_table_portd_right * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r24, Z            ; r24 = PORTD segments
    
    ldi ZL, low(anim_table_portb_right * 2)
    ldi ZH, high(anim_table_portb_right * 2)
    add ZL, temp
    adc ZH, temp2
    lpm r25, Z            ; r25 = PORTB segments
    
    ; Combine segments (r24) and RGB bits (r23) for PORTD, preserving PD4 (Buzzer) and PD0
    andi r24, 0xE0        ; Keep only segment bits (PD5-PD7)
    andi r23, 0x0E        ; Keep only RGB LED bits (PD1-PD3)
    in temp, PORTD
    andi temp, 0x11       ; Keep PD0 (RX) and PD4 (Buzzer)
    or r24, temp          ; Merge in preserved bits
    or r24, r23           ; Merge in RGB LED bits
    out PORTD, r24
    
    ; Write segments to PORTB (preserving PB4-PB5)
    in temp, PORTB
    andi temp, 0xF0
    or temp, r25
    out PORTB, temp
    
    cbi PORTB, DISP_UNI   ; turn on units cathode (PB5=0)
    rjmp isr_exit

isr_normal_seg:
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

; Display rotating segment tables (8 frames, single trace moving from left to right display)
anim_table_portd_left:
    .db 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
anim_table_portb_left:
    .db 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x04
anim_table_portd_right:
    .db 0x00, 0x20, 0x40, 0x80, 0x00, 0x00, 0x00, 0x00
anim_table_portb_right:
    .db 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00
