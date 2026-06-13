; Atraso para sincronia do barramento I2C (Slower for physical hardware robustness)
i2c_delay:
    push temp2
    ldi temp2, 80
    i2c_delay_loop:
        dec temp2
        brne i2c_delay_loop
        pop temp2
        ret

; Atraso de 1 ms
delay_1ms:
    push temp
    push temp2
    ldi temp, 21
    delay_1ms_outer:
        ldi temp2, 253
    delay_1ms_inner:
        dec temp2
        brne delay_1ms_inner
        dec temp
        brne delay_1ms_outer
        pop temp2
        pop temp
        ret

; Atraso de N ms (N passado no temp)
delay_ms:
    tst temp
    breq delay_ms_ret
    delay_ms_loop:
        rcall delay_1ms
        dec temp
        brne delay_ms_loop
    delay_ms_ret:
        ret

; Condição de START no barramento I2C
i2c_start:
    cbi DDRC, LCD_SDA ; SDA = 1 (alta impedância)
    rcall i2c_delay
    cbi DDRC, LCD_SCL ; SCL = 1 (alta impedância)
    rcall i2c_delay
    sbi DDRC, LCD_SDA ; SDA = 0 (nível baixo)
    rcall i2c_delay
    sbi DDRC, LCD_SCL ; SCL = 0 (nível baixo)
    rcall i2c_delay
    ret

; Condição de STOP no barramento I2C
i2c_stop:
    sbi DDRC, LCD_SDA ; SDA = 0
    rcall i2c_delay
    cbi DDRC, LCD_SCL ; SCL = 1
    rcall i2c_delay
    cbi DDRC, LCD_SDA ; SDA = 1
    rcall i2c_delay
    ret

; Escreve um byte (passado no temp) via I2C
i2c_write_byte:
    push temp
    ldi temp2, 8 ; contador de bits
    i2c_bit_loop:
        lsl temp ; joga MSB para o carry
        brcs i2c_bit_one
        sbi DDRC, LCD_SDA ; se carry=0, zera SDA
        rjmp i2c_pulse_scl
    i2c_bit_one:
        cbi DDRC, LCD_SDA ; se carry=1, libera SDA
    i2c_pulse_scl:
        rcall i2c_delay
        cbi DDRC, LCD_SCL ; SCL = 1
        rcall i2c_delay
        sbi DDRC, LCD_SCL ; SCL = 0
        dec temp2
        brne i2c_bit_loop

        ; Bit de ACK/NACK (pulso no 9º clock)
        cbi DDRC, LCD_SDA ; libera SDA
        rcall i2c_delay ; espera o retorno do dispositivo
        cbi DDRC, LCD_SCL ; SCL = 1
        rcall i2c_delay
        sbi DDRC, LCD_SCL ; SCL = 0
        rcall i2c_delay
        pop temp
        ret
