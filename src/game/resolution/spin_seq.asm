; Lógica modular da sequência de giro da roleta
; Controla as etapas de animação, mapeamento de LEDs, desaceleração e efeitos sonoros.

; Executa a sequência completa de giro da roleta
; Entradas: Nenhuma
; Saídas:
;   temp2 = número vencedor (0-36)
Run_Roulette_Spin_Sequence:
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH
    
    ; Sorteia um índice de slot vencedor pseudoaleatório (0 a 36) usando o PRNG
    call PRNG_Spin
    mov r22, temp2 ; r22 agora contém o índice do slot vencedor S_win (0 a 36)
    
    ; Determina o total de passos para a animação (pelo menos 2 voltas completas + S_win)
    ; passos totais = SPIN_BASE_STEPS + S_win
    ldi r23, SPIN_BASE_STEPS
    add r23, r22 ; r23 = passos restantes (contador decrescente)
    
    push r22 ; salva o slot vencedor sorteado (S_win)
    
    ; Executa o loop de animação do giro
    ldi r21, 0 ; r21 = índice do slot atual S (começa em 0)
spin_anim_loop:
    ; Salva os passos restantes e o slot atual
    push r23
    push r21
    
    ; Lê o número correspondente ao slot S
    ldi ZL, low(roulette_wheel_table * 2)
    ldi ZH, high(roulette_wheel_table * 2)
    add ZL, r21
    clr temp
    adc ZH, temp
    lpm r24, Z ; r24 = número atual (0-36)
    
    ; Atualiza o display de 7 segmentos com o número atual
    sts RAM_ROUND_NUM, r24
    
    ; Configura a cor do LED RGB com base no número atual
    mov temp, r24
    call RGB_Set_By_Number
    
    ; Mapeia o slot S (r21) para o índice L da matriz de LEDs (0-19)
    ; Fórmula: L = (S * 20) / 37
    mov r22, r21 ; S
    rcall map_slot_to_led ; retorna L em r20
    
    ; Renderiza o frame da matriz com losango estático e bola em L
    ldi temp, 0x80
    mov temp2, r20
    call Matrix_Render_Frame
    
    ; Toca som a cada passo do giro
    call Buzzer_Tick
    
    ; Desacelera usando atraso variável com base nos passos restantes (r23)
    pop r21 ; restaura S
    pop r23 ; restaura quantidade de passos restantes
    
    mov temp, r23 ; determina o atraso pelos passos restantes
    rcall get_friction_delay ; retorna o atraso em temp
    call delay_ms
    
    ; Avança para o próximo slot físico no sentido horário
    inc r21
    cpi r21, ROULETTE_SLOTS
    brlo slot_no_wrap
    ldi r21, 0
slot_no_wrap:
    
    dec r23
    brne spin_anim_loop
    
    pop r22 ; restaura o slot vencedor (S_win)
    
    ; Passo final: para no slot vencedor
    ldi ZL, low(roulette_wheel_table * 2)
    ldi ZH, high(roulette_wheel_table * 2)
    add ZL, r22
    clr temp
    adc ZH, temp
    lpm r24, Z ; r24 = número vencedor (0-36)
    
    ; Salva o número vencedor final na RAM
    sts RAM_ROUND_NUM, r24
    
    ; Mapeia o slot vencedor S_win (r22) para o índice L da matriz de LEDs
    rcall map_slot_to_led ; retorna L em r20
    sts RAM_BALL_IDX, r20 ; salva o índice final da bola
    
    ; Renderiza o frame final
    ldi temp, 0x80
    mov temp2, r20
    call Matrix_Render_Frame
    
    ; Acende o LED RGB na cor vencedora
    mov temp, r24
    call RGB_Set_By_Number
    
    ; Retorna o número vencedor em temp2
    mov temp2, r24
    
    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    ret

; Calcula o índice físico do LED (L) para o slot atual da roleta (S)
; Fórmula: L = (S * 20) / 37
; Entradas:
;   r22 = Índice do slot (0-36)
; Saídas:
;   r20 = Índice do LED (0-19)
map_slot_to_led:
    push temp
    push r24
    push r25
    
    ; Multiplica S (r22) por MATRIX_RING_SIZE -> resultado em r25:r24
    clr r24
    clr r25
    ldi temp, MATRIX_RING_SIZE
mul_loop_spin:
    add r24, r22
    clr r20
    adc r25, r20
    dec temp
    brne mul_loop_spin
    
    ; Divide r25:r24 por ROULETTE_SLOTS via subtrações sucessivas
    clr r20 ; r20 guardará o resultado (L)
div_loop_spin:
    cpi r24, ROULETTE_SLOTS
    ldi temp, 0
    cpc r25, temp
    brlo div_done_spin ; se r25:r24 < ROULETTE_SLOTS, encerra
    
    subi r24, ROULETTE_SLOTS
    sbci r25, 0
    inc r20
    rjmp div_loop_spin
    
div_done_spin:
    ; Adiciona o deslocamento de alinhamento para o zero da roleta ficar na posição correta
    subi r20, -ROULETTE_ALIGN_OFFSET
    
    ; Ajusta com resto de divisão por MATRIX_RING_SIZE
    cpi r20, MATRIX_RING_SIZE
    brlo mod_20_spin_done
    subi r20, MATRIX_RING_SIZE
mod_20_spin_done:
    pop r25
    pop r24
    pop temp
    ret

; Retorna o atraso de atrito em milissegundos com base nos passos restantes
; Entradas:
;   temp = passos restantes
; Saídas:
;   temp = atraso em ms
get_friction_delay:
    cpi temp, 40
    brsh delay_fast ; restante >= 40: 10ms
    cpi temp, 30
    brsh delay_20 ; restante 30-39: 20ms
    cpi temp, 20
    brsh delay_40 ; restante 20-29: 40ms
    cpi temp, 10
    brsh delay_80 ; restante 10-19: 80ms
    cpi temp, 5
    brsh delay_150 ; restante 5-9: 150ms
    
    ; restante 1-4:
    ldi temp, 250 ; 250ms
    ret
delay_fast:
    ldi temp, 10
    ret
delay_20:
    ldi temp, 20
    ret
delay_40:
    ldi temp, 40
    ret
delay_80:
    ldi temp, 80
    ret
delay_150:
    ldi temp, 150
    ret

; Layout físico do disco da roleta francesa
roulette_wheel_table:
    .db 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23
    .db 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26, 0
