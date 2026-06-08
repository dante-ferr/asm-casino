; Configuracoes globais e definicoes de pinos
.include "m328Pdef.inc"

; Definicoes Globais de Registradores
.def temp        = r16 ; Registrador temporario geral 1
.def temp2       = r17 ; Registrador temporario geral 2
.def argument    = r24 ; Passagem de argumento (LSB)
.def argument_h  = r25 ; Passagem de argumento (MSB)

.def fsm_state   = r20 ; Estado atual da FSM
.def active_plyr = r21 ; ID do jogador ativo (1 a 4)
.def sys_flags   = r22 ; Flags gerais do sistema

; Mapeamento de Pinos de Hardware

; PORTB - Display de 7 segmentos e controle de multiplexacao
; PB0: Segmento D
; PB1: Segmento E
; PB2: Segmento F
; PB3: Segmento G
; PB4: Catodo da dezena (Ativo em Baixo)
; PB5: Catodo da unidade (Ativo em Baixo)
.equ SEG_D       = 0
.equ SEG_E       = 1
.equ SEG_F       = 2
.equ SEG_G       = 3
.equ DISP_DEC    = 4 ; Catodo da dezena
.equ DISP_UNI    = 5 ; Catodo da unidade

; PORTD - Segmentos do display, buzzer e LED RGB
; PD1: LED RGB Canal Verde
; PD2: LED RGB Canal Vermelho
; PD3: LED RGB Canal Azul/Preto
; PD4: Buzzer
; PD5: Segmento A
; PD6: Segmento B
; PD7: Segmento C
.equ RGB_GREEN   = 1
.equ RGB_RED     = 2
.equ RGB_BLACK   = 3 ; Canal azul do LED RGB
.equ BUZZER_PIN  = 4
.equ SEG_A       = 5
.equ SEG_B       = 6
.equ SEG_C       = 7

; PORTC - Teclado (ADC) e SPI/I2C por software
; PC0: Entrada ADC para o teclado
; PC1: Matriz de LEDs DIN (SPI por software)
; PC2: Matriz de LEDs SCK (SPI por software)
; PC3: Matriz de LEDs CS (SPI por software)
; PC4: LCD SDA (I2C por software)
; PC5: LCD SCL (I2C por software)
.equ KEYBOARD_PIN = 0 ; Entrada ADC0
.equ MATRIX_DIN   = 1
.equ MATRIX_SCK   = 2
.equ MATRIX_CS    = 3
.equ LCD_SDA      = 4
.equ LCD_SCL      = 5

; Enderecos SRAM e offsets para os dados dos jogadores
.equ PLAYER_DATA_START = SRAM_START
.equ PLAYER_SIZE   = 16

.equ OFS_BAL_H     = 0 ; Saldo (Byte Alto)
.equ OFS_BAL_L     = 1 ; Saldo (Byte Baixo)
.equ OFS_STATUS    = 2 ; Byte de status (Bit 0: En Prison)
.equ OFS_BET_TYPE  = 3 ; Tipo de aposta
.equ OFS_BET_TGT   = 4 ; Alvo da aposta
.equ OFS_BET_VAL_H = 5 ; Valor da aposta (Byte Alto)
.equ OFS_BET_VAL_L = 6 ; Valor da aposta (Byte Baixo)
.equ OFS_HIST_START= 7 ; Historico local (5 bytes: offsets 7 a 11)

; Variaveis Globais na SRAM
.equ RAM_ROUND_NUM = 0x0140 ; Numero sorteado
.equ RAM_SEED_L    = 0x0146 ; Seed do PRNG (LSB)
.equ RAM_SEED_H    = 0x0147 ; Seed do PRNG (MSB)
.equ RAM_SYS_TICKS = 0x0148 ; Contador de milissegundos (1 byte)
.equ RAM_BALL_IDX  = 0x0149 ; Indice da posicao da bola na matriz (1 byte)
.equ RAM_SCREEN_BUF = 0x014A ; Buffer da matriz de LEDs (8 bytes)
.equ RAM_NUM_PLAYERS = 0x0152 ; Numero de jogadores ativos (1 byte)
.equ RAM_PWM_COUNTER = 0x0153 ; Contador do PWM por software (1 byte)
.equ RAM_PWM_RED     = 0x0154 ; Ciclo de trabalho do Vermelho (0 a 7)
.equ RAM_PWM_GREEN   = 0x0155 ; Ciclo de trabalho do Verde (0 a 7)
.equ RAM_PWM_BLACK   = 0x0156 ; Ciclo de trabalho do Azul (0 a 7)
.equ RAM_PWM_TICK    = 0x0157 ; Contador de ticks de fade (1 byte)
.equ RAM_FADE_STATE  = 0x0158 ; Estado do fade (0, 1, 2)
.equ RAM_CURRENT_TRACK = 0x0159 ; ID da faixa de musica ativa (1 byte)
.equ RAM_FSM_STATE     = 0x015A ; Estado ativo da FSM (1 byte)

