# Referência Completa de Subrotinas (API)

Este documento atua como um catálogo técnico e dicionário de subrotinas para todo o projeto da Roleta Francesa, detalhando os parâmetros de entrada, registradores de saída, registradores modificados (clobbered) e a descrição funcional de cada rotina.

---

## 1. Módulo Principal (`src/main.asm`)

- **`RESET`**
  - **Entrada:** Nenhuma (Acionado por Hardware/Reset).
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `r16` (`temp`), `r17` (`temp2`).
  - **Descrição:** Inicializa o Stack Pointer (`SPL`, `SPH`), configura a direção dos pinos de E/S (`DDRB`, `DDRD`, `DDRC`), inicia o LCD e a Matriz de LEDs, zera os dados dos jogadores na SRAM, configura o Timer 0 para interrupção periódica (multiplexação a cada 2ms), habilita o ADC para leitura dos botões, inicializa o Timer 1 para PRNG, define variáveis globais e habilita interrupções globais (`sei`).
- **`MAIN_LOOP`**
  - **Entrada:** `fsm_state` (`r20`).
  - **Saída:** Nenhuma (Loop infinito).
  - **Registradores Modificados:** Varia conforme o estado acionado.
  - **Descrição:** Compara `fsm_state` contra as constantes de estados e desvia para o tratador correspondente (`Run_Welcome`, `Run_Main_Menu`, `Run_Choose_Cat`, `Run_Confirm_Bet`, `Run_Spin_Roulette`, `Run_Resolution`, `Run_Num_Players`, `Run_Set_Credits`, etc.).

---

## 2. Módulo de Entrada de Teclado (`src/hardware/adc_buttons/`)

- **`Read_Buttons`**
  - **Entrada:** Nenhuma (Dispara leitura física do canal ADC0).
  - **Saída:** `temp` (`r16`) = Código do botão: `0` (Nenhum), `1` (Botão A / Próximo), `2` (Botão B / Histórico), `3` (Select).
  - **Registradores Modificados:** `temp` (`r16`), `r24`, `r25`.
  - **Descrição:** Inicia a conversão analógica no ADC, faz polling no bit `ADSC` até a conclusão, lê os registradores `ADCL` e `ADCH` e compara o resultado de 10 bits contra os limiares configurados para decidir qual botão foi acionado.
- **`Wait_Button_Press`**
  - **Entrada:** Nenhuma.
  - **Saída:** `temp` (`r16`) = Código do botão pressionado.
  - **Registradores Modificados:** `temp` (`r16`), `temp2` (`r17`), `r24`, `r25`.
  - **Descrição:** Aguarda em loop até que `Read_Buttons` retorne um valor diferente de `0`, executa 20ms de debounce, aguarda o botão ser solto, executa mais 20ms de debounce e retorna o código.

---

## 3. Módulo de Áudio e Buzzer (`src/hardware/buzzer/`)

- **`Buzzer_Play_Tone`**
  - **Entrada:** `temp` (`r16`) = Semi-período do tom (determina frequência/pitch), `temp2` (`r17`) = Quantidade de ciclos (duração).
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`.
  - **Descrição:** Comuta o estado lógico da porta `PD4` a intervalos definidos por `temp` para gerar tom. Se a frequência for 0, gera uma pausa silenciosa de mesma duração.
- **`Buzzer_Tick`**
  - **Entrada:** Nenhuma.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`.
  - **Descrição:** Atalho para reproduzir um ruído rápido de clique mecânico da roleta.
- **`Buzzer_Beep`**
  - **Entrada:** Nenhuma.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`.
  - **Descrição:** Reproduz um bipe padrão de confirmação.
- **`Buzzer_Success`**
  - **Entrada:** Nenhuma.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`.
  - **Descrição:** Executa melodia rápida de sucesso (3 notas ascendentes).
- **`Buzzer_Failure`**
  - **Entrada:** Nenhuma.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`.
  - **Descrição:** Executa melodia de erro/derrota (tom grave contínuo).
- **`Buzzer_Play_Current_Track`**
  - **Entrada:** `RAM_CURRENT_TRACK` (`0x0159`).
  - **Saída:** `temp` (`r16`) = Código do botão se interrompido, `0` se concluído.
  - **Registradores Modificados:** `temp`, `temp2`, `r18`, `r19`, `ZL`, `ZH`.
  - **Descrição:** Decodifica a faixa musical selecionada e toca suas notas uma a uma a partir da Flash. Atualiza a posição da bolinha na matriz de LEDs. Lê o teclado constantemente para permitir interrupção imediata da música.

---

## 4. Módulo de Display LCD I2C (`src/hardware/lcd_i2c/`)

- **`delay_1ms`**
  - **Entrada:** Nenhuma.
  - **Saída:** Nenhuma (Atrasa a CPU em exatamente 1,0011 ms).
  - **Registradores Modificados:** `temp`, `temp2`.
  - **Descrição:** Rotina de atraso de calibração baseada em contagem de ciclos para 16 MHz.
- **`delay_ms`**
  - **Entrada:** `temp` (`r16`) = Quantidade de milissegundos.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`.
  - **Descrição:** Executa `delay_1ms` em loop para atrasar múltiplos milissegundos.
