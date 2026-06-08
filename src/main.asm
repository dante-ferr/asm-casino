; Ponto de entrada principal do programa e vetores de interrupcao
.include "config.inc"

; Vetores de Interrupcao
.org 0x0000
    rjmp RESET ; Handler de reset
.org OC0Aaddr ; Vetor de comparacao A do Timer0
    rjmp TIMER0_ISR ; Handler de comparacao A do Timer0
.org 0x0034 ; Fim dos vetores de interrupcao

; Inicializacao do sistema (RESET)
RESET:
    ; Inicializa o ponteiro de pilha
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Configura as direcoes das portas de E/S
    ; PORTB: PB0-PB3 (saidas dos segmentos), PB4-PB5 (saidas dos catodos)
    ldi temp, 0b00111111 ; define PB0-PB5 como saida
    out DDRB, temp
    
    ; PORTD: PD1-PD3 (RGB), PD4 (Buzzer), PD5-PD7 (segmentos)
    ldi temp, 0b11101110 ; PD1-PD3 e PD5-PD7 como saida, PD4 como entrada
    out DDRD, temp

    ; PORTC: PC1-PC3 (saidas da matriz), PC4-PC5 (I2C), PC0 (entrada do ADC)
    ldi temp, 0b00111110 ; PC1-PC3 e PC4-PC5 como saida/entrada, PC0 como entrada
    out DDRC, temp
    
    ; Desliga as saidas dos catodos no inicio (catodo comum)
    sbi PORTB, DISP_DEC
    sbi PORTB, DISP_UNI

    ; Inicializa o LCD e a matriz de LEDs
    rcall LCD_Init
    rcall LCD_Clear
    rcall Matrix_Init

    ; Inicializa os dados dos jogadores na SRAM
    rcall Players_Init

    ; Configura o Timer 0 para interrupcoes periodicas da multiplexacao
    ; Modo CTC (limpa o timer ao comparar)
    ldi temp, (1 << WGM01)
    out TCCR0A, temp
    ; Prescaler de 256
    ldi temp, (1 << CS02)
    out TCCR0B, temp
    ; Valor de comparacao para gerar interrupcao a cada 2ms
    ldi temp, 124
    out OCR0A, temp
    ; Habilita interrupcao de comparacao do Timer 0
    ldi temp, (1 << OCIE0A)
    sts TIMSK0, temp

    ; Configura o ADC para o teclado analogico
    ; Tensao de referencia AVCC e canal ADC0
    ldi temp, (1 << REFS0)
    sts ADMUX, temp
    ; Habilita o ADC com prescaler 128
    ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts ADCSRA, temp

    ; Configura o Timer 1 para gerar entropia no gerador aleatorio
    ldi temp, (1 << CS10)
    sts TCCR1B, temp

    ; Inicializa as variaveis de estado
    ldi temp, 4
    sts RAM_NUM_PLAYERS, temp ; inicia com padrao de 4 jogadores
    ldi fsm_state, STATE_WELCOME ; tela de boas-vindas inicial
    sts RAM_FSM_STATE, fsm_state
    ldi active_plyr, 1 ; comeca no jogador 1
    ldi sys_flags, 0
    ldi temp, 0
    sts RAM_CURRENT_TRACK, temp ; faixa de musica inicial 0

    ; Inicializa variaveis de PWM e efeito fade
    ldi temp, 0
    sts RAM_PWM_COUNTER, temp
    sts RAM_PWM_TICK, temp
    sts RAM_FADE_STATE, temp
    sts RAM_PWM_GREEN, temp
    sts RAM_PWM_BLACK, temp
    ldi temp, 7
    sts RAM_PWM_RED, temp ; inicia o vermelho no maximo
    ldi temp, 0
    sts RAM_ROUND_NUM, temp ; frame inicial da animacao

    ; Valores iniciais do display para o jogador 1
    ldi temp, 1
    sts RAM_ROUND_NUM, temp
    ldi temp, 0
    sts RAM_BALL_IDX, temp

    ; Desenha o estado inicial da matriz com a bola no indice 0
    ldi temp, 0x80 ; padrao do losango estatico
    ldi temp2, 0 ; posicao inicial da bola
    rcall Matrix_Render_Frame
    
    ; Cor inicial do LED RGB correspondente ao jogador 1
    ldi temp, 1
    rcall RGB_Set_By_Player

    ; Habilita as interrupcoes globais
    sei

; Loop principal
MAIN_LOOP:
    sts RAM_FSM_STATE, fsm_state
    cpi fsm_state, STATE_MAIN_MENU
    brne CHECK_STATE_1
    call Run_Main_Menu
    rjmp MAIN_LOOP

CHECK_STATE_1:
    cpi fsm_state, STATE_CHOOSE_CAT
    brne CHECK_STATE_2
    call Run_Choose_Cat
    rjmp MAIN_LOOP

CHECK_STATE_2:
    cpi fsm_state, STATE_CHOOSE_BET
    brne CHECK_STATE_3
    call Run_Choose_Bet
    rjmp MAIN_LOOP

CHECK_STATE_3:
    cpi fsm_state, STATE_CONFIRM_BET
    brne CHECK_STATE_4
    call Run_Confirm_Bet
    rjmp MAIN_LOOP

CHECK_STATE_4:
    cpi fsm_state, STATE_SPIN_ROULET
    brne CHECK_STATE_5
    call Run_Spin_Roulette
    rjmp MAIN_LOOP

CHECK_STATE_5:
    cpi fsm_state, STATE_RESOLUTION
    brne CHECK_STATE_6
    call Run_Resolution
    rjmp MAIN_LOOP

CHECK_STATE_6:
    cpi fsm_state, STATE_EN_PRISON
    brne CHECK_STATE_7
    call Run_En_Prison
    rjmp MAIN_LOOP

CHECK_STATE_7:
    cpi fsm_state, STATE_SET_CREDITS
    brne CHECK_STATE_8
    call Run_Set_Credits
    rjmp MAIN_LOOP

CHECK_STATE_8:
    cpi fsm_state, STATE_NUM_PLAYERS
    brne CHECK_STATE_9
    call Run_Num_Players
    rjmp MAIN_LOOP

CHECK_STATE_9:
    cpi fsm_state, STATE_WELCOME
    brne MAIN_LOOP
    call Run_Welcome
    rjmp MAIN_LOOP

; Inclusao de drivers e logica do jogo
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

; Tabelas de musica no final para evitar estouro de enderecos relativos
.include "game/music/ode_to_joy.asm"
.include "game/music/minuet_g.asm"
.include "game/music/tetris.asm"
.include "game/music/star_wars.asm"
.include "game/music/mario.asm"