; Constantes de Estado da FSM
.equ STATE_MAIN_MENU    = 0
.equ STATE_CHOOSE_CAT   = 1
.equ STATE_CHOOSE_BET   = 2
.equ STATE_CONFIRM_BET  = 3
.equ STATE_SPIN_ROULET  = 4
.equ STATE_RESOLUTION   = 5
.equ STATE_EN_PRISON    = 6
.equ STATE_SET_CREDITS  = 7
.equ STATE_NUM_PLAYERS  = 8
.equ STATE_WELCOME      = 9

; --- CONFIGURACOES DE ARQUITETURA DO JOGO ---
; Limites de jogadores
.equ START_BALANCE             = 1000 ; Saldo inicial dos jogadores
.equ MIN_PLAYERS               = 1
.equ MAX_PLAYERS               = 4

; Configuracoes de ajuste de saldo
.equ CREDIT_STEP               = 100 ; Passo de ajuste de creditos
.equ CREDIT_MAX_LIMIT          = 9900 ; Limite maximo de creditos
.equ CREDIT_MIN_LIMIT          = 0 ; Limite minimo de creditos

; Limites de apostas
.equ BET_STEP                  = 100 ; Passo de ajuste de aposta
.equ NUM_BET_TARGETS           = 49 ; Opcoes totais de alvos (0-48)
.equ FIRST_INTERNAL_IDX        = 12 ; Indice inicial para apostas internas

; Multiplicadores de pagamento
.equ MULTIPLIER_INTERNAL_PAYOUT = 35 ; Multiplicador de aposta interna
.equ MULTIPLIER_INTERNAL_TOTAL  = 36 ; Pagamento total incluindo valor apostado

; Configuracoes de giro da roleta
.equ ROULETTE_SLOTS            = 37 ; Posicoes da roleta francesa (0 a 36)
.equ MATRIX_RING_SIZE          = 20 ; LEDs da borda da matriz 8x8
.equ ROULETTE_ALIGN_OFFSET     = 2 ; Alinhamento do zero da roleta com a matriz
.equ SPIN_MIN_LOOPS            = 2 ; Numero minimo de voltas na animacao
.equ SPIN_BASE_STEPS           = (SPIN_MIN_LOOPS * ROULETTE_SLOTS)
.equ RESULT_DELAY_COUNT        = 14 ; Tempo de exibicao do resultado (5 segundos)

; Cores Logicas
.equ COLOR_GREEN               = 0
.equ COLOR_RED                 = 1
.equ COLOR_BLACK               = 2

; Limiares analogicos dos botoes
.equ BTN_THRES_NONE            = 860
.equ BTN_THRES_SELECT          = 610
.equ BTN_THRES_B               = 350

; Selecao do ambiente de hardware
; Define SimulIDE (display ST7032) como 0
; Define hardware real (display PCF8574) como 1
.equ USE_PCF8574_BACKPACK = 0

.if USE_PCF8574_BACKPACK == 1
.equ LCD_I2C_ADDR              = 0x4E ; Endereco do PCF8574 (0x27 deslocado para esquerda = 0x4E)
.else
.equ LCD_I2C_ADDR              = 0x7C ; Endereco nativo do LCD no SimulIDE
.endif
.equ LCD_CTRL_CMD              = 0x80
.equ LCD_CTRL_DATA             = 0x40
.equ LCD_CMD_CLEAR             = 0x01
.equ LCD_CMD_FUNC              = 0x38
.equ LCD_CMD_ON                = 0x0C
.equ LCD_CMD_ENTRY             = 0x06

; Comandos e parametros do MAX7219
.equ MAX7219_SHUTDOWN          = 0x0C
.equ MAX7219_TEST              = 0x0F
.equ MAX7219_DECODE            = 0x09
.equ MAX7219_SCAN_LIMIT        = 0x0B
.equ MAX7219_INTENSITY         = 0x0A
.equ MAX7219_BRIGHTNESS        = 0x03

; Configuracoes de som do Buzzer
.equ TONE_TICK_PITCH           = 50
.equ TONE_TICK_LEN             = 10
.equ TONE_BEEP_PITCH           = 100
.equ TONE_BEEP_LEN             = 80

