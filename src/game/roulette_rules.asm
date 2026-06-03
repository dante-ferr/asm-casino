; French Roulette game rules and payout calculations ("En Prison")
; Handles bet win verification, normal payouts, and En Prison locking logic.

; Calculate win/loss and update player balance based on drawn result
; Inputs: None (reads active_plyr, RAM_ROUND_NUM, and player data in SRAM)
; Outputs: Updates player balance and En Prison status in SRAM.
Calculate_Payout:
    push temp
    push temp2
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ; 1. Get active player pointer in SRAM (Z)
    rcall Player_Get_Pointer
    
    ; 2. Check if player is currently En Prison (status bit 0)
    ldd temp, Z+2           ; Load Status Byte
    sbrc temp, 0            ; Skip if bit 0 is 0 (not En Prison)
    rjmp resolution_prison
    
    ; --- NORMAL RESOLUTION ---
    lds r20, RAM_ROUND_NUM  ; r20 = winning number (0-36)
    
    ; Get bet value
    ldd r25, Z+5            ; Bet value High byte
    ldd r24, Z+6            ; Bet value Low byte
    mov temp, r24
    or temp, r25
    brne normal_resolution_start
    rjmp resolution_done    ; If bet value is 0, no bet to resolve (safe jump)
normal_resolution_start:
    
    ; Check if winning number is 0
    tst r20
    brne check_normal_win
    
    ; Winning number is 0!
    ; Zero drawn on External Bet (Type = 1) -> goes to En Prison
    ldd temp, Z+3           ; Bet type
    cpi temp, 1             ; External?
    brne zero_internal_check
    
    ; Imprison the bet (set En Prison status flag)
    ldd temp, Z+2
    ori temp, 1             ; Set bit 0 (En Prison flag)
    std Z+2, temp
    rjmp resolution_done    ; Bet value remains locked in OFS_BET_VAL
    
zero_internal_check:
    ; Zero drawn on Internal Bet -> check if target is number 0
    ldd temp2, Z+4          ; Bet target
    tst temp2
    breq win_internal_zero  ; target is 0 -> wins!
    rjmp clear_bet_after_spin ; target is not 0 -> lost!
win_internal_zero:
    rjmp win_internal_35to1
    
check_normal_win:
    ldd temp, Z+3           ; Bet type (0=Int, 1=Ext)
    ldd temp2, Z+4          ; Bet target
    rcall Check_Bet_Win     ; Returns temp = 1 (Win) or 0 (Loss)
    
    tst temp
    brne check_normal_win_won
    rjmp clear_bet_after_spin ; Loss -> do nothing to balance, clear bet (safe jump)
check_normal_win_won:
    
    ; Win! Determine multiplier based on bet type
    ldd temp, Z+3
    cpi temp, 1             ; External?
    brne win_internal_35to1
    rjmp win_external_1to1  ; safe jump to win_external_1to1
    
win_internal_35to1:
    ; Payout 35 to 1: Add (bet_value * 36) to balance (original bet + 35x payout)
    ldd r25, Z+5
    ldd r24, Z+6            ; r25:r24 = bet_value
    
    clr r22
    clr r23                 ; r23:r22 = multiplier accumulator
    ldi temp, 36
payout_mul_loop:
    add r22, r24
    adc r23, r25
    dec temp
    brne payout_mul_loop
    
    ; Add to player balance
    rcall Player_Get_Balance ; returns balance in r25:r24
    add r24, r22
    adc r25, r23
    rcall Player_Set_Balance
    rjmp clear_bet_after_spin
    
win_external_1to1:
    ; Payout 1 to 1: Add (bet_value * 2) to balance (original bet + 1x payout)
    ldd r25, Z+5
    ldd r24, Z+6
    lsl r24
    rol r25                 ; r25:r24 = bet_value * 2
    
    mov r22, r24
    mov r23, r25
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    add r24, r22
    adc r25, r23
    rcall Player_Set_Balance
    rjmp clear_bet_after_spin
    
    ; --- EN PRISON RESOLUTION ---
