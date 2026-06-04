; Global configurations and pin definitions
.include "m328Pdef.inc"

; Global Register Definitions
.def temp        = r16  ; General purpose temporary 1
.def temp2       = r17  ; General purpose temporary 2
.def argument    = r24  ; Argument passing (8 bits / 16-bit LSB)
.def argument_h  = r25  ; Argument passing (16-bit MSB)

.def fsm_state   = r20  ; FSM current state
.def active_plyr = r21  ; Active player ID (1 to 4)
.def sys_flags   = r22  ; General system flags

; Hardware Pin Mapping

; PORTB - 7-Segment Displays and Multiplexing Controls
; D8 -> PB0: Segment D
; D9 -> PB1: Segment E
; D10 -> PB2: Segment F
; D11 -> PB3: Segment G
; D12 -> PB4: Tens Digit Cathode (Left) - Active Low
; D13 -> PB5: Units Digit Cathode (Right) - Active Low
.equ SEG_D       = 0
.equ SEG_E       = 1
.equ SEG_F       = 2
.equ SEG_G       = 3
.equ DISP_DEC    = 4    ; Tens Digit Cathode
.equ DISP_UNI    = 5    ; Units Digit Cathode

; PORTD - 7-Segment Display, Buzzer, RGB LED
; D1 -> PD1: LED RGB Green Channel (Zero)
; D2 -> PD2: LED RGB Red Channel
; D3 -> PD3: LED RGB Blue/Black Channel (Black)
; D4 -> PD4: Buzzer
; D5 -> PD5: Segment A
; D6 -> PD6: Segment B
; D7 -> PD7: Segment C
.equ RGB_GREEN   = 1
.equ RGB_RED     = 2
.equ RGB_BLACK   = 3    ; Blue Channel of RGB LED
.equ BUZZER_PIN  = 4
.equ SEG_A       = 5
.equ SEG_B       = 6
.equ SEG_C       = 7

; PORTC - ADC (Keyboard) and Software SPI/I2C
; A0 -> PC0: ADC Input (Keyboard)
; A1 -> PC1: LED Matrix DIN (Software SPI)
; A2 -> PC2: LED Matrix SCK (Software SPI)
; A3 -> PC3: LED Matrix CS (Software SPI)
; A4 -> PC4: LCD SDA (Software I2C)
; A5 -> PC5: LCD SCL (Software I2C)
.equ KEYBOARD_PIN = 0   ; ADC0
.equ MATRIX_DIN   = 1
.equ MATRIX_SCK   = 2
.equ MATRIX_CS    = 3
.equ LCD_SDA      = 4
.equ LCD_SCL      = 5

; SRAM Addresses and Offsets (Player Layout)
.equ PLAYER_DATA_START = SRAM_START
.equ PLAYER_SIZE   = 16

.equ OFS_BAL_H     = 0  ; Balance (High Byte)
.equ OFS_BAL_L     = 1  ; Balance (Low Byte)
.equ OFS_STATUS    = 2  ; Status Byte (Bit 0: En Prison)
.equ OFS_BET_TYPE  = 3  ; Bet Type
.equ OFS_BET_TGT   = 4  ; Bet Target
.equ OFS_BET_VAL_H = 5  ; Bet Value (High Byte)
.equ OFS_BET_VAL_L = 6  ; Bet Value (Low Byte)
.equ OFS_HIST_START= 7  ; Local History (5 bytes: offsets 7 to 11)

; SRAM Global Variables
.equ RAM_ROUND_NUM = 0x0140 ; Drawn Number
.equ RAM_GLOB_HIST = 0x0141 ; General History (5 bytes)
.equ RAM_SEED_L    = 0x0146 ; PRNG Seed LSB
.equ RAM_SEED_H    = 0x0147 ; PRNG Seed MSB
.equ RAM_SYS_TICKS = 0x0148 ; System millisecond counter (1 byte)
.equ RAM_BALL_IDX  = 0x0149 ; Ball position index on matrix (1 byte)
.equ RAM_SCREEN_BUF = 0x014A ; LED matrix screen buffer (8 bytes, 0x014A-0x0151)
.equ RAM_NUM_PLAYERS = 0x0152 ; Number of active players (1 byte)
.equ RAM_PWM_COUNTER = 0x0153 ; Software PWM counter (1 byte)
.equ RAM_PWM_RED     = 0x0154 ; Red duty cycle (0 to 7)
.equ RAM_PWM_GREEN   = 0x0155 ; Green duty cycle (0 to 7)
.equ RAM_PWM_BLACK   = 0x0156 ; Blue duty cycle (0 to 7)
.equ RAM_PWM_TICK    = 0x0157 ; Fade tick counter (1 byte)
.equ RAM_FADE_STATE  = 0x0158 ; Fade state (0, 1, 2)

