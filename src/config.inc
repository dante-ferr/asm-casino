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

; FSM State Constants
.equ STATE_MAIN_MENU    = 0
.equ STATE_CHOOSE_CAT   = 1
.equ STATE_CHOOSE_BET   = 2
.equ STATE_CONFIRM_BET  = 3
.equ STATE_SPIN_ROULET  = 4
.equ STATE_RESOLUTION   = 5
.equ STATE_EN_PRISON    = 6