resolution_prison:
    ; Get bet details
    ldd temp, Z+3           ; Bet type (External)
    ldd temp2, Z+4          ; Bet target
    ldd r23, Z+5            ; Bet value High byte
    ldd r22, Z+6            ; Bet value Low byte
    
    ; Check if winning number (RAM_ROUND_NUM) wins for this bet
    lds r20, RAM_ROUND_NUM
    rcall Check_Bet_Win     ; returns temp = 1 (Win) or 0 (Loss)
    
    tst temp
    breq prison_lost
    
    ; Prison Win: Return original bet value back to the balance
    rcall Player_Get_Balance ; returns balance in r25:r24
    add r24, r22
    adc r25, r23
    rcall Player_Set_Balance
    
prison_lost:
    ; Clean prison state: clear En Prison flag and clear bet value
    ldd temp, Z+2
    andi temp, ~1           ; Clear bit 0 (En Prison flag)
    std Z+2, temp
    
clear_bet_after_spin:
    ; Clear current bet value
    ldi temp, 0
    std Z+5, temp
    std Z+6, temp
    
resolution_done:
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Check if a winning number wins for a bet
; Inputs:
;   r20 = winning number (0-36)
;   temp = bet type (0 = Internal, 1 = External)
;   temp2 = bet target (number 0-36 or category 0-5)
; Outputs:
;   temp = 1 if Win, 0 if Loss
Check_Bet_Win:
    push temp2
    push r21
    push r22
    
    cpi temp, 0             ; Internal?
    brne check_external
    
    ; Internal bet: wins if winning number (r20) == Target number (temp2)
    cp r20, temp2
    breq bet_win
    rjmp bet_lose
    
check_external:
    ; External bet categories (temp2 = 0 to 5)
    cpi temp2, 0            ; Red
    brne check_black
    
    ; Red: check if color of winning number is Red (1)
    mov r21, r20
    rcall get_number_color  ; returns color in r21 (0=G, 1=R, 2=B)
    cpi r21, 1              ; Red?
    breq bet_win
    rjmp bet_lose
    
check_black:
    cpi temp2, 1            ; Black
    brne check_even
    
    ; Black: check if color of winning number is Black (2)
    mov r21, r20
    rcall get_number_color
    cpi r21, 2              ; Black?
    breq bet_win
    rjmp bet_lose
    
check_even:
    cpi temp2, 2            ; Even
    brne check_odd
    
    ; Even: N is even and N > 0
    tst r20
    breq bet_lose
    mov r21, r20
    andi r21, 1
    breq bet_win            ; LSB is 0 -> even
    rjmp bet_lose
    
check_odd:
    cpi temp2, 3            ; Odd
    brne check_low
    
    ; Odd: N is odd and N > 0
    tst r20
    breq bet_lose
    mov r21, r20
    andi r21, 1
    brne bet_win            ; LSB is 1 -> odd
    rjmp bet_lose
    
check_low:
    cpi temp2, 4            ; Low (1-18)
    brne check_high
    
    ; Low: N >= 1 and N <= 18
    tst r20
    breq bet_lose
    cpi r20, 19
    brlo bet_win            ; < 19 means <= 18
    rjmp bet_lose
    
check_high:
    cpi temp2, 5            ; High (19-36)
    brne bet_lose
    
    ; High: N >= 19 and N <= 36
    cpi r20, 19
    brsh bet_win            ; >= 19
    rjmp bet_lose
    
bet_win:
    ldi temp, 1
    rjmp check_win_ret
bet_lose:
    ldi temp, 0
check_win_ret:
    pop r22
    pop r21
    pop temp2
    ret

; Reads number color from Flash color_table
; Inputs:
;   r21 = number (0-36)
; Outputs:
;   r21 = color (0=Green, 1=Red, 2=Black)
get_number_color:
    push ZL
    push ZH
    push temp
    
    ldi ZL, low(color_table * 2)
    ldi ZH, high(color_table * 2)
    add ZL, r21
    clr temp
    adc ZH, temp
    lpm r21, Z
    
    pop temp
    pop ZH
    pop ZL
    ret
