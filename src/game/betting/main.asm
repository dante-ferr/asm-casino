; Game Betting Phase FSM Loops and Handlers

Run_Choose_Cat:
    rcall Show_Betting_Screen
betting_phase_loop:
    rcall Wait_Button_Press
    push temp
    
    ; Check if active player is in prison
    rcall Player_Get_Pointer
    ldd temp, Z+2
    sbrc temp, 0            ; Skip if NOT En Prison
    rjmp betting_phase_prison_handlers
    
    pop temp
    
    ; Now temp contains the pressed button (1 = A, 2 = B, 3 = Select)
    
    cpi sys_flags, 0        ; Mode 0: Edit Target
    breq handle_mode_target
    
    mov temp2, sys_flags
    andi temp2, 0x7F
    cpi temp2, 1            ; Mode 1: Edit Value
    breq handle_mode_value
    
    ; Mode 2: Confirm
    rjmp handle_mode_confirm

handle_mode_target:
    cpi temp, 1            ; Button A -> Decrement Target Index (with wrap-around)
    brne target_check_b
    
    rcall Player_Get_Pointer
    ldd temp2, Z+4          ; current selection index
    tst temp2
    brne target_dec_no_wrap
    ldi temp2, NUM_BET_TARGETS
target_dec_no_wrap:
    dec temp2
    std Z+4, temp2
    rjmp betting_phase_tick
    
target_check_b:
    cpi temp, 2            ; Button B -> Increment Target Index (with wrap-around)
    brne target_check_select
    
    rcall Player_Get_Pointer
    ldd temp2, Z+4
    inc temp2
    cpi temp2, NUM_BET_TARGETS
    brlo target_inc_save
    ldi temp2, 0
target_inc_save:
    std Z+4, temp2
    rjmp betting_phase_tick
    
target_check_select:
    cpi temp, 3            ; Button Select -> Transition to Mode 1 (Edit Value)
    brne target_loop_jmp
    
    rcall Buzzer_Beep
    ldi sys_flags, 1        ; Set Mode to 1
    rjmp betting_phase_tick

target_loop_jmp:
    rjmp betting_phase_loop

handle_mode_value:
    cpi temp, 1            ; Button A -> Increment Value (+100)
    brne value_check_b
    
    ; Get player balance in r19:r18 (avoid clobbering sys_flags in r22)
    rcall Player_Get_Balance ; returns balance in r25:r24
    mov r18, r24
    mov r19, r25            ; r19:r18 = balance
    
    ; Get current bet value in r25:r24
    rcall Player_Get_Pointer ; Z points to player
    ldd r25, Z+5
    ldd r24, Z+6            ; r25:r24 = current bet value
    
    ; If current bet >= balance, we cannot increment further
    cp r24, r18
    cpc r25, r19
    brsh value_tick_beep    ; error beep if already at balance
    
    ; Add BET_STEP points
    ldi temp2, low(BET_STEP)
    add r24, temp2
    ldi temp2, high(BET_STEP)
    adc r25, temp2
    
    ; Double check if exceeds balance
    cp r18, r24
    cpc r19, r25
    brsh value_save_new     ; balance >= new_bet -> save
    
    ; Exceeds -> cap at balance
    mov r24, r18
    mov r25, r19
    
value_save_new:
    rcall Player_Get_Pointer
    std Z+5, r25
    std Z+6, r24
    rjmp betting_phase_tick

value_tick_beep:
    rcall Buzzer_Failure
    rjmp betting_phase_loop

value_check_b:
    cpi temp, 2            ; Button B -> Decrement Value (-100)
    brne value_check_select
    
    rcall Player_Get_Pointer
    ldd r25, Z+5
    ldd r24, Z+6
    
    ; If value is 0, we cannot decrement further
    mov temp2, r24
    or temp2, r25
    breq value_tick_beep
    
    ; Subtract BET_STEP points
    ldi temp2, low(BET_STEP)
    sub r24, temp2
    ldi temp2, high(BET_STEP)
    sbc r25, temp2
    
    rcall Player_Get_Pointer
    std Z+5, r25
    std Z+6, r24
    rjmp betting_phase_tick
    
value_check_select:
    cpi temp, 3            ; Button Select -> Transition to Mode 2 (Confirm)
    brne value_loop_jmp
    
    rcall Buzzer_Beep
    ldi sys_flags, 2        ; Set Mode to 2 (Confirm, default to SIM)
    rjmp betting_phase_tick

value_loop_jmp:
    rjmp betting_phase_loop

