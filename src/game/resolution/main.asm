; Game Spin & Resolution FSM Logic

Run_Spin_Roulette:
    ; 1. Display spinning message
    rcall LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_spinning * 2)
    ldi ZH, high(msg_spinning * 2)
    rcall LCD_Print_Msg
    
    ; 2. Run modular spin sequence
    rcall Run_Roulette_Spin_Sequence ; returns winning number in temp2, saves to RAM_ROUND_NUM
    
    ; 3. Transition to resolution
    ldi fsm_state, STATE_RESOLUTION
    ret

Run_Resolution:
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ldi active_plyr, 1     ; Start with Player 1
resolution_plyr_loop:
    rcall Player_Get_Pointer ; Z points to player
    
    ; Load bet details before Calculate_Payout clears them
    ldd r23, Z+2            ; status
    ldd r22, Z+3            ; type
    ldd r20, Z+4            ; target
    ldd r19, Z+5            ; val_h
    ldd r18, Z+6            ; val_l
    
    push r23
    push r22
    push r20
    push r19
    push r18
    
    rcall Calculate_Payout  ; Calculates payout, updates balance & status, clears bet
    
    pop r18
    pop r19
    pop r23
    pop r22
    pop r20
    
    ; 1. Clear LCD
    rcall LCD_Clear
    
    ; 2. Print "P[ID]: " on Line 0
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ; Check if bet value was 0
    mov temp, r18
    or temp, r19
    brne resolution_has_bet
    
    ; No bet -> display " PASS"
    ldi ZL, low(msg_p_passed * 2)
    ldi ZH, high(msg_p_passed * 2)
    rcall LCD_Print_Msg
    rjmp resolution_show_balance
    
resolution_has_bet:
    ; Check if player was in prison
    sbrc r20, 0
    rjmp resolution_was_prison
    
    ; Was NOT in prison -> check if now in prison
    rcall Player_Get_Pointer
    ldd temp, Z+2
    sbrc temp, 0
    rjmp resolution_went_prison
    
    ; Normal win/loss check
    lds r20, RAM_ROUND_NUM
    mov temp, r22           ; type
    mov temp2, r23          ; target
    rcall Check_Bet_Win     ; returns temp = 1 (Win) or 0 (Loss)
    tst temp
    breq resolution_normal_loss
    
    ; Normal Win!
    rcall Buzzer_Success
    ldi ZL, low(msg_p_won_prefix * 2)
    ldi ZH, high(msg_p_won_prefix * 2)
    rcall LCD_Print_Msg
    
    ; Print win amount
    cpi r22, 1              ; External?
    breq print_ext_win_val
    
    ; Internal win: multiply r19:r18 by 35
    mov r24, r18
    mov r25, r19
    clr r22
    clr r23
    ldi temp, MULTIPLIER_INTERNAL_PAYOUT
mul_35_loop:
    add r22, r24
    adc r23, r25
    dec temp
    brne mul_35_loop
    mov r24, r22
    mov r25, r23
    rcall LCD_Print_Dec16
    rjmp resolution_show_balance
    
print_ext_win_val:
    mov r24, r18
    mov r25, r19
    rcall LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_normal_loss:
    rcall Buzzer_Failure
    ldi ZL, low(msg_p_lost_prefix * 2)
    ldi ZH, high(msg_p_lost_prefix * 2)
    rcall LCD_Print_Msg
    mov r24, r18
    mov r25, r19
    rcall LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_went_prison:
    ldi ZL, low(msg_p_went_prison * 2)
    ldi ZH, high(msg_p_went_prison * 2)
    rcall LCD_Print_Msg
    rjmp resolution_show_balance
    
resolution_was_prison:
    ; Was in prison -> check if win (released)
    lds r20, RAM_ROUND_NUM
    mov temp, r22           ; type
    mov temp2, r23          ; target
    rcall Check_Bet_Win
    tst temp
    breq resolution_prison_loss
    
    ; Released!
    rcall Buzzer_Success
    ldi ZL, low(msg_p_win_ext * 2)
    ldi ZH, high(msg_p_win_ext * 2)
    rcall LCD_Print_Msg
    mov r24, r18
    mov r25, r19
    rcall LCD_Print_Dec16
    rjmp resolution_show_balance
    
resolution_prison_loss:
    rcall Buzzer_Failure
    ldi ZL, low(msg_p_lost_prison * 2)
    ldi ZH, high(msg_p_lost_prison * 2)
    rcall LCD_Print_Msg
    
resolution_show_balance:
    ; Line 1: "Novo Bal: [Balance]"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi ZL, low(msg_novo_bal * 2)
    ldi ZH, high(msg_novo_bal * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    rcall LCD_Print_Dec16
    
    ; Wait dynamically to let players read result
    push temp2
    ldi temp2, RESULT_DELAY_COUNT
resolution_delay_loop:
    ldi temp, 250
    rcall delay_ms
    dec temp2
    brne resolution_delay_loop
    pop temp2
    
    ; Loop to next player
    inc active_plyr
    lds temp, RAM_NUM_PLAYERS
    inc temp
    cp active_plyr, temp
    brlo resolution_plyr_loop_jmp
    rjmp resolution_finished
    
resolution_plyr_loop_jmp:
    rjmp resolution_plyr_loop
    
resolution_finished:
    ldi active_plyr, 1      ; Reset to player 1
    ldi fsm_state, STATE_MAIN_MENU
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    ret

Run_En_Prison:
    ret

; Submodule Inclusions
.include "game/resolution/spin_seq.asm"
.include "game/resolution/rules.asm"
.include "game/resolution/strings.asm"
