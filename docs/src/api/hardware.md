# API: Drivers de Hardware e Periféricos

Lista das subrotinas responsáveis por controlar os componentes e periféricos físicos, localizadas na pasta [src/hardware/](../../../src/hardware/).

---

## 1. Entrada de Teclado ([src/hardware/adc_buttons/](../../../src/hardware/adc_buttons/))

- Read_Buttons
  - Entrada: Nenhuma (faz a leitura física do canal ADC0).
  - Saída: temp (r16) com o código do botão: 0 (nenhum), 1 (Botão A / Próximo), 2 (Botão B / Histórico) ou 3 (Select).
  - Registradores alterados: temp (r16), r24, r25.
  - Descrição: Inicia a conversão analógica pelo ADC, monitora o bit ADSC até que a leitura termine, lê os registradores ADCL e ADCH e compara a leitura de 10 bits com as faixas configuradas para identificar qual botão foi pressionado.

- Wait_Button_Press
  - Entrada: Nenhuma.
  - Saída: temp (r16) com o código do botão que foi pressionado.
  - Registradores alterados: temp (r16), temp2 (r17), r24, r25.
  - Descrição: Fica esperando em loop até que a função Read_Buttons aponte algum botão acionado. Aplica um atraso de 20ms para debounce, espera o botão ser solto, executa mais 20ms de debounce e retorna o código correspondente.

---

## 2. Áudio e Buzzer ([src/hardware/buzzer/](../../../src/hardware/buzzer/))

- Buzzer_Play_Tone
  - Entrada: temp (r16) com o semi-período do tom (para controlar a frequência) e temp2 (r17) com a quantidade de ciclos (duração).
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r18, r19.
  - Descrição: Altera o estado do pino PD4 de acordo com o intervalo definido em temp para produzir o som. Se a frequência passada for zero, gera apenas uma pausa em silêncio pelo tempo indicado.

- Buzzer_Tick
  - Entrada: Nenhuma.
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r18, r19.
  - Descrição: Toca um som curto simulando o barulho mecânico (click) da roleta girando.

- Buzzer_Beep
  - Entrada: Nenhuma.
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r18, r19.
  - Descrição: Emite um bip curto de confirmação.

- Buzzer_Success
  - Entrada: Nenhuma.
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r18, r19.
  - Descrição: Toca uma melodia rápida de sucesso (três notas subindo).

- Buzzer_Failure
  - Entrada: Nenhuma.
  - Saída: Nenhuma.
  - Registradores alterados: temp, temp2, r18, r19.
  - Descrição: Toca um som grave contínuo para indicar erro ou perda.

- Buzzer_Play_Current_Track
  - Entrada: RAM_CURRENT_TRACK (0x0159).
  - Saída: temp (r16) com o código do botão caso a música seja parada antes do fim, ou 0 se tocar até o término.
  - Registradores alterados: temp, temp2, r18, r19, ZL, ZH.
  - Descrição: Lê qual música está configurada e toca suas notas uma a uma a partir da memória Flash. Durante a reprodução, move a luz na matriz de LEDs e fica monitorando o teclado para interromper a música caso o jogador aperte algum botão.

---

## 3. Display LCD I2C ([src/hardware/lcd_i2c/](../../../src/hardware/lcd_i2c/))

- delay_1ms
  - Entrada: Nenhuma.
  - Saída: Nenhuma (atrasa o processamento por cerca de 1ms).
  - Registradores alterados: temp, temp2.
  - Descrição: Função de atraso calibrada por ciclos de máquina para clock de 16 MHz.

- delay_ms
  - Entrada: temp (r16) com a quantidade de milissegundos desejada.
  - Saída: Nenhuma.
  - Registradores alterados: temp (r16).
  - Descrição: Roda a função delay_1ms repetidamente em um loop para gerar atrasos maiores.

- i2c_start / i2c_stop
  - Entrada/Saída: Nenhuma.
  - Descrição: Controla as linhas PC4 e PC5 para gerar os sinais de início (START) e fim (STOP) do protocolo I2C.

- i2c_write_byte
  - Entrada: temp (r16) com o byte a ser transmitido.
  - Saída: Nenhuma.
  - Registradores alterados: temp2 (r17).
  - Descrição: Transmite um byte de forma serial bit a bit (bit-bang) e trata o nono pulso de clock para receber a confirmação (ACK/NACK).

- lcd_write_cmd
  - Entrada: temp (r16) com o comando do LCD.
  - Descrição: Envia um comando para o display LCD controlando a divisão dos dados em partes (nibbles) e o estado do backlight via módulo PCF8574, ou por conexões diretas dependendo do modo ativo.

