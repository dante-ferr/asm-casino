; Ponto de entrada principal do programa e vetores de interrupção
.include "config.inc"

; Vetores de Interrupção
.org 0x0000
    rjmp RESET ; Handler de reset
.org OC0Aaddr ; Vetor de comparação A do Timer0
    rjmp TIMER0_ISR ; Handler de comparação A do Timer0
.org 0x0034 ; Fim dos vetores de interrupção

; Inicialização do sistema (RESET)
RESET:
    ; Inicializa o ponteiro de pilha
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Configura as direções das portas de E/S
    ; PORTB: PB0-PB3 (saídas dos segmentos), PB4-PB5 (saídas dos cátodos)
    ldi temp, 0b00111111 ; define PB0-PB5 como saída
    out DDRB, temp
    
    ; PORTD: PD1-PD3 (RGB), PD4 (Buzzer), PD5-PD7 (segmentos)
    ldi temp, 0b11101110 ; PD1-PD3 e PD5-PD7 como saída, PD4 como entrada
    out DDRD, temp

    ; PORTC: PC1-PC3 (saídas da matriz), PC4-PC5 (I2C), PC0 (entrada do ADC)
    ldi temp, 0b00111110 ; PC1-PC3 e PC4-PC5 como saída/entrada, PC0 como entrada
    out DDRC, temp
    
    ; Desliga as saídas dos cátodos no início (cátodo comum)
    sbi PORTB, DISP_DEC
    sbi PORTB, DISP_UNI

    ; Inicializa o LCD e a matriz de LEDs
    rcall LCD_Init
    rcall LCD_Clear
    rcall Matrix_Init

    ; Inicializa os dados dos jogadores na SRAM
    rcall Players_Init

    ; Configura o Timer 0 para interrupções periódicas da multiplexação
    ; Modo CTC (limpa o timer ao comparar)
    ldi temp, (1 << WGM01)
    out TCCR0A, temp
    ; Prescaler de 256
    ldi temp, (1 << CS02)
    out TCCR0B, temp
    ; Valor de comparação para gerar interrupção a cada 2ms
    ldi temp, 124
    out OCR0A, temp
    ; Habilita interrupção de comparação do Timer 0
    ldi temp, (1 << OCIE0A)
    sts TIMSK0, temp

    ; Configura o ADC para o teclado analógico
    ; Tensão de referência AVCC e canal ADC0
    ldi temp, (1 << REFS0)
    sts ADMUX, temp
    ; Habilita o ADC com prescaler 128
    ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, temp

    ; Configura o Timer 1 para gerar entropia no gerador aleatório
    ldi temp, (1 << CS10)
    sts TCCR1B, temp

    ; Inicializa as variáveis de estado
    ldi temp, 4
    sts RAM_NUM_PLAYERS, temp ; inicia com padrão de 4 jogadores
    ldi fsm_state, STATE_WELCOME ; tela de boas-vindas inicial
    sts RAM_FSM_STATE, fsm_state
    ldi active_plyr, 1 ; começa no jogador 1
    ldi sys_flags, 0
    ldi temp, 0
    sts RAM_CURRENT_TRACK, temp ; faixa de música inicial 0

    ; Inicializa variáveis de PWM e efeito fade
    ldi temp, 0
    sts RAM_PWM_COUNTER, temp
    sts RAM_PWM_TICK, temp
    sts RAM_FADE_STATE, temp
    sts RAM_PWM_GREEN, temp
    sts RAM_PWM_BLACK, temp
    ldi temp, 7
    sts RAM_PWM_RED, temp ; inicia o vermelho no máximo
    ldi temp, 0
    sts RAM_ROUND_NUM, temp ; frame inicial da animação

    ; Valores iniciais do display para o jogador 1
    ldi temp, 1
    sts RAM_ROUND_NUM, temp
    ldi temp, 0
    sts RAM_BALL_IDX, temp

    ; Desenha o estado inicial da matriz com a bola no índice 0
    ldi temp, 0x80 ; padrão do losango estático
    ldi temp2, 0 ; posição inicial da bola
    rcall Matrix_Render_Frame
    
    ; Cor inicial do LED RGB correspondente ao jogador 1
    ldi temp, 1
    rcall RGB_Set_By_Player

    ; Habilita as interrupções globais
    sei

