# Gerenciamento de Registradores

Para evitar conflitos de variáveis entre o fluxo principal do jogo e as rotinas de serviço de interrupção (ISRs), adotamos uma regra fixa para o uso dos 32 registradores de uso geral do ATmega328P, garantindo que os dados não sejam sobrescritos por acidente.

## Registradores Temporários

### r16 (temp) e r17 (temp2)
* Propósito: Armazenamento local de curto prazo, operações lógicas e aritméticas com valores imediatos (ldi, andi, ori), e controle de contadores de loops locais.
* Regra: Qualquer subrotina pode alterar livremente temp e temp2 sem precisar preservar seus estados na pilha. Portanto, seus valores não são garantidos após a chamada de um call ou rcall.

## Passagem de Parâmetros e Retorno

### r24 (argument) e r25 (argument_h)
* Propósito: Transferência de argumentos para as subrotinas e retorno de resultados.
  * Para dados de 8 bits, utilizamos o r24.
  * Para dados de 16 bits, utilizamos o par r25:r24 (onde r25 tem o byte mais significativo - MSB, e r24 o menos significativo - LSB).
* Exemplo: LCD_Print_Dec16 recebe o valor de 16 bits que está em r25:r24. Player_Get_Balance retorna o saldo em r25:r24.

## Variáveis Globais de Estado (FSM e Controle)

### r20 (fsm_state)
* Propósito: Armazena o estado lógico atual da Máquina de Estados Finita (FSM) do jogo (constantes de STATE_WELCOME a STATE_WELCOME).
* Regra: Só deve ser modificado em trechos de transição de estado da lógica principal do jogo. Drivers e rotinas auxiliares de baixo nível nunca devem alterar seu valor.

### r21 (active_plyr)
* Propósito: Armazena o identificador numérico (1 a 4) do jogador atual.
* Regra: Usado para calcular dinamicamente o offset na memória SRAM onde os dados do jogador são lidos ou gravados.

### r22 (sys_flags)
* Propósito: Flags globais de controle do sistema (como indicação de sub-modo de edição de aposta e controle de confirmação).

## Ponteiros de Endereçamento Indireto

### Ponteiro X (r27:r26)
* Propósito: Armazena o endereço inicial do registro do jogador ativo na memória SRAM (pelo Player_Get_Pointer) para manipulação de dados dos jogadores, e é usado temporariamente como ponteiro auxiliar em sub-rotinas gráficas (como Matrix_Draw_Icon).

### Ponteiro Y (r29:r28)
* Propósito: Ponteiro de uso geral e livre para as sub-rotinas do sistema. Serve como rascunho de endereçamento quando os ponteiros X e Z já estão ocupados.

### Ponteiro Z (r31:r30)
* Propósito: Reservado para o acesso a tabelas de dados na memória Flash (como fontes de texto para o LCD, ícones e partituras musicais pela instrução lpm) e também atua como o ponteiro principal de atualização e limpeza do buffer da matriz de LEDs (RAM_SCREEN_BUF) na SRAM.