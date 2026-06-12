.if USE_PCF8574_BACKPACK == 1

; =========================================================================
; --- DRIVER DO SHIELD I2C PCF8574 (HARDWARE REAL) ---
; =========================================================================

; Escreve comando no LCD (comando em temp)
lcd_write_cmd:
    push temp2
    ldi temp2, 0x08 ; RS = 0, BL = 1 (luz de fundo ligada)
    rcall lcd_write_byte
    pop temp2
    
    ; Atraso de ~47us para execução do comando
    push temp
    push temp2
    ldi temp, 5
lcd_cmd_delay_outer:
    ldi temp2, 50
lcd_cmd_delay_inner:
    dec temp2
    brne lcd_cmd_delay_inner
    dec temp
    brne lcd_cmd_delay_outer
    pop temp2
    pop temp
    ret

; Escreve caractere/dado no LCD (dado em temp)
lcd_write_data:
    push temp2
    ldi temp2, 0x09 ; RS = 1, BL = 1 (luz de fundo ligada)
    rcall lcd_write_byte
    pop temp2
    ret

; Escreve byte em modo de 4 bits (temp = byte, temp2 = flags RS | BL)
lcd_write_byte:
    push r18
    push r19
    mov r18, temp ; salva byte
    mov r19, temp2 ; salva flags
    
    ; Envia os 4 bits mais significativos
    mov temp, r18
    andi temp, 0xF0 ; mantém os bits altos
    or temp, r19 ; junta RS e BL
    rcall lcd_write_nibble
    
    ; Envia os 4 bits menos significativos
    mov temp, r18
    swap temp ; inverte os nibbles
    andi temp, 0xF0 ; mantém os bits baixos
    or temp, r19 ; junta RS e BL
    rcall lcd_write_nibble
    
    pop r19
    pop r18
    ret

; Escreve um nibble no PCF8574 e gera pulso no pino Enable (EN)
; Entrada: temp = dados (bits 4-7) e controle (bits 0-3, bit 2 é EN)
lcd_write_nibble:
    rcall i2c_start
    ldi temp2, LCD_I2C_ADDR ; endereço I2C do PCF8574
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    pop temp
    
    ; Envia com EN = 1
    push temp
    ori temp, 0x04 ; ativa EN
    rcall i2c_write_byte
    pop temp
    
    ; Envia com EN = 0 para registrar o dado
    push temp
    andi temp, ~0x04 ; desativa EN
    rcall i2c_write_byte
    pop temp
    
    rcall i2c_stop
    ret

; Inicializa o LCD no modo I2C usando o PCF8574
LCD_Init:
    ; Configura PC4 e PC5 como dreno aberto
    cbi DDRC, LCD_SDA
    cbi DDRC, LCD_SCL
    cbi PORTC, LCD_SDA
    cbi PORTC, LCD_SCL

    ; Aguarda estabilização da tensão
    ldi temp, 50
    rcall delay_ms

    ; Sequência de inicialização de 4 bits para o HD44780
    ; Envia nibble 0x30 (modo de 8 bits)
    ldi temp, 0x30 | 0x08 ; BL = 1
    rcall lcd_write_nibble
    ldi temp, 5
    rcall delay_ms ; espera mais de 4.1ms

    ; Repete o envio de 0x30
    ldi temp, 0x30 | 0x08
    rcall lcd_write_nibble
    ldi temp, 1
    rcall delay_ms ; espera mais de 100us

    ; Repete mais uma vez o envio de 0x30
    ldi temp, 0x30 | 0x08
    rcall lcd_write_nibble
    ldi temp, 1
    rcall delay_ms

    ; Envia nibble 0x20 para mudar para modo de 4 bits
    ldi temp, 0x20 | 0x08
    rcall lcd_write_nibble
    ldi temp, 1
    rcall delay_ms

    ; Configura display: modo 4 bits, 2 linhas, fonte 5x8
    ldi temp, 0x28
    rcall lcd_write_cmd

    ; Liga tela, desliga cursor
    ldi temp, 0x0C
    rcall lcd_write_cmd

    ; Modo de entrada: auto-incremento
    ldi temp, 0x06
    rcall lcd_write_cmd

    rcall LCD_Clear
    ret