; Loop principal
MAIN_LOOP:
    ; Salva o estado atual da FSM na memória SRAM
    sts RAM_FSM_STATE, fsm_state
    
    ; Verifica se está no estado de Menu Principal
    cpi fsm_state, STATE_MAIN_MENU
    brne CHECK_STATE_1
    call Run_Main_Menu
    rjmp MAIN_LOOP

CHECK_STATE_1:
    ; Verifica se está no estado de Escolha da Categoria de Aposta
    cpi fsm_state, STATE_CHOOSE_CAT
    brne CHECK_STATE_2
    call Run_Choose_Cat
    rjmp MAIN_LOOP

CHECK_STATE_2:
    ; Verifica se está no estado de Escolha do Alvo/Valor da Aposta
    cpi fsm_state, STATE_CHOOSE_BET
    brne CHECK_STATE_3
    call Run_Choose_Bet
    rjmp MAIN_LOOP

CHECK_STATE_3:
    ; Verifica se está no estado de Confirmação da Aposta
    cpi fsm_state, STATE_CONFIRM_BET
    brne CHECK_STATE_4
    call Run_Confirm_Bet
    rjmp MAIN_LOOP

CHECK_STATE_4:
    ; Verifica se está no estado de Giro da Roleta
    cpi fsm_state, STATE_SPIN_ROULET
    brne CHECK_STATE_5
    call Run_Spin_Roulette
    rjmp MAIN_LOOP

CHECK_STATE_5:
    ; Verifica se está no estado de Resolução de Resultados
    cpi fsm_state, STATE_RESOLUTION
    brne CHECK_STATE_6
    call Run_Resolution
    rjmp MAIN_LOOP

CHECK_STATE_6:
    ; Verifica se está no estado de Regra "En Prison"
    cpi fsm_state, STATE_EN_PRISON
    brne CHECK_STATE_7
    call Run_En_Prison
    rjmp MAIN_LOOP

CHECK_STATE_7:
    ; Verifica se está no estado de Configuração de Créditos
    cpi fsm_state, STATE_SET_CREDITS
    brne CHECK_STATE_8
    call Run_Set_Credits
    rjmp MAIN_LOOP

CHECK_STATE_8:
    ; Verifica se está no estado de Seleção do Número de Jogadores
    cpi fsm_state, STATE_NUM_PLAYERS
    brne CHECK_STATE_9
    call Run_Num_Players
    rjmp MAIN_LOOP

CHECK_STATE_9:
    ; Verifica se está no estado de Boas-vindas (inicial)
    cpi fsm_state, STATE_WELCOME
    brne MAIN_LOOP
    call Run_Welcome
    rjmp MAIN_LOOP

; Inclusão de drivers e lógica do jogo
.include "hardware/lcd_i2c/main.asm"
.include "hardware/seven_seg/main.asm"
.include "hardware/max7219/main.asm"
.include "hardware/adc_buttons/main.asm"
.include "hardware/buzzer/main.asm"
.include "hardware/rgb_led/main.asm"
.include "game/players/main.asm"
.include "game/prng/main.asm"
.include "game/menu/main.asm"
.include "game/betting/main.asm"
.include "game/resolution/main.asm"

; Tabelas de música no final para evitar estouro de endereços relativos
.include "game/music/ode_to_joy.asm"
.include "game/music/minuet_g.asm"
.include "game/music/tetris.asm"
.include "game/music/star_wars.asm"
.include "game/music/mario.asm"