; FSM State Constants
.equ STATE_MAIN_MENU    = 0
.equ STATE_CHOOSE_CAT   = 1
.equ STATE_CHOOSE_BET   = 2
.equ STATE_CONFIRM_BET  = 3
.equ STATE_SPIN_ROULET  = 4
.equ STATE_RESOLUTION   = 5
.equ STATE_EN_PRISON    = 6
.equ STATE_SET_CREDITS  = 7
.equ STATE_NUM_PLAYERS  = 8
.equ STATE_WELCOME      = 9

; --- GAME ARCHITECTURAL SETTINGS ---
; Player limits
.equ START_BALANCE             = 1000  ; Initial player credits
.equ MIN_PLAYERS               = 1
.equ MAX_PLAYERS               = 4

; Credit adjustment settings
.equ CREDIT_STEP               = 100   ; Step value for adding/subtracting credits
.equ CREDIT_MAX_LIMIT          = 9900  ; Max allowed credits
.equ CREDIT_MIN_LIMIT          = 0     ; Min allowed credits

; Betting limits
.equ BET_STEP                  = 100   ; Step value for betting
.equ NUM_BET_TARGETS           = 43    ; Total target options (0-42)
.equ FIRST_INTERNAL_IDX        = 6     ; Start index for internal number bets (0-5 are external)

; Win payouts
.equ MULTIPLIER_INTERNAL_PAYOUT = 35   ; Internal bet payout multiplier
.equ MULTIPLIER_INTERNAL_TOTAL  = 36   ; Total internal payout value including original bet

; Roulette Wheel & Spin settings
.equ ROULETTE_SLOTS            = 37    ; Slots on French wheel (0 to 36)
.equ MATRIX_RING_SIZE          = 20    ; Total LEDs around the 8x8 border
.equ ROULETTE_ALIGN_OFFSET     = 2     ; Offset to align wheel zero with matrix ring index
.equ SPIN_MIN_LOOPS            = 2     ; Minimum wheel loops for spin animation
.equ SPIN_BASE_STEPS           = (SPIN_MIN_LOOPS * ROULETTE_SLOTS)
.equ RESULT_DELAY_COUNT        = 14    ; Result display delay loop count (20 * 250ms = 5 seconds)

; Logical Colors
.equ COLOR_GREEN               = 0
.equ COLOR_RED                 = 1
.equ COLOR_BLACK               = 2

; Hardware Button Analog Thresholds (Resistor Ladder)
.equ BTN_THRES_NONE            = 900
.equ BTN_THRES_SELECT          = 650
.equ BTN_THRES_B               = 450
.equ BTN_THRES_A               = 150

; LCD Commands & Parameters
.equ LCD_I2C_ADDR              = 0x7C
.equ LCD_CTRL_CMD              = 0x80
.equ LCD_CTRL_DATA             = 0x40
.equ LCD_CMD_CLEAR             = 0x01
.equ LCD_CMD_FUNC              = 0x38
.equ LCD_CMD_ON                = 0x0C
.equ LCD_CMD_ENTRY             = 0x06

; MAX7219 Commands & Parameters
.equ MAX7219_SHUTDOWN          = 0x0C
.equ MAX7219_TEST              = 0x0F
.equ MAX7219_DECODE            = 0x09
.equ MAX7219_SCAN_LIMIT        = 0x0B
.equ MAX7219_INTENSITY         = 0x0A
.equ MAX7219_BRIGHTNESS        = 0x03

; Buzzer Tone Settings
.equ TONE_TICK_PITCH           = 50
.equ TONE_TICK_LEN             = 10
.equ TONE_BEEP_PITCH           = 100
.equ TONE_BEEP_LEN             = 80