; Limpa a tela do LCD
LCD_Clear:
    ldi temp, LCD_CMD_CLEAR ; comando de limpar
    rcall lcd_write_cmd
    ldi temp, 2
    rcall delay_ms
    ret

.else

; =========================================================================
; --- DRIVER DO LCD NATIVO ST7032 (SIMULAÇÃO SIMULIDE) ---
; =========================================================================

; Escreve comando no LCD (comando em temp)
lcd_write_cmd:
    rcall i2c_start
    ldi temp2, LCD_I2C_ADDR ; endereço do LCD
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, LCD_CTRL_CMD ; byte de controle: próximo byte é comando
    rcall i2c_write_byte
    pop temp
    rcall i2c_write_byte ; envia comando
    rcall i2c_stop
    
    ; Atraso de ~47us para execução do comando
    push temp
    push temp2
    ldi temp, 5
lcd_cmd_delay_outer:
    ldi temp2, 50
lcd_cmd_delay_inner:
    dec temp2
    brne lcd_cmd_delay_inner
    dec temp
    brne lcd_cmd_delay_outer
    pop temp2
    pop temp
    ret

; Escreve caractere/dado no LCD (caractere em temp)
lcd_write_data:
    rcall i2c_start
    ldi temp2, LCD_I2C_ADDR ; endereço do LCD
    push temp
    mov temp, temp2
    rcall i2c_write_byte
    ldi temp, LCD_CTRL_DATA ; byte de controle: próximo byte é dado
    rcall i2c_write_byte
    pop temp
    rcall i2c_write_byte ; envia caractere
    rcall i2c_stop
    ret

; Inicializa o LCD no modo I2C
LCD_Init:
    ; Configura PC4 e PC5 como dreno aberto
    cbi DDRC, LCD_SDA
    cbi DDRC, LCD_SCL
    cbi PORTC, LCD_SDA
    cbi PORTC, LCD_SCL

    ; Aguarda estabilização da tensão
    ldi temp, 50
    rcall delay_ms

    ; Configura display (modo 8 bits, 2 linhas, fonte 5x8)
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd
    ldi temp, 5
    rcall delay_ms

    ; Configura display
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd
    ldi temp, 1
    rcall delay_ms

    ; Configura display
    ldi temp, LCD_CMD_FUNC
    rcall lcd_write_cmd

    ; Liga tela, desliga cursor
    ldi temp, LCD_CMD_ON
    rcall lcd_write_cmd

    ; Modo de entrada: auto-incremento do cursor
    ldi temp, LCD_CMD_ENTRY
    rcall lcd_write_cmd

    rcall LCD_Clear
    ret

; Limpa a tela do LCD
LCD_Clear:
    ldi temp, LCD_CMD_CLEAR
    rcall lcd_write_cmd
    ldi temp, 2
    rcall delay_ms
    ret

.endif

; Posiciona o cursor (temp = linha 0 ou 1, temp2 = coluna 0 a 15)
LCD_Set_Cursor:
    push temp
    tst temp
    breq cursor_line0
    ldi temp, 0xC0 ; linha 1
    rjmp cursor_add_col
cursor_line0:
    ldi temp, 0x80 ; linha 0
cursor_add_col:
    add temp, temp2
    rcall lcd_write_cmd
    pop temp
    ret

; Imprime string terminada em zero da Flash apontada por Z
LCD_Print_Msg:
    lpm temp, Z+
    tst temp
    breq lcd_print_ret
    rcall lcd_write_data
    rjmp LCD_Print_Msg
lcd_print_ret:
    ret

; Imprime inteiro sem sinal de 16 bits (r24:r25) com supressão de zeros à esquerda
LCD_Print_Dec16:
    push temp
    push temp2
    push r20
    push r21
    push r22
    push r23
    
    mov r22, r24
    mov r23, r25 ; r23:r22 = valor
    
    ; Casa dos 10000
    ldi r20, 0 ; acumulador de dígitos
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
    ldi r21, 1 ; flag: imprimiu primeiro dígito
    rjmp check_1k
skip_10k:
    ldi r21, 0 ; flag: nenhum dígito impresso ainda
    
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

    ; Casa dos 100
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

    ; Casa dos 10
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

    ; Casa das unidades (sempre impressa)
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
