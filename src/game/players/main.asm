; Player data initialization and management
; Initializes balances to 1000 points and clears game states for up to 4 players

; Initialize SRAM data for all 4 players
Players_Init:
    push temp
    push temp2
    push ZL
    push ZH
    push r20
    
    ldi ZL, low(PLAYER_DATA_START)
    ldi ZH, high(PLAYER_DATA_START)
    
    ldi r20, 4              ; Initialize 4 players
players_init_loop:
    ; 1. Set starting balance to 1000 points (0x03E8)
    ldi temp, 0x03          ; Balance High Byte (0x03)
    st Z+, temp
    ldi temp, 0xE8          ; Balance Low Byte (0xE8)
    st Z+, temp
    
    ; 2. Initialize the remaining 14 bytes of the player struct to 0
    ldi temp, 14
    ldi temp2, 0
init_zeros_loop:
    st Z+, temp2
    dec temp
    brne init_zeros_loop
    
    dec r20
    brne players_init_loop
    
    pop r20
    pop ZH
    pop ZL
    pop temp2
    pop temp
    ret

; Gets the SRAM pointer to the active player's record
; Inputs:
;   active_plyr = player ID (1 to 4)
; Outputs:
;   ZH:ZL = SRAM pointer
Player_Get_Pointer:
    push temp
    push temp2
    push r24
    
    ldi ZL, low(PLAYER_DATA_START)
    ldi ZH, high(PLAYER_DATA_START)
    
    mov temp, active_plyr
    dec temp
    breq get_ptr_done       ; If Player 1, offset is 0
    
    ldi r24, 16             ; 16 bytes per player record
    clr temp2               ; zero register for carry addition
get_ptr_loop:
    add ZL, r24
    adc ZH, temp2
    dec temp
    brne get_ptr_loop
    
get_ptr_done:
    pop r24
    pop temp2
    pop temp
    ret

; Get active player's balance
; Outputs:
;   r25 = Balance High Byte
;   r24 = Balance Low Byte
Player_Get_Balance:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ld r25, Z+              ; Load High Byte (offset 0) and increment
    ld r24, Z               ; Load Low Byte (offset 1)
    pop ZH
    pop ZL
    ret

; Set active player's balance
; Inputs:
;   r25 = Balance High Byte
;   r24 = Balance Low Byte
Player_Set_Balance:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    st Z+, r25              ; Store High Byte (offset 0) and increment
    st Z, r24               ; Store Low Byte (offset 1)
    pop ZH
    pop ZL
    ret

; Get active player's status byte
; Outputs:
;   temp = status byte
Player_Get_Status:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ldd temp, Z+2           ; Offset 2: Status Byte
    pop ZH
    pop ZL
    ret

; Set active player's status byte
; Inputs:
;   temp = status byte
Player_Set_Status:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    std Z+2, temp
    pop ZH
    pop ZL
    ret

; Get active player's bet details
; Outputs:
;   temp  = bet type (offset 3)
;   temp2 = bet target (offset 4)
;   r25:r24 = bet value (offsets 5 and 6)
Player_Get_Bet:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ldd temp, Z+3           ; Bet type
    ldd temp2, Z+4          ; Bet target
    ldd r25, Z+5            ; Bet value High byte
    ldd r24, Z+6            ; Bet value Low byte
    pop ZH
    pop ZL
    ret

; Set active player's bet details
; Inputs:
;   temp  = bet type (offset 3)
;   temp2 = bet target (offset 4)
;   r25:r24 = bet value (offsets 5 and 6)
Player_Set_Bet:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    std Z+3, temp
    std Z+4, temp2
    std Z+5, r25
    std Z+6, r24
    pop ZH
    pop ZL
    ret