handle_mode_confirm:
    cpi temp, 1            ; Button A -> Toggle selection
    breq toggle_confirm
    cpi temp, 2            ; Button B -> Toggle selection
    breq toggle_confirm
    
    cpi temp, 3            ; Button Select -> Confirm action
    brne confirm_loop_jmp
    
    ; Check if we confirmed (bit 7 of sys_flags is 0) or returned (bit 7 of sys_flags is 1)
    sbrc sys_flags, 7
    rjmp return_to_target   ; If bit 7 is set, return to Edit Target
    
    ; CONFIRMED!
    rcall Buzzer_Beep
    
    ; Map selection index to real bet type/target
    rcall Player_Get_Pointer
    ldd temp, Z+4           ; selection index
    rcall Map_Selection_To_Bet ; returns type in temp, target in temp2
    
    rcall Player_Get_Pointer
    std Z+3, temp           ; save real bet type
    std Z+4, temp2          ; save real bet target
    
    ; Deduct the bet value from player's balance!
    ldd r19, Z+5
    ldd r18, Z+6            ; r19:r18 = bet value
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    sub r24, r18
    sbc r25, r19            ; subtract bet value
    rcall Player_Set_Balance ; save new balance
    
    ldi sys_flags, 0        ; Reset mode for next player
    rjmp betting_phase_next_player
    
toggle_confirm:
    rcall Buzzer_Tick
    ldi temp2, 0x80
    eor sys_flags, temp2    ; Toggle bit 7 of sys_flags
    rjmp betting_phase_tick
    
return_to_target:
    rcall Buzzer_Beep
    ldi sys_flags, 0        ; Reset mode to Edit Target
    rjmp betting_phase_tick

confirm_loop_jmp:
    rjmp betting_phase_loop

betting_phase_tick:
    rcall Buzzer_Tick
    rcall Show_Betting_Screen
    rjmp betting_phase_loop

betting_phase_next_player:
    ; Move to next player
    inc active_plyr
    lds temp, RAM_NUM_PLAYERS
    inc temp
    cp active_plyr, temp
    brsh betting_phase_done
    
    ; Go to next player's betting screen
    rcall Show_Betting_Screen
    rjmp betting_phase_loop
    
betting_phase_done:
    rcall Check_Any_Bets    ; returns temp = 1 (has bets) or 0 (no bets)
    tst temp
    brne proceed_to_spin
    
    ; ERROR: No bets placed!
    rcall LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_err_no_bets * 2)
    ldi ZH, high(msg_err_no_bets * 2)
    rcall LCD_Print_Msg
    
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_err_return_menu * 2)
    ldi ZH, high(msg_err_return_menu * 2)
    rcall LCD_Print_Msg
    
    rcall Buzzer_Failure
    
    ; Wait 4.0 seconds (16 iterations of 250ms)
    ldi temp, 16
wait_loop_no_bets:
    push temp
    ldi temp, 250
    rcall delay_ms
    pop temp
    dec temp
    brne wait_loop_no_bets
    
    ldi active_plyr, 1      ; Reset to player 1
    ldi fsm_state, STATE_MAIN_MENU ; Return to menu
    ret

proceed_to_spin:
    ldi active_plyr, 1      ; Reset to player 1
    ldi fsm_state, STATE_SPIN_ROULET ; Go to spin!
    ret

; Helper: Checks if at least one active player has a non-zero bet
; Outputs: temp = 1 (has bets), 0 (no bets)
Check_Any_Bets:
    push temp2
    push r20
    push r21
    push ZL
    push ZH
    
    ldi r21, 1              ; Start checking from Player 1
check_bets_loop:
    ; Check if r21 > RAM_NUM_PLAYERS
    lds temp, RAM_NUM_PLAYERS
    cp temp, r21
    brlo no_bets_found      ; If RAM_NUM_PLAYERS < r21, we checked all active players
    
    ; Temporarily set active_plyr to get pointer
    push active_plyr
    mov active_plyr, r21
    rcall Player_Get_Pointer ; Z points to player
    pop active_plyr
    
    ldd temp, Z+5           ; bet value high
    ldd temp2, Z+6          ; bet value low
    or temp, temp2
    brne bet_found          ; Found a non-zero bet!
    
    inc r21
    rjmp check_bets_loop

bet_found:
    ldi temp, 1
    rjmp check_bets_done

no_bets_found:
    ldi temp, 0

check_bets_done:
    pop ZH
    pop ZL
    pop r21
    pop r20
    pop temp2
    ret

betting_phase_prison_handlers:
    pop temp
    cpi temp, 3            ; Button Select?
    breq betting_phase_select_prison
    
    ; A or B pressed while in prison -> play error beep and ignore
    rcall Buzzer_Failure
    rjmp betting_phase_loop
    
betting_phase_select_prison:
    ; Confirm prison locked bet and move to next player
    rcall Buzzer_Beep
    rjmp betting_phase_next_player

Run_Choose_Bet:
    ret

Run_Confirm_Bet:
    ret

; Submodule Inclusions
.include "game/betting/screen.asm"
.include "game/betting/map.asm"
.include "game/betting/strings.asm"
