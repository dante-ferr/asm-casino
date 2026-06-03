; Modular Roulette Spin Sequence Logic
; Handles animation steps, LED matrix mapping, friction deceleration, and buzzer sounds.

; Runs the complete roulette spin sequence
; Inputs: None
; Outputs:
;   temp2 = winning number (0-36)
Run_Roulette_Spin_Sequence:
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ; 1. Draw a pseudo-random winning slot index (0 to 36) using PRNG
    rcall PRNG_Spin
    mov r22, temp2          ; r22 now contains the winning slot index S_win (0 to 36)
    
    ; 2. Determine total steps for animation (at least 2 full loops + S_win)
    ; total steps = 74 + S_win
    ldi r23, 74
    add r23, r22            ; r23 = total steps remaining (counter decreases)
    
    push r22                ; Save rigged winning slot (S_win) to prevent overwrite
    
    ; 3. Run spin animation loop
    ldi r21, 0              ; r21 = current slot index S (starts at 0)
spin_anim_loop:
    ; Save remaining steps and current slot
    push r23
    push r21
    
    ; Get roulette number for current slot S
    ldi ZL, low(roulette_wheel_table * 2)
    ldi ZH, high(roulette_wheel_table * 2)
    add ZL, r21
    clr temp
    adc ZH, temp
    lpm r24, Z              ; r24 = current number (0-36)
    
    ; Update 7-segment display with current number
    sts RAM_ROUND_NUM, r24
    
    ; Set RGB LED color according to current number
    mov temp, r24
    rcall RGB_Set_By_Number
    
    ; Map slot S (r21) to LED matrix index L (0-19)
    ; Formula: L = (S * 20) / 37
    mov r22, r21            ; S
    rcall map_slot_to_led   ; returns L in r20
    
    ; Render matrix frame with static diamond and ball at L
    ldi temp, 0x80
    mov temp2, r20
    rcall Matrix_Render_Frame
    
    ; Play spin step sound
    rcall Buzzer_Tick
    
    ; Decelerate using variable delay based on remaining steps (r23)
    pop r21                 ; restore S
    pop r23                 ; restore remaining steps count
    
    mov temp, r23           ; determine delay based on remaining steps
    rcall get_friction_delay ; returns delay in temp
    rcall delay_ms
    
    ; Advance to next physical slot clockwise
    inc r21
    cpi r21, 37
    brlo slot_no_wrap
    ldi r21, 0
slot_no_wrap:
    
    dec r23
    brne spin_anim_loop
    
    pop r22                 ; Restore winning slot (S_win)
    
    ; 4. Final step: Stop on winning slot
    ldi ZL, low(roulette_wheel_table * 2)
    ldi ZH, high(roulette_wheel_table * 2)
    add ZL, r22
    clr temp
    adc ZH, temp
    lpm r24, Z              ; r24 = winning number (0-36)
    
    ; Save final winning number in RAM
    sts RAM_ROUND_NUM, r24
    
    ; Map winning slot S_win (r22) to LED matrix index L
    rcall map_slot_to_led   ; returns L in r20
    sts RAM_BALL_IDX, r20   ; Save final ball index
    
    ; Render final frame
    ldi temp, 0x80
    mov temp2, r20
    rcall Matrix_Render_Frame
    
    ; Set winning color on RGB LED
    mov temp, r24
    rcall RGB_Set_By_Number
    
    ; Return winning number in temp2
    mov temp2, r24
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    ret

; Calculate physical LED index (L) for current wheel slot (S)
; Formula: L = (S * 20) / 37
; Inputs:
;   r22 = Slot index (0-36)
; Outputs:
;   r20 = LED index (0-19)
map_slot_to_led:
    push temp
    push r24
    push r25
    
    ; 1. Multiply S (r22) by 20 -> result in r25:r24
    clr r24
    clr r25
    ldi temp, 20
mul_loop_spin:
    add r24, r22
    clr r20
    adc r25, r20
    dec temp
    brne mul_loop_spin
    
    ; 2. Divide r25:r24 by 37 via subtraction loop
    clr r20                 ; r20 will hold the result (L)
div_loop_spin:
    cpi r24, 37
    ldi temp, 0
    cpc r25, temp
    brlo div_done_spin      ; if r25:r24 < 37, done
    
    subi r24, 37
    sbci r25, 0
    inc r20
    rjmp div_loop_spin
    
div_done_spin:
    ; 3. Add offset of +2 to align slot 0 (number 0) at the 4th column of the top row (LED index 2)
    subi r20, -2
    
    ; 4. Modulo 20 wrap-around
    cpi r20, 20
    brlo mod_20_spin_done
    subi r20, 20
mod_20_spin_done:
    pop r25
    pop r24
    pop temp
    ret

; Get friction delay in milliseconds based on remaining steps
; Inputs:
;   temp = remaining steps
; Outputs:
;   temp = delay in ms
get_friction_delay:
    cpi temp, 40
    brsh delay_fast        ; remaining >= 40: 10ms
    cpi temp, 30
    brsh delay_20          ; remaining 30-39: 20ms
    cpi temp, 20
    brsh delay_40          ; remaining 20-29: 40ms
    cpi temp, 10
    brsh delay_80          ; remaining 10-19: 80ms
    cpi temp, 5
    brsh delay_150         ; remaining 5-9: 150ms
    ; remaining 1-4:
    ldi temp, 250          ; 250ms
    ret
delay_fast:
    ldi temp, 10
    ret
delay_20:
    ldi temp, 20
    ret
delay_40:
    ldi temp, 40
    ret
delay_80:
    ldi temp, 80
    ret
delay_150:
    ldi temp, 150
    ret

; Physical layout of French Roulette wheel (37 slots, padded to even length)
roulette_wheel_table:
    .db 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23
    .db 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26, 0
