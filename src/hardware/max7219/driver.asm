; Envia pacote de 16 bits para o MAX7219 (registrador em temp, dado em temp2)
max7219_write:
    push temp
    push temp2
    push r20
    push r21

    cbi PORTC, MATRIX_CS ; CS = 0 (inicia transmissão)
    
    ; Envia o endereço do registrador
    mov r20, temp
    rcall max7219_send_byte

    ; Envia o byte de dado
    mov r20, temp2
    rcall max7219_send_byte

    sbi PORTC, MATRIX_CS ; CS = 1 (salva o dado)
    
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Envia 8 bits do r20 (MSB primeiro)
max7219_send_byte:
    ldi r21, 8
send_bit_loop:
    sbi PORTC, MATRIX_DIN ; DIN padrão em 1
    sbrs r20, 7 ; pula se o MSB for 1
    cbi PORTC, MATRIX_DIN ; coloca DIN em 0
    
    sbi PORTC, MATRIX_SCK ; clock alto
    lsl r20 ; rotaciona bit
    cbi PORTC, MATRIX_SCK ; clock baixo
    
    dec r21
    brne send_bit_loop
    ret

; Inicializa as configurações do MAX7219 e limpa a matriz
Matrix_Init:
    ; Configura pinos de controle como saída
    sbi DDRC, MATRIX_DIN
    sbi DDRC, MATRIX_SCK
    sbi DDRC, MATRIX_CS
    
    ; CS inicializa em nível alto
    sbi PORTC, MATRIX_CS
    
    ; Modo de operação normal
    ldi temp, MAX7219_SHUTDOWN
    ldi temp2, 0x01
    rcall max7219_write

    ; Modo de teste desligado
    ldi temp, MAX7219_TEST
    ldi temp2, 0x00
    rcall max7219_write

    ; Sem decodificação de caracteres
    ldi temp, MAX7219_DECODE
    ldi temp2, 0x00
    rcall max7219_write

    ; Habilita todas as 8 linhas
    ldi temp, MAX7219_SCAN_LIMIT
    ldi temp2, 0x07
    rcall max7219_write

    ; Ajusta brilho
    ldi temp, MAX7219_INTENSITY
    ldi temp2, MAX7219_BRIGHTNESS
    rcall max7219_write

    rcall Matrix_Clear
    ret

; Envia os dados do framebuffer para o MAX7219
Matrix_Refresh:
    push temp
    push temp2
    push r20
    push r21
    
    ldi temp, 1 ; começa na linha/registrador 1 do MAX7219
    ; Inicializa o ponteiro Z no fim do buffer + 1 (para o pré-decremento)
    ldi ZL, low(RAM_SCREEN_BUF + 8)
    ldi ZH, high(RAM_SCREEN_BUF + 8)
    
refresh_loop:
    ld temp2, -Z ; pré-decrementa Z e carrega do buffer (inversão vertical)
    
    ; Inverte a ordem dos bits de temp2 (inversão horizontal)
    ldi r20, 8
    clr r21
reverse_bit_loop:
    rol temp2
    ror r21
    dec r20
    brne reverse_bit_loop
    mov temp2, r21
    
    rcall max7219_write
    inc temp
    cpi temp, 9
    brne refresh_loop
    
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Limpa o framebuffer e atualiza a tela
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

; Renderiza e atualiza o frame na matriz de LED
; temp  = padrão central (0x80 = diamante, 0x00/0xFF = vazio)
; temp2 = índice da bola na borda (0-19, ou 0xFF = sem bola)
Matrix_Render_Frame:
    push temp
    push temp2
    push r20
    push r21
    push ZL
    push ZH
    
    mov r20, temp ; save center control code
    mov r21, temp2 ; save ball index
    
    ; Limpa o framebuffer local na SRAM
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
    ldi temp2, 8
    ldi temp, 0
clear_frame_loop:
    st Z+, temp
    dec temp2
    brne clear_frame_loop
    
    ; Desenha o padrão central
    cpi r20, 0x80
    brne skip_center
    
    ; Desenha diamante estático na área central (linhas 4 e 5)
    ldi temp, 0x18 ; linha 4: 00011000
    sts RAM_SCREEN_BUF+3, temp
    sts RAM_SCREEN_BUF+4, temp ; linha 5: 00011000
    
skip_center:
    ; Desenha a posição da bola
    cpi r21, 0xFF
    breq skip_ball
    
    ; Multiplica o índice por 2 para achar o deslocamento na tabela
    lsl r21
    clr temp2
    ldi ZL, low(border_table * 2)
    ldi ZH, high(border_table * 2)
    add ZL, r21
    adc ZH, temp2
    lpm temp, Z+ ; lê a linha (1 a 8)
    lpm temp2, Z ; lê a máscara da coluna
    
    ; Converte linha (1-8) para offset do buffer (0-7)
    dec temp
    
    ; Aplica a máscara usando OR lógico no framebuffer
    ldi ZL, low(RAM_SCREEN_BUF)
    ldi ZH, high(RAM_SCREEN_BUF)
    add ZL, temp
    clr r20
    adc ZH, r20
    ld r20, Z
    or r20, temp2
    st Z, r20
    
skip_ball:
    ; Escreve o framebuffer nos registradores do MAX7219
    rcall Matrix_Refresh
    
    pop ZH
    pop ZL
    pop r21
    pop r20
    pop temp2
    pop temp
    ret

; Desenha um ícone estático de 8x8 da Flash na matriz
; Entradas:
;   ZH:ZL = Endereço do ícone de 8 bytes na Flash (multiplicado por 2)
Matrix_Draw_Icon:
    push temp
    push r20
    push XL
    push XH
    push ZL
    push ZH
    
    ldi XL, low(RAM_SCREEN_BUF)
    ldi XH, high(RAM_SCREEN_BUF)
    ldi r20, 8 ; 8 linhas para copiar
copy_icon_loop:
    lpm temp, Z+ ; lê byte da Flash
    st X+, temp ; salva byte na SRAM
    dec r20
    brne copy_icon_loop
    
    ; Envia buffer da SRAM para o MAX7219
    rcall Matrix_Refresh
    
    pop ZH
    pop ZL
    pop XH
    pop XL
    pop r20
    pop temp
    ret
