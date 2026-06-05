; Write command to LCD (command in temp)
lcd_write_cmd:
    rcall i2c_start
    ldi temp2, LCD_I2C_ADDR       ; LCD write address
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, LCD_CTRL_CMD        ; control byte: next byte is command
    rcall i2c_write_byte
    pop temp
    rcall i2c_write_byte  ; send command
    rcall i2c_stop
    ret

; Write data/character to LCD (char in temp)
lcd_write_data:
    rcall i2c_start
    ldi temp2, LCD_I2C_ADDR       ; LCD write address
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, LCD_CTRL_DATA       ; control byte: next byte is data
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
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd
    ldi temp, 5
    rcall delay_ms

    ; Function set
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd
    ldi temp, 1
    rcall delay_ms

    ; Function set
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd

    ; Display ON, cursor OFF
    ldi temp, LCD_CMD_ON
    rcall lcd_write_cmd

    ; Entry mode: auto-increment cursor
    ldi temp, LCD_CMD_ENTRY
    rcall lcd_write_cmd

    rcall LCD_Clear
    ret

; Clear LCD display
LCD_Clear:
    ldi temp, LCD_CMD_CLEAR
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

; Print 16-bit unsigned integer (in r24:r25) on LCD with leading zero suppression
LCD_Print_Dec16:
    push temp
    push temp2
    push r20
    push r21
    push r22
    push r23
    
    mov r22, r24
    mov r23, r25            ; r23:r22 = value
    
    ; 10000s digit
    ldi r20, 0              ; digit accumulator
    ldi r24, low(10000)
    ldi r25, high(10000)
div_10k:
    cp r22, r24
    cpc r23, r25
    brlo print_10k
    sub r22, r24
    sbc r23, r25
    inc r20
    rjmp div_10k
print_10k:
    tst r20
    breq skip_10k
    subi r20, -'0'
    mov temp, r20
    rcall lcd_write_data
    ldi r21, 1              ; flag: printed first digit
    rjmp check_1k
skip_10k:
    ldi r21, 0              ; flag: no digits printed yet
    
check_1k:
    ldi r20, 0
    ldi r24, low(1000)
    ldi r25, high(1000)
div_1k:
    cp r22, r24
    cpc r23, r25
    brlo print_1k
    sub r22, r24
    sbc r23, r25
    inc r20
    rjmp div_1k
print_1k:
    tst r20
    brne print_1k_digit
    tst r21
    breq skip_1k
print_1k_digit:
    subi r20, -'0'
    mov temp, r20
    rcall lcd_write_data
    ldi r21, 1
skip_1k:

    ; 100s digit
    ldi r20, 0
div_100:
    cpi r22, 100
    ldi temp, 0
    cpc r23, temp
    brlo print_100
    subi r22, 100
    sbci r23, 0
    inc r20
    rjmp div_100
print_100:
    tst r20
    brne print_100_digit
    tst r21
    breq skip_100
print_100_digit:
    subi r20, -'0'
    mov temp, r20
    rcall lcd_write_data
    ldi r21, 1
skip_100:

    ; 10s digit
    ldi r20, 0
div_10:
    cpi r22, 10
    brlo print_10
    subi r22, 10
    inc r20
    rjmp div_10
print_10:
    tst r20
    brne print_10_digit
    tst r21
    breq skip_10
print_10_digit:
    subi r20, -'0'
    mov temp, r20
    rcall lcd_write_data
skip_10:

    ; 1s digit (always printed)
    subi r22, -'0'
    mov temp, r22
    rcall lcd_write_data
    
    pop r23
    pop r22
    pop r21
    pop r20
    pop temp2
    pop temp
    ret
