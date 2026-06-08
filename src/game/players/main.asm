; Inicialização e gerenciamento dos dados dos jogadores
; Inicializa saldos com 1000 pontos e limpa estados do jogo para até 4 jogadores

; Inicializa dados na SRAM para todos os jogadores
Players_Init:
    push temp
    push temp2
    push ZL
    push ZH
    push r20
    
    ldi ZL, low(PLAYER_DATA_START)
    ldi ZH, high(PLAYER_DATA_START)
    
    ldi r20, MAX_PLAYERS ; define o número máximo de jogadores
players_init_loop:
    ; Define o saldo inicial de cada jogador
    ldi temp, high(START_BALANCE) ; parte alta do saldo inicial
    st Z+, temp
    ldi temp, low(START_BALANCE) ; parte baixa do saldo inicial
    st Z+, temp
    
    ; Zera os bytes restantes da estrutura do jogador
    ldi temp, PLAYER_SIZE - 2
    ldi temp2, 0
init_zeros_loop:
    st Z+, temp2
    dec temp
    brne init_zeros_loop
    
    dec r20
    brne players_init_loop
    
    pop r20
    pop ZH
    pop ZL
    pop temp2
    pop temp
    ret

; Obtém o ponteiro SRAM para a ficha do jogador ativo
; Entradas:
;   active_plyr = ID do jogador (1 a 4)
; Saídas:
;   ZH:ZL = ponteiro SRAM
Player_Get_Pointer:
    push temp
    push temp2
    push r24
    
    ldi ZL, low(PLAYER_DATA_START)
    ldi ZH, high(PLAYER_DATA_START)
    
    mov temp, active_plyr
    dec temp
    breq get_ptr_done ; se for o jogador 1, offset é zero
    
    ldi r24, PLAYER_SIZE ; tamanho da estrutura de cada jogador
    clr temp2 ; limpa registrador para soma de carry
get_ptr_loop:
    add ZL, r24
    adc ZH, temp2
    dec temp
    brne get_ptr_loop
    
get_ptr_done:
    pop r24
    pop temp2
    pop temp
    ret

; Lê o saldo do jogador ativo
; Saídas:
;   r25 = parte alta do saldo
;   r24 = parte baixa do saldo
Player_Get_Balance:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ld r25, Z+ ; lê a parte alta
    ld r24, Z ; lê a parte baixa
    pop ZH
    pop ZL
    ret

; Define o saldo do jogador ativo
; Entradas:
;   r25 = parte alta do saldo
;   r24 = parte baixa do saldo
Player_Set_Balance:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    st Z+, r25 ; salva a parte alta
    st Z, r24 ; salva a parte baixa
    pop ZH
    pop ZL
    ret

; Lê o byte de status do jogador ativo
; Saídas:
;   temp = byte de status
Player_Get_Status:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ldd temp, Z+2 ; byte de status no offset 2
    pop ZH
    pop ZL
    ret

; Define o byte de status do jogador ativo
; Entradas:
;   temp = byte de status
Player_Set_Status:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    std Z+2, temp
    pop ZH
    pop ZL
    ret

; Lê os detalhes da aposta do jogador ativo
; Saídas:
;   temp = tipo da aposta
;   temp2 = alvo da aposta
;   r25:r24 = valor da aposta
Player_Get_Bet:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    ldd temp, Z+3 ; tipo da aposta
    ldd temp2, Z+4 ; alvo da aposta
    ldd r25, Z+5 ; valor da aposta (parte alta)
    ldd r24, Z+6 ; valor da aposta (parte baixa)
    pop ZH
    pop ZL
    ret

; Define os detalhes da aposta do jogador ativo
; Entradas:
;   temp = tipo da aposta
;   temp2 = alvo da aposta
;   r25:r24 = valor da aposta
Player_Set_Bet:
    push ZL
    push ZH
    rcall Player_Get_Pointer
    std Z+3, temp
    std Z+4, temp2
    std Z+5, r25
    std Z+6, r24
    pop ZH
    pop ZL
    ret
