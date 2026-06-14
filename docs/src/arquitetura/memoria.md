# Organização de Memória (SRAM)

A memória SRAM do microcontrolador ATmega328P começa no endereço 0x0100 (SRAM_START). Dividimos esse espaço de forma fixa para armazenar os dados de até 4 jogadores e as variáveis globais que controlam o estado do sistema.

## Estrutura de Dados do Jogador

Cada jogador ocupa um espaço fixo de 16 bytes na memória (PLAYER_SIZE = 16). A divisão interna desses bytes funciona assim:

| Offset | Tamanho | Nome da Constante | Tipo | Descrição |
| :---: | :---: | :--- | :--- | :--- |
| 0x00 | 1 byte | OFS_BAL_H | Byte | Parte alta (MSB) do saldo de créditos. |
| 0x01 | 1 byte | OFS_BAL_L | Byte | Parte baixa (LSB) do saldo de créditos. |
| 0x02 | 1 byte | OFS_STATUS | Byte | Bit 0: Flag de aprisionamento (En Prison). Outros bits: Reservados. |
| 0x03 | 1 byte | OFS_BET_TYPE | Byte | Tipo da aposta: 0 = Interna, 1 = Externa. |
| 0x04 | 1 byte | OFS_BET_TGT | Byte | Alvo da aposta: Número (0-36) ou Categoria externa (0-11). |
| 0x05 | 1 byte | OFS_BET_VAL_H | Byte | Parte alta (MSB) do valor apostado na rodada. |
| 0x06 | 1 byte | OFS_BET_VAL_L | Byte | Parte baixa (LSB) do valor apostado na rodada. |
| 0x07 | 5 bytes | OFS_HIST_START| Vetor | Últimos 5 números sorteados por este jogador. |
| 0x0C | 4 bytes | - | - | Espaço livre reservado para futuras melhorias. |

### Endereços de Início de Cada Jogador:
* Jogador 1: 0x0100 a 0x010F
* Jogador 2: 0x0110 a 0x011F
* Jogador 3: 0x0120 a 0x012F
* Jogador 4: 0x0130 a 0x013F

### Como o código encontra o jogador atual:
A subrotina Player_Get_Pointer lê o número do jogador ativo (armazenado no registrador r21) e faz uma conta simples para achar o endereço base na memória:
Endereço do Jogador = 0x0100 + ((Número do Jogador - 1) * 16)

## Variáveis Globais (a partir do endereço 0x0140)

Os endereços de memória que vêm logo depois do quarto jogador são usados para as variáveis gerais da roleta:

| Endereço SRAM | Nome da Constante | Tamanho | Descrição |
| :---: | :--- | :---: | :--- |
| 0x0140 | RAM_ROUND_NUM | 1 byte | Número sorteado na rodada atual ou passo da animação no display. |
| 0x0141 | RAM_GLOB_HIST | 5 bytes | Histórico geral da mesa (últimos 5 números sorteados). |
| 0x0146 | RAM_SEED_L | 1 byte | Parte baixa da semente do gerador de números aleatórios. |
| 0x0147 | RAM_SEED_H | 1 byte | Parte alta da semente do gerador de números aleatórios. |
| 0x0148 | RAM_SYS_TICKS | 1 byte | Contador de milissegundos para controle de tempo geral. |
| 0x0149 | RAM_BALL_IDX | 1 byte | Posição atual do LED da bolinha na matriz 8x8 (0 a 19). |
| 0x014A | RAM_SCREEN_BUF | 8 bytes | Buffer de tela da matriz de LEDs (1 byte por linha da matriz). |
| 0x0152 | RAM_NUM_PLAYERS| 1 byte | Quantidade de jogadores ativos na partida (1 a 4). |
| 0x0153 | RAM_PWM_COUNTER| 1 byte | Contador de ciclos (0 a 7) para o controle de cor (PWM) do LED RGB. |
| 0x0154 | RAM_PWM_RED | 1 byte | Intensidade (0 a 7) da cor vermelha do LED RGB. |
| 0x0155 | RAM_PWM_GREEN | 1 byte | Intensidade (0 a 7) da cor verde do LED RGB. |
| 0x0156 | RAM_PWM_BLACK | 1 byte | Intensidade (0 a 7) da cor azul do LED RGB (usado para números pretos). |
| 0x0157 | RAM_PWM_TICK | 1 byte | Contador de velocidade para a transição suave de cores (0 a 49). |
| 0x0158 | RAM_FADE_STATE | 1 byte | Estado atual da animação de transição de cores. |
| 0x0159 | RAM_CURRENT_TRACK| 1 byte | Índice da música atual que está tocando no buzzer (0 a 4). |
| 0x015A | RAM_FSM_STATE | 1 byte | Cópia do estado do jogo para sincronização com as interrupções de tempo. |