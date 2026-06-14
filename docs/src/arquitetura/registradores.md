# Gerenciamento de Registradores

Para evitar conflitos de variáveis entre o fluxo principal do jogo e as rotinas de serviço de interrupção (ISRs), adotamos uma regra fixa para o uso dos 32 registradores de uso geral do ATmega328P, garantindo que os dados não sejam sobrescritos por acidente.

## Passagem de Parâmetros e Retorno

### r25:r4. r16(temp) e r17 (temp2)
* Propósito: Transferência de argumentos para as subrotinas e retorno de resultados. Geralmente, utilizou-se temp e temp2 como argumentos quando eles representavam coisas em 8 bits e r25:r24 para informações de 16 bits.
* Exemplo: LCD_Print_Dec16 recebe o valor de 16 bits que está em r25:r24. Player_Get_Balance retorna o saldo em r25:r24.

## Variáveis Globais de Estado (FSM e Controle)

### r20 (fsm_state)
* Propósito: Armazena o estado lógico atual da Máquina de Estados Finita (FSM) do jogo (constantes de STATE_WELCOME a STATE_WELCOME).
* Regra: Só deve ser modificado em trechos de transição de estado da lógica principal do jogo. Drivers e rotinas auxiliares de baixo nível nunca devem alterar seu valor.

### r21 (active_plyr)
* Propósito: Armazena o identificador numérico (1 a 4) do jogador atual.
* Regra: Usado para calcular dinamicamente o offset na memória SRAM onde os dados do jogador são lidos ou gravados.

### r22 (sys_flags)
* Propósito: Flags globais de controle do sistema (como indicação de sub-modo de edição de aposta e controle de confirmação). Mais especificamente:
*   Bit 0: Serve para alternar entre SIM e VOLTAR na tela de confirmação.
*   Bit 6 e 7: Permite escolher o Modo de Edição:
*       Modo 0: Permite o jogador escolher a aposta (índices de 0 a 48) 
*       Modo 1: Permite definir a quantidade de créditos que o jogador deseja apostar.
*       Modo 2: Alterna entre as opções SIM e VOLTAR na tela de confirmação. 
Os demais bit são inúteis.

## Ponteiros de Endereçamento Indireto

### Ponteiro X (r27:r26)
* Propósito: Armazena o endereço inicial do registro do jogador ativo na memória SRAM (pelo Player_Get_Pointer) para manipulação de dados dos jogadores, e é usado temporariamente como ponteiro auxiliar em sub-rotinas gráficas (como Matrix_Draw_Icon).

### Ponteiro Y (r29:r28)
* Propósito: Ponteiro de uso geral e livre para as sub-rotinas do sistema. Serve como rascunho de endereçamento quando os ponteiros X e Z já estão ocupados.

### Ponteiro Z (r31:r30)
* Propósito: Reservado para o acesso a tabelas de dados na memória Flash (como fontes de texto para o LCD, ícones e partituras musicais pela instrução lpm) e também atua como o ponteiro principal de atualização e limpeza do buffer da matriz de LEDs (RAM_SCREEN_BUF) na SRAM.