- **`i2c_start` / `i2c_stop`**
  - **Entrada/Saída:** Nenhuma.
  - **Descrição:** Gera sinais elétricos de START e STOP nas portas do barramento I2C (`PC4` e `PC5`).
- **`i2c_write_byte`**
  - **Entrada:** `temp` (`r16`) = Byte a transmitir.
  - **Saída:** Nenhuma.
  - **Registradores Modificados:** `temp`, `temp2`.
  - **Descrição:** Envia o byte serialmente via Bit-Bang e processa o 9º clock para consumir o ACK/NACK.
- **`lcd_write_cmd`**
  - **Entrada:** `temp` (`r16`) = Comando do LCD.
  - **Descrição:** Escreve um byte de comando no display LCD, aplicando controle de nibbles e backlight no modo PCF8574, ou flags de controle no modo nativo.
- **`lcd_write_data`**
  - **Entrada:** `temp` (`r16`) = Caractere ASCII.
  - **Descrição:** Escreve um caractere ou dado visual para ser desenhado nas células do display.
- **`LCD_Init`**
  - **Entrada:** Constante `USE_PCF8574_BACKPACK`.
  - **Descrição:** Configura pinos open-drain do I2C e envia comandos sequenciais de barramento e modo de visualização.
- **`LCD_Clear`**
  - **Entrada/Saída:** Nenhuma.
  - **Descrição:** Limpa a tela de exibição do LCD (atraso de 2ms).
- **`LCD_Set_Cursor`**
  - **Entrada:** `temp` (`r16`) = Linha (`0` ou `1`), `temp2` (`r17`) = Coluna (`0` a `15`).
  - **Descrição:** Reposiciona o cursor de exibição do LCD.
- **`LCD_Print_Msg`**
  - **Entrada:** `ZH:ZL` = Ponteiro para string terminada em nulo na Flash (multiplicado por 2).
  - **Descrição:** Imprime a string apontada até encontrar o caractere nulo `0x00`.
- **`LCD_Print_Dec16`**
  - **Entrada:** `r25:r24` = Valor de 16 bits sem sinal.
  - **Descrição:** Converte o número para caracteres ASCII e imprime no LCD, suprimindo zeros redundantes à esquerda.

---

## 5. Módulo de Matriz de LEDs 8x8 (`src/hardware/max7219/`)

- **`max7219_write`**
  - **Entrada:** `temp` (`r16`) = Registrador de comando, `temp2` (`r17`) = Byte de dado.
  - **Descrição:** Envia pacote de 16 bits para o driver MAX7219 via SPI por Bit-Banging nos pinos `PC1-PC3`.
- **`Matrix_Init`**
  - **Descrição:** Configura portas de dados SPI e envia comandos de inicialização (shutdown off, scan all, brightness, etc.).
- **`Matrix_Refresh`**
  - **Descrição:** Transmite sequencialmente as 8 linhas de imagem do buffer na SRAM (`RAM_SCREEN_BUF`) para atualizar os LEDs físicos.
- **`Matrix_Clear`**
  - **Descrição:** Preenche o framebuffer na SRAM com zeros e força atualização para desligar todos os LEDs.
- **`Matrix_Render_Frame`**
  - **Entrada:** `temp` (`r16`) = Padrão do centro (`0x80` para diamante), `temp2` (`r17`) = Posição circular da bolinha (`0-19`).
  - **Descrição:** Limpa o framebuffer, desenha o diamante no centro, calcula a linha e coluna da bolinha usando a tabela `border_table` da Flash e atualiza a matriz.
- **`Matrix_Draw_Icon`**
  - **Entrada:** `ZH:ZL` = Endereço do bitmap de 8 bytes na Flash (multiplicado por 2).
  - **Descrição:** Copia os 8 bytes da Flash para `RAM_SCREEN_BUF` e atualiza a matriz.

---

## 6. Módulo de LED RGB (`src/hardware/rgb_led/`)

- **`RGB_Clear`**
  - **Descrição:** Coloca pinos `PD1-PD3` em nível baixo (desliga todas as cores).
- **`RGB_Set_By_Player`**
  - **Entrada:** `temp` (`r16`) = ID do jogador ativo (`1` a `4`).
  - **Descrição:** Atribui cores exclusivas: P1 (Vermelho), P2 (Azul), P3 (Verde), P4 (Amarelo / Vermelho+Verde).
- **`RGB_Set_By_Number`**
  - **Entrada:** `temp` (`r16`) = Número sorteado da roleta (`0` a `36`).
  - **Descrição:** Define cor do LED de acordo com a casa sorteada consultando a tabela `color_table` na Flash (Verde para 0, Vermelho para ímpares/pares vermelhos, Azul para pretos).

