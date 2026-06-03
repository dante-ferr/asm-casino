; Main program entry point and interrupt vectors
.include "config.inc"

; Interrupt Vectors
.org 0x0000
    rjmp RESET             ; Reset Handler
.org OC0Aaddr              ; Timer0 Compare Match A Vector (0x001C)
    rjmp TIMER0_ISR        ; Timer0 Compare Match A Handler
.org 0x0034                ; End of interrupt vectors

; System Initialization (RESET)
RESET:
    ; 1. Initialize Stack Pointer
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; 2. Configure I/O port directions
    ; PORTB: PB0-PB3 (Segment outputs), PB4-PB5 (Cathode outputs)
    ldi temp, 0b00111111   ; PB0-PB5 set as output
    out DDRB, temp
    
    ; PORTD: PD1-PD3 (RGB), PD4 (Buzzer), PD5-PD7 (Segments)
    ldi temp, 0b11111110   ; PD1-PD7 set as output (PD0 RX/TX free)
    out DDRD, temp

    ; PORTC: PC1-PC3 (Matrix outputs), PC4-PC5 (I2C), PC0 (ADC input)
    ldi temp, 0b00111110   ; PC1-PC3 output, PC4-PC5 output/input, PC0 input
    out DDRC, temp
    
    ; Initialize cathode outputs to High (Off, Common Cathode)
    sbi PORTB, DISP_DEC
    sbi PORTB, DISP_UNI

    ; 3. Initialize LCD and LED Matrix
    rcall LCD_Init
    rcall LCD_Clear
    rcall Matrix_Init

    ; 4. Initialize player data in SRAM
    rcall Players_Init

    ; 5. Configure Timer 0 for periodic interrupts (Multiplexing)
    ; CTC Mode (Clear Timer on Compare Match A)
    ldi temp, (1 << WGM01)
    out TCCR0A, temp
    ; Prescaler of 256 -> 16MHz / 256 = 62.5kHz
    ldi temp, (1 << CS02)
    out TCCR0B, temp
    ; Compare A: 124 counts -> 125 * 16us = 2.0ms
    ldi temp, 124
    out OCR0A, temp
    ; Enable Timer 0 Compare Match A Interrupt
    ldi temp, (1 << OCIE0A)
    sts TIMSK0, temp

    ; 6. Configure ADC (Analog Keyboard)
    ; ADMUX: AVCC with external cap at AREF pin, channel ADC0
    ldi temp, (1 << REFS0)
    sts ADMUX, temp
    ; ADCSRA: Enable ADC, Prescaler 128 (16MHz / 128 = 125kHz)
    ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, temp

    ; 6b. Configure Timer 1 for PRNG entropy (runs at full 16MHz clock)
    ldi temp, (1 << CS10)
    sts TCCR1B, temp

    ; 7. Initialize state variables
    ldi fsm_state, STATE_MAIN_MENU
    ldi active_plyr, 1     ; Start with Player 1
    ldi sys_flags, 0

    ; Set initial display values matching Player 1 (01)
    ldi temp, 1
    sts RAM_ROUND_NUM, temp
    ldi temp, 0
    sts RAM_BALL_IDX, temp

    ; Draw initial matrix state (static diamond, ball at index 0)
    ldi temp, 0x80         ; static diamond in the center
    ldi temp2, 0           ; ball at index 0
    rcall Matrix_Render_Frame
    
    ; Initial RGB LED color (Red for number 1)
    ldi temp, 1
    rcall RGB_Set_By_Number

    ; Enable global interrupts
    sei

; Main Loop
MAIN_LOOP:
    cpi fsm_state, STATE_MAIN_MENU
    brne CHECK_STATE_1
    rcall Run_Main_Menu
    rjmp MAIN_LOOP

CHECK_STATE_1:
    cpi fsm_state, STATE_CHOOSE_CAT
    brne CHECK_STATE_2
    rcall Run_Choose_Cat
    rjmp MAIN_LOOP

