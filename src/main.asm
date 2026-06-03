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

    ; Clear display and ball index values
    ldi temp, 0
    sts RAM_ROUND_NUM, temp
    sts RAM_BALL_IDX, temp

    ; Draw initial matrix state (static diamond, ball at index 0)
    ldi temp, 0x80         ; static diamond in the center
    ldi temp2, 0           ; ball at index 0
    rcall Matrix_Render_Frame

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
    brne MAIN_LOOP
    rcall Run_En_Prison
    rjmp MAIN_LOOP

; FSM State Execution Subroutines (Stubs)

Run_Main_Menu:
    rcall LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_press_btn * 2)
    ldi ZH, high(msg_press_btn * 2)
    rcall LCD_Print_Msg

    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_btn_prefix * 2)
    ldi ZH, high(msg_btn_prefix * 2)
    rcall LCD_Print_Msg

test_button_loop:
    rcall Wait_Button_Press
    push temp

    ldi temp, 1
    ldi temp2, 7
    rcall LCD_Set_Cursor

    pop temp
    cpi temp, 1            ; Button A -> Increment index and move ball
    brne check_btn_b
    
    lds temp2, RAM_BALL_IDX
    inc temp2
    cpi temp2, 20
    brlo update_idx_a
    ldi temp2, 0           ; Wrap around to 0
update_idx_a:
    sts RAM_BALL_IDX, temp2
    sts RAM_ROUND_NUM, temp2 ; show index on 7-segment display
    
    ; Render frame with static diamond (0x80) and new ball index (temp2)
    ldi temp, 0x80
    rcall Matrix_Render_Frame

    ; Play button tick sound
    rcall Buzzer_Tick

    ldi ZL, low(msg_btn_a * 2)
    ldi ZH, high(msg_btn_a * 2)
    rcall LCD_Print_Msg
    rjmp test_button_loop

check_btn_b:
    cpi temp, 2            ; Button B -> Decrement index and move ball
    brne check_btn_select
    
    lds temp2, RAM_BALL_IDX
    tst temp2
    brne dec_idx
    ldi temp2, 19          ; Wrap around to 19
    rjmp update_idx_b
dec_idx:
    dec temp2
update_idx_b:
    sts RAM_BALL_IDX, temp2
    sts RAM_ROUND_NUM, temp2
    
    ; Render frame with static diamond (0x80) and new ball index (temp2)
    ldi temp, 0x80
    rcall Matrix_Render_Frame

    ; Play button tick sound
    rcall Buzzer_Tick

    ldi ZL, low(msg_btn_b * 2)
    ldi ZH, high(msg_btn_b * 2)
    rcall LCD_Print_Msg
    rjmp test_button_loop

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
    
    ; Restore static UI
    rcall LCD_Clear
    ldi temp, 0
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_press_btn * 2)
    ldi ZH, high(msg_press_btn * 2)
    rcall LCD_Print_Msg

    ldi temp, 1
    ldi temp2, 0
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_btn_prefix * 2)
    ldi ZH, high(msg_btn_prefix * 2)
    rcall LCD_Print_Msg

    ldi temp, 1
    ldi temp2, 7
    rcall LCD_Set_Cursor
    ldi ZL, low(msg_btn_sel * 2)
    ldi ZH, high(msg_btn_sel * 2)
    rcall LCD_Print_Msg
    rjmp test_button_loop

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
msg_press_btn:    .db "Aperte um botao", 0
msg_btn_prefix:   .db "Botao: ", 0
msg_btn_a:        .db "A      ", 0
msg_btn_b:        .db "B      ", 0
msg_btn_sel:      .db "Select ", 0
msg_spinning:     .db "Girando roleta.", 0