---

## 7. Módulo de Display de 7 Segmentos e ISR (`src/hardware/seven_seg/`)

- **`TIMER0_ISR`**
  - **Entrada:** Interrupção do Timer 0 Compare Match A (a cada 2.0 ms).
  - **Descrição:** Realiza a multiplexação dos displays de dezenas e unidades. Caso esteja nos estados de boas-vindas ou seleção de jogadores, executa rotina de Soft-PWM para transição suave de cores do RGB (Fade) e aciona segmentos alternados simulando um giro de roda.

---

## 8. Módulo de Jogadores e SRAM (`src/game/players/`)

- **`Players_Init`**
  - **Descrição:** Inicializa os balanços dos 4 jogadores na SRAM para 1000 e limpa os campos de status, apostas e histórico.
- **`Player_Get_Pointer`**
  - **Entrada:** `active_plyr` (`r21`).
  - **Saída:** `ZH:ZL` = Endereço de início do jogador atual na SRAM.
  - **Descrição:** Retorna a referência física do registro do jogador ativo.
- **`Player_Get_Balance` / `Player_Set_Balance`**
  - **Entrada/Saída:** `r25:r24` = Balanço de 16 bits.
  - **Descrição:** Lê ou atualiza o saldo de créditos do jogador ativo.
- **`Player_Get_Status` / `Player_Set_Status`**
  - **Entrada/Saída:** `temp` (`r16`) = Byte de status.
  - **Descrição:** Lê ou atualiza o byte de status (En Prison, etc.) do jogador ativo.
- **`Player_Get_Bet` / `Player_Set_Bet`**
  - **Entrada/Saída:** `temp` = Tipo de aposta, `temp2` = Alvo, `r25:r24` = Valor da aposta.
  - **Descrição:** Lê ou atualiza a estrutura de aposta ativa do jogador.

---

## 9. Módulo PRNG (`src/game/prng/`)

- **`PRNG_Spin`**
  - **Saída:** `temp2` (`r17`) = Número sorteado (0 a 36).
  - **Descrição:** Lê o registrador do Timer 1 (`TCNT1L`) e reduz o valor bruto para modulo 37.

---

## 10. Módulo de Apostas (`src/game/betting/`)

- **`Run_Choose_Cat`**
  - **Descrição:** Gerencia o ciclo de criação e ajuste da aposta do jogador ativo.
- **`Map_Selection_To_Bet`**
  - **Entrada:** `temp` (`r16`) = Índice da lista de seleção (0-42).
  - **Saída:** `temp` = Tipo (0: Int, 1: Ext), `temp2` = Alvo real.
  - **Descrição:** Mapeia a seleção visual para os dados reais exigidos pelas regras.
- **`Show_Betting_Screen`**
  - **Descrição:** Desenha o layout do menu de apostas com seus cursores e labels informativas de limite e botões.

---

## 11. Módulo de Menu e Boas-Vindas (`src/game/menu/`)

- **`Run_Welcome`**
  - **Descrição:** Controla a animação de introdução do cassino e a alteração das faixas musicais de background.
- **`Run_Num_Players`**
  - **Descrição:** Controla o menu de configuração inicial de número de participantes ($1$ a $4$).
- **`Run_Main_Menu`**
  - **Descrição:** Controla a tela principal com informações de saldo dos jogadores.
- **`Run_Set_Credits`**
  - **Descrição:** Executa a interface de alteração e setup de saldo inicial.

---

## 12. Módulo de Resolução de Rodada (`src/game/resolution/`)

- **`Run_Spin_Roulette`**
  - **Descrição:** Invoca o giro mecânico e chama a resolução do saldo.
- **`Run_Roulette_Spin_Sequence`**
  - **Saída:** `temp2` = Número final vencedor (0 a 36).
  - **Descrição:** Realiza a animação de giro da bolinha, atualiza os displays e RGB síncronamente, aplica o decay de atrito e retorna o resultado.
- **`Calculate_Payout`**
  - **Descrição:** Analisa os ganhos ou perdas dos 4 jogadores e processa o aprisionamento ("En Prison") das apostas externas no zero.
- **`Check_Bet_Win`**
  - **Entrada:** `r20` = Número vencedor, `temp` = Tipo de aposta, `temp2` = Alvo apostado.
  - **Saída:** `temp` = `1` (Vitória), `0` (Derrota).
  - **Descrição:** Executa a validação lógica das condições de aposta da roleta.
- **`map_slot_to_led`**
  - **Entrada:** `r22` = Slot físico (0-36).
  - **Saída:** `r20` = LED correspondente na borda (0-19).
  - **Descrição:** Mapeia matematicamente a posição real da roleta para a matriz de LEDs.
- **`get_friction_delay`**
  - **Entrada:** `temp` = Passos restantes de animação.
  - **Saída:** `temp` = Milissegundos de delay (10ms a 250ms).
  - **Descrição:** Define o perfil de desaceleração mecânica simulada.