CHECK_STATE_2:
    cpi fsm_state, STATE_CHOOSE_BET
    brne CHECK_STATE_3
    rcall Run_Choose_Bet
    rjmp MAIN_LOOP

CHECK_STATE_3:
    cpi fsm_state, STATE_CONFIRM_BET
    brne CHECK_STATE_4
    rcall Run_Confirm_Bet
    rjmp MAIN_LOOP

CHECK_STATE_4:
    cpi fsm_state, STATE_SPIN_ROULET
    brne CHECK_STATE_5
    rcall Run_Spin_Roulette
    rjmp MAIN_LOOP

CHECK_STATE_5:
    cpi fsm_state, STATE_RESOLUTION
    brne CHECK_STATE_6
    rcall Run_Resolution
    rjmp MAIN_LOOP

CHECK_STATE_6:
    cpi fsm_state, STATE_EN_PRISON
    brne CHECK_STATE_7
    rcall Run_En_Prison
    rjmp MAIN_LOOP

CHECK_STATE_7:
    cpi fsm_state, STATE_SET_CREDITS
    brne MAIN_LOOP
    rcall Run_Set_Credits
    rjmp MAIN_LOOP

; FSM State Execution Subroutines (Stubs)

Run_Main_Menu:
    rcall Show_Player_Menu

test_button_loop:
    rcall Wait_Button_Press
    push temp

    pop temp
    cpi temp, 1            ; Button A -> Switch active player
    brne check_btn_b
    
    ; Cycle player ID (1 -> 2 -> 3 -> 4 -> 1)
    mov temp2, active_plyr
    inc temp2
    cpi temp2, 5
    brlo update_active_plyr
    ldi temp2, 1
update_active_plyr:
    mov active_plyr, temp2
    
    ; Update 7-segment display to show active player ID (01-04)
    sts RAM_ROUND_NUM, active_plyr
    
    ; Map player ID to matrix ball index (player_id - 1)
    mov temp2, active_plyr
    dec temp2
    sts RAM_BALL_IDX, temp2
    
    ; Render matrix frame
    ldi temp, 0x80
    rcall Matrix_Render_Frame
    
    ; Update RGB LED color to match player ID
    mov temp, active_plyr
    rcall RGB_Set_By_Number
    
    ; Play click sound
    rcall Buzzer_Tick
    
    ; Refresh LCD display
    rcall Show_Player_Menu
    rjmp test_button_loop

check_btn_b:
    cpi temp, 2            ; Button B -> Enter credit setting screen
    brne check_btn_select
    
    ; Switch FSM state and exit Run_Main_Menu
    ldi fsm_state, STATE_SET_CREDITS
    ret

check_btn_select:
    cpi temp, 3            ; Button Select -> Run spin animation
    brne test_button_loop

    ; Confirmation beep
    rcall Buzzer_Beep

    ; Print spinning message
    rcall LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_spinning * 2)
    ldi ZH, high(msg_spinning * 2)
    rcall LCD_Print_Msg

    ; Run modular roulette spin sequence
    rcall Run_Roulette_Spin_Sequence
    
    ; Play victory melody
    rcall Buzzer_Success
    
    ; Wait 2.5 seconds to let the user view and hear the result
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    ldi temp, 250
    rcall delay_ms
    
    ; Restore player values on displays
    sts RAM_ROUND_NUM, active_plyr
    mov temp2, active_plyr
    dec temp2
    sts RAM_BALL_IDX, temp2
    
    ; Render matrix frame
    ldi temp, 0x80
    rcall Matrix_Render_Frame
    
    ; Update RGB LED color to match player ID
    mov temp, active_plyr
    rcall RGB_Set_By_Number
    
    ; Refresh LCD and resume menu
    rcall Show_Player_Menu
    rjmp test_button_loop

