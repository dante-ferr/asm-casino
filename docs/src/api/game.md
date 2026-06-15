# API: Subsistemas do Jogo

Documentação das funções que controlam a lógica do jogo, regras e estados do sistema, localizadas no diretório [src/game/](../../../src/game/).

---

## 1. Jogadores e SRAM ([src/game/players/](../../../src/game/players/))

- Players_Init
  - Descrição: Inicializa o saldo dos 4 jogadores na SRAM com 1000 créditos e limpa o status, as apostas e o histórico de cada um.

- Player_Get_Pointer
  - Entrada: active_plyr (r21).
  - Saída: ZH:ZL com o endereço de início do jogador atual na SRAM.
  - Descrição: Retorna o ponteiro para a posição de memória SRAM onde os dados do jogador ativo estão armazenados.

- Player_Get_Balance / Player_Set_Balance
  - Entrada/Saída: r25:r24 (saldo em 16 bits).
  - Descrição: Faz a leitura ou atualiza o saldo de créditos do jogador ativo.

- Player_Get_Status / Player_Set_Status
  - Entrada/Saída: temp (r16) com o byte de status.
  - Descrição: Lê ou atualiza o status do jogador ativo (indicando, por exemplo, se ele está na prisão "En Prison").

- Player_Get_Bet / Player_Set_Bet
  - Entrada/Saída: temp (tipo de aposta), temp2 (alvo da aposta) e r25:r24 (valor da aposta).
  - Descrição: Lê ou atualiza as informações da aposta ativa do jogador.

---

## 2. Gerador Pseudo-Aleatório ([src/game/prng/](../../../src/game/prng/))

- PRNG_Spin
  - Saída: temp2 (r17) com o número sorteado (entre 0 e 36).
  - Descrição: Lê o valor atual do Timer 1 (TCNT1L) e aplica a operação módulo 37 para definir o número sorteado da roleta.

---

## 3. Fase de Apostas ([src/game/betting/](../../../src/game/betting/))

- Run_Choose_Cat
  - Entrada: Nenhuma.
  - Saída: Nenhuma (muda o fsm_state).
  - Registradores alterados: temp, temp2, r24, r25, ZH:ZL.
  - Descrição: Controla a seleção do tipo de aposta (se será interna ou externa) pelo jogador ativo e atualiza o estado da FSM.

- Run_Choose_Bet
  - Entrada: Nenhuma.
  - Saída: Nenhuma (subrotina stub).
  - Descrição: Subrotina stub que apenas retorna (ret). A lógica de escolha do alvo é processada internamente no loop de Run_Choose_Cat.

- Run_Confirm_Bet
  - Entrada: Nenhuma.
  - Saída: Nenhuma (subrotina stub).
  - Descrição: Subrotina stub que apenas retorna (ret). O fluxo de confirmação final é tratado diretamente dentro de Run_Choose_Cat.

- Check_Any_Bets
  - Entrada: Nenhuma (lê os dados direto da SRAM dos jogadores).
  - Saída: temp (r16) com o valor 1 se houver pelo menos uma aposta ativa de algum jogador, ou 0 se ninguém tiver apostado nada.
  - Registradores alterados: temp, temp2, r24, r25, ZH:ZL.
  - Descrição: Varre a memória SRAM de todos os jogadores para checar se alguma aposta foi feita na rodada atual.

- Map_Selection_To_Bet
  - Entrada: temp (r16) com o índice selecionado na tela (de 0 a 42).
  - Saída: temp (tipo de aposta - 0 para interna, 1 para externa) e temp2 (alvo real na roleta).
  - Descrição: Converte a opção escolhida na interface do jogo nos dados lógicos que a roleta precisa para processar as regras.

- Show_Betting_Screen
  - Descrição: Desenha na tela a interface de apostas, mostrando os cursores, limites de aposta e a indicação dos botões.

---

## 4. Menus e Interface ([src/game/menu/](../../../src/game/menu/))

- Run_Welcome
  - Descrição: Cuida da tela de boas-vindas do cassino, tocando a música de fundo e permitindo trocar de faixa.

- Show_Welcome_Screen
  - Entrada: Nenhuma.
  - Saída: Nenhuma (desenha direto no LCD).
  - Registradores alterados: temp, temp2, ZH:ZL.
  - Descrição: Limpa a tela do LCD e exibe a mensagem de introdução da roleta.

- Run_Num_Players
  - Descrição: Gerencia a configuração da quantidade de jogadores da rodada (de 1 a 4).

- Show_Num_Players_Menu
  - Entrada: Nenhuma (faz a leitura de RAM_NUM_PLAYERS).
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r24, r25, ZH:ZL.
  - Descrição: Desenha a tela de escolha de jogadores e carrega o ícone de grupo na matriz de LEDs.

- Run_Main_Menu
  - Descrição: Controla a exibição do menu principal com o saldo de cada participante.

- Show_Player_Menu
  - Entrada: active_plyr.
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r24, r25, ZH:ZL.
  - Descrição: Mostra no LCD o número do jogador ativo, seu saldo atual, a marcação (P) se ele estiver preso, além de exibir o ícone de avatar na matriz de LEDs.

- Run_Set_Credits
  - Descrição: Gerencia a interface para ajustar os créditos iniciais.

- Show_Credits_Menu
  - Entrada: Nenhuma (lê o saldo atual do jogador).
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r24, r25, ZH:ZL.
  - Descrição: Exibe a tela de ajuste de créditos do jogador ativo no LCD e coloca o ícone de cifrão na matriz de LEDs.

---

## 5. Resolução da Rodada ([src/game/resolution/](../../../src/game/resolution/))

- Run_Spin_Roulette
  - Descrição: Dispara a animação física de giro da roleta e depois processa a atualização dos saldos.

- Run_Roulette_Spin_Sequence
  - Saída: temp2 com o número final vencedor (entre 0 e 36).
  - Descrição: Faz a animação da bolinha girando na matriz, atualiza os displays e o LED RGB no tempo certo, aplica a desaceleração pelo atrito e retorna o resultado sorteado.

- Calculate_Payout
  - Descrição: Calcula os prêmios ou perdas de todos os 4 jogadores e aplica a regra de prisão (En Prison) para apostas externas se o resultado for zero.

- Check_Bet_Win
  - Entrada: r20 (número vencedor), temp (tipo de aposta) e temp2 (alvo apostado).
  - Saída: temp com valor 1 para vitória ou 0 para derrota.
  - Descrição: Valida se a aposta do jogador bateu com o número sorteado com base nas regras da roleta.

- map_slot_to_led
  - Entrada: r22 com a posição da roleta (0-36).
  - Saída: r20 com o LED correspondente na borda da matriz (0-19).
  - Descrição: Converte a posição lógica da roleta para acender o LED correto na borda física da matriz.

- get_friction_delay
  - Entrada: temp com os passos restantes da animação.
  - Saída: temp com o tempo de atraso em milissegundos (de 10ms a 250ms).
  - Descrição: Retorna o tempo de espera de cada passo para simular a desaceleração física da roleta.
