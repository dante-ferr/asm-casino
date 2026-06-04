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
    ldi temp, 0b11101110   ; PD1-PD3 output, PD5-PD7 output. PD4 (Buzzer) is input. (PD0 RX/TX free)
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
    ldi temp, 4
    sts RAM_NUM_PLAYERS, temp ; Default to 4 players
    ldi fsm_state, STATE_WELCOME ; Start with welcome screen
    ldi active_plyr, 1     ; Start with Player 1
    ldi sys_flags, 0
    ldi temp, 0
    sts RAM_CURRENT_TRACK, temp ; Initialize music track index to 0

    ; 7b. Initialize soft PWM and fading variables
    ldi temp, 0
    sts RAM_PWM_COUNTER, temp
    sts RAM_PWM_TICK, temp
    sts RAM_FADE_STATE, temp
    sts RAM_PWM_GREEN, temp
    sts RAM_PWM_BLACK, temp
    ldi temp, 7
    sts RAM_PWM_RED, temp     ; Red starts at max
    ldi temp, 0
    sts RAM_ROUND_NUM, temp   ; Start animation at frame 0

    ; Set initial display values matching Player 1 (01)
    ldi temp, 1
    sts RAM_ROUND_NUM, temp
    ldi temp, 0
    sts RAM_BALL_IDX, temp

    ; Draw initial matrix state (static diamond, ball at index 0)
    ldi temp, 0x80         ; static diamond in the center
    ldi temp2, 0           ; ball at index 0
    rcall Matrix_Render_Frame
    
    ; Initial RGB LED color (matching Player 1)
    ldi temp, 1
    rcall RGB_Set_By_Player

    ; Enable global interrupts
    sei

; Main Loop
MAIN_LOOP:
    cpi fsm_state, STATE_MAIN_MENU
    brne CHECK_STATE_1
    call Run_Main_Menu
    rjmp MAIN_LOOP

CHECK_STATE_1:
    cpi fsm_state, STATE_CHOOSE_CAT
    brne CHECK_STATE_2
    call Run_Choose_Cat
    rjmp MAIN_LOOP

CHECK_STATE_2:
    cpi fsm_state, STATE_CHOOSE_BET
    brne CHECK_STATE_3
    call Run_Choose_Bet
    rjmp MAIN_LOOP

CHECK_STATE_3:
    cpi fsm_state, STATE_CONFIRM_BET
    brne CHECK_STATE_4
    call Run_Confirm_Bet
    rjmp MAIN_LOOP

CHECK_STATE_4:
    cpi fsm_state, STATE_SPIN_ROULET
    brne CHECK_STATE_5
    call Run_Spin_Roulette
    rjmp MAIN_LOOP

CHECK_STATE_5:
    cpi fsm_state, STATE_RESOLUTION
    brne CHECK_STATE_6
    call Run_Resolution
    rjmp MAIN_LOOP

CHECK_STATE_6:
    cpi fsm_state, STATE_EN_PRISON
    brne CHECK_STATE_7
    call Run_En_Prison
    rjmp MAIN_LOOP

CHECK_STATE_7:
    cpi fsm_state, STATE_SET_CREDITS
    brne CHECK_STATE_8
    call Run_Set_Credits
    rjmp MAIN_LOOP

CHECK_STATE_8:
    cpi fsm_state, STATE_NUM_PLAYERS
    brne CHECK_STATE_9
    call Run_Num_Players
    rjmp MAIN_LOOP

CHECK_STATE_9:
    cpi fsm_state, STATE_WELCOME
    brne MAIN_LOOP
    call Run_Welcome
    rjmp MAIN_LOOP

; Driver and Game Logic Inclusions
.include "hardware/lcd_i2c/main.asm"
.include "hardware/seven_seg/main.asm"
.include "hardware/max7219/main.asm"
.include "hardware/adc_buttons/main.asm"
.include "hardware/buzzer/main.asm"
.include "hardware/rgb_led/main.asm"
.include "game/players/main.asm"
.include "game/prng/main.asm"
.include "game/menu/main.asm"
.include "game/betting/main.asm"
.include "game/resolution/main.asm"

; Music tables placed at the end to prevent code segment bloating and relative address overflows
.include "game/music/ode_to_joy.asm"
.include "game/music/minuet_g.asm"
.include "game/music/tetris.asm"
.include "game/music/star_wars.asm"
.include "game/music/mario.asm"