; Show player ID and balance on LCD
Show_Player_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    rcall LCD_Clear
    
    ; Line 0: "P[ID] Bal: [Value]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ldi ZL, low(msg_bal_label * 2)
    ldi ZH, high(msg_bal_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    rcall LCD_Print_Dec16
    
    ; Line 1: "A:Mudar B:+100 S:Gira"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_menu_line1 * 2)
    ldi ZH, high(msg_menu_line1 * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

; FSM State: Set Credits Screen
Run_Set_Credits:
    rcall Show_Credits_Menu
set_credits_loop:
    rcall Wait_Button_Press
    push temp
    
    pop temp
    cpi temp, 1            ; Button A -> Add 100 points
    brne set_credits_b
    
    ; Get current balance (r25:r24)
    rcall Player_Get_Balance
    
    ; Check maximum limit (9900 points)
    cpi r24, low(9900)
    ldi temp2, high(9900)
    cpc r25, temp2
    brsh set_credits_tick   ; Skip addition if already >= 9900
    
    ; Add 100 points
    subi r24, low(-100)
    sbci r25, high(-100)
    rcall Player_Set_Balance
    
set_credits_tick:
    rcall Buzzer_Tick
    rcall Show_Credits_Menu
    rjmp set_credits_loop
    
set_credits_b:
    cpi temp, 2            ; Button B -> Subtract 100 points
    brne set_credits_select
    
    ; Get current balance (r25:r24)
    rcall Player_Get_Balance
    
    ; Check minimum limit (0 points)
    cpi r24, 0
    ldi temp2, 0
    cpc r25, temp2
    breq set_credits_tick   ; Skip subtraction if already 0
    
    ; Subtract 100 points
    subi r24, low(100)
    sbci r25, high(100)
    rcall Player_Set_Balance
    rjmp set_credits_tick
    
set_credits_select:
    cpi temp, 3            ; Button Select -> Confirm and return to Main Menu
    brne set_credits_loop
    
    ; Play confirmation beep
    rcall Buzzer_Beep
    
    ; Switch state back to Main Menu
    ldi fsm_state, STATE_MAIN_MENU
    ret

; Show player credit configuration screen
Show_Credits_Menu:
    push temp
    push temp2
    push r24
    push r25
    push ZL
    push ZH
    
    rcall LCD_Clear
    
    ; Line 0: "P[ID] Set Bal: [Val]"
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    
    ldi temp, 'P'
    rcall lcd_write_data
    
    mov temp, active_plyr
    subi temp, -'0'
    rcall lcd_write_data
    
    ldi ZL, low(msg_set_bal_label * 2)
    ldi ZH, high(msg_set_bal_label * 2)
    rcall LCD_Print_Msg
    
    rcall Player_Get_Balance ; returns balance in r25:r24
    rcall LCD_Print_Dec16
    
    ; Line 1: "A:+100 B:-100 S:OK"
    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_credits_line1 * 2)
    ldi ZH, high(msg_credits_line1 * 2)
    rcall LCD_Print_Msg
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop temp2
    pop temp
    ret

Run_Choose_Cat:
    ; TODO: Choose bet category
    ret

Run_Choose_Bet:
    ; TODO: Choose bet number or color
    ret

Run_Confirm_Bet:
    ; TODO: Confirm bet value
    ret

Run_Spin_Roulette:
    ; TODO: Roulette spin animation
    ret

Run_Resolution:
    ; TODO: Calculate winnings and update balance
    ret

Run_En_Prison:
    ; TODO: Handle En Prison locked state
    ret

; Driver and Game Logic Inclusions
.include "hardware/lcd_i2c.asm"
.include "hardware/seven_seg.asm"
.include "hardware/max7219.asm"
.include "hardware/adc_buttons.asm"
.include "hardware/buzzer.asm"
.include "hardware/rgb_led.asm"
.include "game/prng.asm"
.include "game/roulette_rules.asm"
.include "game/players.asm"
.include "game/roulette_spin.asm"

; Flash Text Messages
msg_spinning:     .db "Girando roleta.", 0
msg_bal_label:    .db " Bal: ", 0, 0
msg_menu_line1:   .db "A:Mudar B:Cred S:Gira", 0
msg_set_bal_label:  .db " Set Bal: ", 0, 0
msg_credits_line1:  .db "A:+100 B:-100 S:OK", 0, 0
