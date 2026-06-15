# Manipulação dos Jogadores e Dados
Os dados dos jogadores da roleta francesa são manipulados e alterados para garantir o fluxo do jogo e que a lógica dos saldos, apostas, perdas e vitórias seja preservada.

---
### `src`
A fase de inicialização chama a subrotina `Players_Init` em [main.asm](../../../src/main.asm) para inicializar a tabela de jogadores. A tabela da informações dos jogadores está na memória SRAM, em que o endereço inicial `PLAYER_DATA_START` é definido em [config.inc](../../../src/config.inc) como `PLAYER_DATA_START = SRAM_START`, palavra-chave da arquitetura do ATmega328P que aponta para o endereço base da SRAM, o qual é definido em [m328Pdef.inc](../../../src/m328Pdef.inc) como `SRAM_START = 0x0100`. 

A tabela de jogadores é estabelecida com 64 endereços, mapeada com 16 endereços para cada jogador, em que, considerando um registrador `Z` com `ldi ZL, low(PLAYER_DATA_START)` & `ldi ZH, high(PLAYER_DATA_START)`, `Z` indica a parte alta do saldo, `Z+1` indica a parte baixa do saldo, `Z+2` indica o status, `Z+3` indica o tipo de aposta, `Z+4` indica o alvo da aposta, `Z+5` indica a parte alta do valor da aposta, `Z+6` indica a parte baixa do valor da aposta, enquanto os outros endereços permanecem conservados e não utilizados. 

Aqui também é definido `START_BALANCE` como `START_BALANCE = 1000` e `active_plyr` como `active_plyr = 1` que é utilizado em [players](../../../src/game/players).

---
### `src/game/players`
`Players_Init` reinicializa a tabela de jogadores com uma nova sessão, predefinindo o saldo inicial com 1000 e zerando os demais valores nos endereços da tabela

`Player_Get_Pointer` é uma subrotina que será chamada em outra subrotinas para encontrar o jogador atual alvo de ditas subrotinas. `active_plyr` informa qual é o jogador atual e é utilizado para calcular o endereço base da secção desse jogador, transformando a numeração do jogador em um ponteiro para essa secção. Caso `active_plyr` informar o primeiro jogador, chama-se o endereço base da tabela `PLAYER_DATA_START`, caso não, entra na lógica de ponteiros a partir do endereço base e `active_plyr` para retornar a secção do jogador correto.

`Player_Get_Balance` encontra o saldo jogador selecionado e vincula a parte alta a `r25` e a parte baixa a `r24`.

`Player_Set_Balance` sobreescreve o saldo do jogador selecionado.

`Player_Get_Status` encontra o estado do jogador, se o jogador está na prisão ou não, e vincula a `temp`.

`Player_Set_Status` sobreescreve o respectivo estado do jogador.

`Player_Get_Bet` encontra as informações da aposta do jogador, são elas: tipo de aposta (Externa ou Interna), alvo da aposta (número 0-36 ou categoria 0-5), parte baixa e a parte alta do valor das apostas. Elas são vinculadas a `temp`, `temp2`, `r24` e `r25` respectivamente.

`Player_Set_Bet` sobreescreve as informações da aposta.

`Init_Players_Bets_For_Round` reconfigura as informações da aposta para um estado inicial zerado antes de iniciar a fase de apostas, reiniciando tipo de aposta, alvo da aposta, parte baixa e a parte alta do valor das apostas. Caso um jogador esteja na prisão (`Z+2 = 0`), ignora a reinicialização, ou seja, a aposta é mantida. Esse subrotina entra em loop para os 4 jogadores.