- lcd_write_data
  - Entrada: temp (r16) com o caractere em código ASCII.
  - Descrição: Envia um caractere para ser escrito e exibido no LCD.

- LCD_Init
  - Entrada: Constante USE_PCF8574_BACKPACK.
  - Descrição: Configura os pinos do I2C em dreno aberto e envia os comandos necessários para ligar e configurar o display.

- LCD_Clear
  - Entrada/Saída: Nenhuma.
  - Descrição: Limpa todo o conteúdo do display (exige um tempo de espera de 2ms).

- LCD_Set_Cursor
  - Entrada: temp (r16) indicando a linha (0 ou 1) e temp2 (r17) a coluna (de 0 a 15).
  - Descrição: Move o cursor de escrita para uma coordenada específica do LCD.

- LCD_Print_Msg
  - Entrada: ZH:ZL com o endereço da mensagem em texto na Flash (multiplicado por 2 e terminada com 0).
  - Descrição: Imprime no display a mensagem apontada pelo ponteiro até encontrar o marcador de fim de string (byte 0x00).

- LCD_Print_Dec16
  - Entrada: r25:r24 com o número de 16 bits sem sinal.
  - Descrição: Converte um número para representação em texto ASCII e o imprime na tela, removendo os zeros à esquerda para ficar mais limpo.

---

## 4. Matriz de LEDs 8x8 ([src/hardware/max7219/](../../../src/hardware/max7219/))

- max7219_write
  - Entrada: temp (r16) com o registrador de controle e temp2 (r17) com o valor a ser gravado.
  - Descrição: Transmite dados de 16 bits para o circuito integrado MAX7219 via protocolo SPI emulador por software nos pinos PC1 a PC3.

- Matrix_Init
  - Descrição: Prepara as portas de saída usadas pelo SPI e configura o chip MAX7219 (ligando o display, definindo brilho, definindo a varredura completa das linhas, etc.).

- Matrix_Refresh
  - Descrição: Transmite as 8 linhas de imagem guardadas na SRAM (buffer RAM_SCREEN_BUF) para atualizar os LEDs reais da matriz física.

- Matrix_Clear
  - Descrição: Limpa o buffer de imagem na SRAM preenchendo-o com zeros e força uma atualização para desligar todos os LEDs.

- Matrix_Render_Frame
  - Entrada: temp (r16) com o padrão do centro (como 0x80 para o desenho de diamante) e temp2 (r17) indicando o local da bola na borda (0 a 19).
  - Descrição: Limpa o buffer de vídeo, desenha a figura do centro, localiza a linha e coluna onde a bola deve ficar na borda (usando a tabela border_table na Flash) e atualiza o display.

- Matrix_Draw_Icon
  - Entrada: ZH:ZL com o local do bitmap de 8 bytes na memória Flash (multiplicado por 2).
  - Descrição: Copia as informações do desenho da Flash para o buffer de vídeo e faz a atualização da matriz de LEDs.

---

## 5. LED RGB ([src/hardware/rgb_led/](../../../src/hardware/rgb_led/))

- RGB_Clear
  - Entrada: Nenhuma.
  - Saída: Nenhuma.
  - Registradores alterados: Nenhum (usa instrução direta cbi).
  - Descrição: Apaga as três cores do LED (vermelho, verde e azul) colocando as respectivas saídas físicas em nível lógico baixo.

- RGB_Set_By_Player
  - Entrada: temp (r16) com o número do jogador ativo (de 1 a 4).
  - Descrição: Liga a cor definida para cada jogador: P1 fica Vermelho, P2 Azul, P3 Verde e P4 Amarelo (mistura de Vermelho com Verde).

- RGB_Set_By_Number
  - Entrada: temp (r16) com o número sorteado (de 0 a 36).
  - Descrição: Ajusta o LED de acordo com a cor do número da roleta olhando a tabela color_table na Flash (Verde para o 0, Vermelho para os números vermelhos e Azul/Preto para os outros).

---

## 6. Display de 7 Segmentos e ISR ([src/hardware/seven_seg/](../../../src/hardware/seven_seg/))

- TIMER0_ISR
  - Entrada: Interrupção do Timer 0 por igualdade na comparação A (ocorre a cada 2ms).
  - Descrição: Controla a alternância rápida (multiplexação) dos displays de dezena e unidade. Quando está na tela inicial ou na escolha de jogadores, gera um efeito de transição suave das cores (fade) no RGB por software e acende segmentos específicos simulando o movimento de giro na tela.
