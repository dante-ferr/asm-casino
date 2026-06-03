; MAX7219 8x8 LED matrix driver via software SPI
; Pins used: DIN on PC1, SCK on PC2, CS on PC3
; Uses a framebuffer in SRAM (RAM_SCREEN_BUF) for stable rendering

; Write 16-bit packet to MAX7219 (register in temp, data in temp2)
max7219_write:
    push temp
    push temp2
    push r20
    push r21

    cbi PORTC, MATRIX_CS    ; CS = 0 (enable transmission)
    
    ; Send register address
    mov r20, temp
    rcall max7219_send_byte

    ; Send data byte
    mov r20, temp2
    rcall max7219_send_byte

    sbi PORTC, MATRIX_CS    ; CS = 1 (latch data)
    
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Shift out 8 bits from r20 (MSB first)
max7219_send_byte:
    ldi r21, 8
send_bit_loop:
    sbi PORTC, MATRIX_DIN   ; default DIN to 1
    sbrs r20, 7             ; skip pull down if MSB is 1
    cbi PORTC, MATRIX_DIN   ; pull DIN to 0
    
    sbi PORTC, MATRIX_SCK   ; SCK = 1
    lsl r20                 ; shift register for next bit
    cbi PORTC, MATRIX_SCK   ; SCK = 0
    
    dec r21
    brne send_bit_loop
    ret

; Initialize MAX7219 settings and clear the matrix
Matrix_Init:
    ; Configure control pins as outputs
    sbi DDRC, MATRIX_DIN
    sbi DDRC, MATRIX_SCK
    sbi DDRC, MATRIX_CS
    
    ; CS starts high
    sbi PORTC, MATRIX_CS
    
    ; Shutdown register (0x0C): Normal operation (0x01)
    ldi temp, 0x0C
    ldi temp2, 0x01
    rcall max7219_write

    ; Display test register (0x0F): Normal mode (0x00)
    ldi temp, 0x0F
    ldi temp2, 0x00
    rcall max7219_write

    ; Decode mode register (0x09): No decode (0x00)
    ldi temp, 0x09
    ldi temp2, 0x00
    rcall max7219_write

    ; Scan limit register (0x0B): Scan all digits 0-7 (0x07)
    ldi temp, 0x0B
    ldi temp2, 0x07
    rcall max7219_write

    ; Intensity register (0x0A): Set brightness level (0x03)
    ldi temp, 0x0A
    ldi temp2, 0x03
    rcall max7219_write

    rcall Matrix_Clear
    ret

; Send framebuffer data to MAX7219
Matrix_Refresh:
    push temp
    push temp2
    ldi temp, 1             ; start at row 1
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
refresh_loop:
    ld temp2, Z+            ; load from buffer and increment pointer
    rcall max7219_write
    inc temp
    cpi temp, 9
    brne refresh_loop
    pop temp2
    pop temp
    ret

; Clear framebuffer and refresh screen
Matrix_Clear:
    push temp
    push ZL
    push ZH
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
    ldi temp2, 8
    ldi temp, 0
clear_buf_loop_main:
    st Z+, temp
    dec temp2
    brne clear_buf_loop_main
    rcall Matrix_Refresh
    pop ZH
    pop ZL
    pop temp
    ret

; Render and refresh LED matrix frame
; temp  = center pattern (0x80 = static diamond 2x2, 0x00/0xFF = empty)
; temp2 = ball index on circular border (0-19, or 0xFF = no ball)
Matrix_Render_Frame:
    push temp
    push temp2
    push r20
    push r21
    push ZL
    push ZH
    
    mov r20, temp           ; save center control code
    mov r21, temp2          ; save ball index
    
    ; 1. Clear local framebuffer in SRAM
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
    ldi temp2, 8
    ldi temp, 0
clear_frame_loop:
    st Z+, temp
    dec temp2
    brne clear_frame_loop
    
    ; 2. Render center pattern
    cpi r20, 0x80
    brne skip_center
    
    ; Render static diamond in the central 2x2 area (rows 4 and 5)
    ldi temp, 0x18          ; row 4: 00011000
    sts RAM_SCREEN_BUF+3, temp
    sts RAM_SCREEN_BUF+4, temp ; row 5: 00011000
    
skip_center:
    ; 3. Render ball position
    cpi r21, 0xFF
    breq skip_ball
    
    ; Multiply ball index by 2 to get offset in border_table
    lsl r21
    clr temp2
    ldi ZL, low(border_table * 2)
    ldi ZH, high(border_table * 2)
    add ZL, r21
    adc ZH, temp2
    lpm temp, Z+            ; fetch row (1 to 8)
    lpm temp2, Z            ; fetch column mask
    
    ; Convert row (1-8) to buffer offset (0-7)
    dec temp
    
    ; Apply bitmask using logical OR in framebuffer
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
    add ZL, temp
    clr r20
    adc ZH, r20
    ld r20, Z
    or r20, temp2
    st Z, r20
    
skip_ball:
    ; 4. Write framebuffer to MAX7219 registers
    rcall Matrix_Refresh
    
    pop ZH
    pop ZL
    pop r21
    pop r20
    pop temp2
    pop temp
    ret


; Coordinate table for the 20 LEDs around the circular border of the 8x8 matrix
; Format: Row (1-8), Column bitmask
border_table:
    ; Top-Left corner & Top row
    .db 2, 0x40, 1, 0x20, 1, 0x10, 1, 0x08, 1, 0x04, 2, 0x02
    ; Right column
    .db 3, 0x01, 4, 0x01, 5, 0x01, 6, 0x01
    ; Bottom-Right corner & Bottom row
    .db 7, 0x02, 8, 0x04, 8, 0x08, 8, 0x10, 8, 0x20, 7, 0x40
    ; Left column
    .db 6, 0x80, 5, 0x80, 4, 0x80, 3, 0x80

; Draw a static 8x8 icon on the LED matrix from Flash
; Inputs:
;   ZH:ZL = Flash address of the 8-byte icon data (multiplied by 2)
Matrix_Draw_Icon:
    push temp
    push r20
    push XL
    push XH
    push ZL
    push ZH
    
    ldi XL, low(RAM_SCREEN_BUF)
    ldi XH, high(RAM_SCREEN_BUF)
    ldi r20, 8                  ; 8 rows to copy
copy_icon_loop:
    lpm temp, Z+                ; load byte from Flash and post-increment Z
    st X+, temp                 ; store byte to SRAM and post-increment X
    dec r20
    brne copy_icon_loop
    
    ; Write SRAM buffer to MAX7219
    rcall Matrix_Refresh
    
    pop ZH
    pop ZL
    pop XH
    pop XL
    pop r20
    pop temp
    ret

; 8x8 Icon Definitions (8 bytes each)
icon_avatar:
    .db 0x18, 0x3C, 0x3C, 0x18, 0x3C, 0x7E, 0x7E, 0x00
    
icon_dollar:
    .db 0x10, 0x3C, 0x50, 0x38, 0x14, 0x3C, 0x10, 0x10
    
icon_question:
    .db 0x3C, 0x42, 0x02, 0x04, 0x08, 0x08, 0x00, 0x08

