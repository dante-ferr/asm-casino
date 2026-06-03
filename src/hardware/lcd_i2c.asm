; LCD I2C Display Driver (AIP31068 controller) via Bit-Banging
; Pins used: SDA on PC4, SCL on PC5

; Delay of ~4.5 us for I2C bus timing
i2c_delay:
    push temp2
    ldi temp2, 20
i2c_delay_loop:
    dec temp2
    brne i2c_delay_loop
    pop temp2
    ret

; Delay of 1 ms
delay_1ms:
    push temp
    push temp2
    ldi temp, 16
delay_1ms_outer:
    ldi temp2, 250
delay_1ms_inner:
    dec temp2
    brne delay_1ms_inner
    dec temp
    brne delay_1ms_outer
    pop temp2
    pop temp
    ret

; Delay of N ms (N passed in temp)
delay_ms:
    tst temp
    breq delay_ms_ret
delay_ms_loop:
    rcall delay_1ms
    dec temp
    brne delay_ms_loop
delay_ms_ret:
    ret

; START condition on I2C bus
i2c_start:
    cbi DDRC, LCD_SDA     ; SDA = 1 (high impedance)
    rcall i2c_delay
    cbi DDRC, LCD_SCL     ; SCL = 1 (high impedance)
    rcall i2c_delay
    sbi DDRC, LCD_SDA     ; SDA = 0 (pull low)
    rcall i2c_delay
    sbi DDRC, LCD_SCL     ; SCL = 0 (pull low)
    rcall i2c_delay
    ret

; STOP condition on I2C bus
i2c_stop:
    sbi DDRC, LCD_SDA     ; SDA = 0
    rcall i2c_delay
    cbi DDRC, LCD_SCL     ; SCL = 1
    rcall i2c_delay
    cbi DDRC, LCD_SDA     ; SDA = 1
    rcall i2c_delay
    ret

; Write one byte (in temp) via I2C
i2c_write_byte:
    push temp
    ldi temp2, 8          ; bit counter
i2c_bit_loop:
    lsl temp              ; shift MSB to carry
    brcs i2c_bit_one
    sbi DDRC, LCD_SDA     ; if carry=0, pull SDA low
    rjmp i2c_pulse_scl
i2c_bit_one:
    cbi DDRC, LCD_SDA     ; if carry=1, release SDA high
i2c_pulse_scl:
    rcall i2c_delay
    cbi DDRC, LCD_SCL     ; SCL = 1
    rcall i2c_delay
    sbi DDRC, LCD_SCL     ; SCL = 0
    dec temp2
    brne i2c_bit_loop

    ; ACK/NACK bit (pulse 9th clock)
    cbi DDRC, LCD_SDA     ; release SDA
    rcall i2c_delay
    cbi DDRC, LCD_SCL     ; SCL = 1
    rcall i2c_delay
    sbi DDRC, LCD_SCL     ; SCL = 0
    rcall i2c_delay
    pop temp
    ret

; Write command to LCD (command in temp)
lcd_write_cmd:
    rcall i2c_start
    ldi temp2, 0x7C       ; LCD write address
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, 0x80        ; control byte: next byte is command
    rcall i2c_write_byte
    pop temp
    rcall i2c_write_byte  ; send command
    rcall i2c_stop
    ret

; Write data/character to LCD (char in temp)
lcd_write_data:
    rcall i2c_start
    ldi temp2, 0x7C       ; LCD write address
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, 0x40        ; control byte: next byte is data
    rcall i2c_write_byte
    pop temp
    rcall i2c_write_byte  ; send character
    rcall i2c_stop
    ret

; Initialize LCD in I2C mode
LCD_Init:
    ; Configure PC4 and PC5 as open-drain (PORT=0, DDR=0 for high impedance)
    cbi DDRC, LCD_SDA
    cbi DDRC, LCD_SCL
    cbi PORTC, LCD_SDA
    cbi PORTC, LCD_SCL

    ; Wait for power stabilization
    ldi temp, 20
    rcall delay_ms

    ; Function set (8-bit mode, 2 lines, 5x8 font)
    ldi temp, 0x38
    rcall lcd_write_cmd
    ldi temp, 5
    rcall delay_ms

    ldi temp, 0x38
    rcall lcd_write_cmd
    ldi temp, 1
    rcall delay_ms

    ldi temp, 0x38
    rcall lcd_write_cmd

    ; Display ON, cursor OFF
    ldi temp, 0x0C
    rcall lcd_write_cmd

    ; Entry mode: auto-increment cursor
    ldi temp, 0x06
    rcall lcd_write_cmd

    rcall LCD_Clear
    ret

; Clear LCD display
LCD_Clear:
    ldi temp, 0x01
    rcall lcd_write_cmd
    ldi temp, 2
    rcall delay_ms
    ret

; Set cursor position (temp = row 0 or 1, temp2 = col 0 to 15)
LCD_Set_Cursor:
    push temp
    tst temp
    breq cursor_line0
    ldi temp, 0xC0        ; row 1 (0x80 | 0x40)
    rjmp cursor_add_col
cursor_line0:
    ldi temp, 0x80        ; row 0 (0x80 | 0x00)
cursor_add_col:
    add temp, temp2
    rcall lcd_write_cmd
    pop temp
    ret

; Print null-terminated string from Flash pointed by Z register
LCD_Print_Msg:
    lpm temp, Z+
    tst temp
    breq lcd_print_ret
    rcall lcd_write_data
    rjmp LCD_Print_Msg
lcd_print_ret:
    ret
