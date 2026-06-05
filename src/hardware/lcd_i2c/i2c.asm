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
