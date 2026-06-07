# Referência dos Drivers de Hardware e Periféricos

Este documento detalha o funcionamento, as rotinas de interface e as especificações de temporização de cada módulo de hardware implementado no projeto do Cassino ASM.

---

## 1. Teclado Analógico com Escada de Resistores (`adc_buttons`)

Para otimizar o uso de portas do microcontrolador, três botões físicos são conectados a um único pino analógico (`A0 / PC0`) utilizando uma escada de resistores (divisor de tensão). A leitura é feita pelo Conversor Analógico-Digital (ADC) integrado de 10 bits.

### Especificação de Tensões e Limiares (VCC = 5V, ADC: 0 a 1023)
* **Nenhum Botão Pressionado:** Pino A0 conectado ao VCC via pull-up externo de $10\text{ k}\Omega$.
  - Tensão teórica: $5.0\text{V} \implies ADC \approx 1023$
  - Constante de limiar: `BTN_THRES_NONE` = 900
* **Botão A (Próximo / Cima):** Conecta o pino A0 diretamente ao GND.
  - Tensão teórica: $0.0\text{V} \implies ADC \approx 0$
  - Constante de limiar: `BTN_THRES_A` = 150
* **Botão B (Histórico / Créditos):** Conecta o pino A0 ao GND através de um resistor de $10\text{ k}\Omega$.
  - Tensão teórica: $5\text{V} \times \frac{10\text{k}}{10\text{k} + 10\text{k}} = 2.5\text{V} \implies ADC \approx 512$
  - Constante de limiar: `BTN_THRES_B` = 450
* **Botão Select (Confirmação):** Conecta o pino A0 ao GND através de um resistor de $22\text{ k}\Omega$.
  - Tensão teórica: $5\text{V} \times \frac{22\text{k}}{10\text{k} + 22\text{k}} \approx 3.44\text{V} \implies ADC \approx 703$
  - Constante de limiar: `BTN_THRES_SELECT` = 650

### Subrotinas de Interface
- **`Read_Buttons`:** Dispara a conversão ADC, aguarda sua conclusão realizando polling no bit `ADSC` do registrador `ADCSRA`, lê os registradores de resultado `ADCL` e `ADCH` (nesta ordem obrigatória) e classifica a leitura contra os limiares. Retorna o código do botão no registrador `temp` (`0` = Nenhum, `1` = Botão A, `2` = Botão B, `3` = Select).
- **`Wait_Button_Press`:** Aguarda em loop o pressionamento de um botão válido, aplica um delay de debounce de 20ms, aguarda a liberação completa do botão e aplica outro delay de 20ms antes de retornar com o código correspondente no registrador `temp`.

---

## 2. Buzzer e Motor de Música (`buzzer`)

O buzzer é controlado pelo pino digital `PD4`. O driver implementa geração de tons por software e um reprodutor de trilhas sonoras capaz de ler partituras simplificadas armazenadas na memória Flash.

### Subrotinas de Interface
- **`Buzzer_Play_Tone`:** Gera ondas quadradas chaveando o pino `PD4` por software. Recebe o semi-período do tom em `temp` (determina a frequência) e a quantidade de ciclos em `temp2` (determina a duração). Caso `temp` seja 0, executa uma pausa silenciosa (rest) com a duração programada.
- **`Buzzer_Tick`:** Emite um bipe ultra-curto (click mecânico) utilizado nos passos de rotação da roleta.
- **`Buzzer_Beep`:** Emite um bipe médio padrão para confirmação de seleções nos menus.
- **`Buzzer_Success`:** Emite um efeito sonoro festivo composto por 3 notas em escala ascendente rápido.
- **`Buzzer_Failure`:** Emite um tom grave arrastado indicando erro ou perda de aposta.
- **`Buzzer_Play_Current_Track`:** Toca a trilha musical carregada em `RAM_CURRENT_TRACK`. A reprodução é dividida em blocos curtos de som, intercalando leituras rápidas do ADC para permitir que o usuário interrompa a música a qualquer momento pressionando um botão (retorna o código do botão imediatamente, ou 0 se a música tocou até o fim).

### Trilhas Musicais Disponíveis na Flash:
* **Track 0:** Ode to Joy (Beethoven)
* **Track 1:** Minuet in G (Bach) - com redimensionamento de tempo em software (+25% lento)
* **Track 2:** Tetris Theme (Korobeiniki)
* **Track 3:** Star Wars Imperial March
* **Track 4:** Super Mario Bros Theme

---

## 3. Display LCD 16x2 via I2C (`lcd_i2c`)

O driver suporta tanto a simulação nativa no SimulIDE (controlador ST7032 no endereço de barramento de 7 bits `0x3E` / `0x7C` de escrita) quanto o hardware físico (controlador HD44780 com expansor PCF8574 no endereço configurável `0x27` / `0x4E`). A comunicação é efetuada por **Bit-Banging** nos pinos `PC4` (SDA) e `PC5` (SCL).

### Primitivas do Barramento I2C (`i2c.asm`)
- **`i2c_delay`:** Atraso calibrado de $\approx 4.5\,\mu\text{s}$ para conformidade com a temporização do barramento I2C padrão de 100 kHz.
- **`i2c_start` / `i2c_stop`:** Gera as condições físicas de START e STOP nas linhas de clock e dados.
- **`i2c_write_byte`:** Envia sequencialmente 8 bits do registrador `temp` (MSB first) chaveando SDA e SCL, e consome o pulso de clock do bit de ACK/NACK enviado pelo dispositivo escravo.

### Rotinas de Alto Nível (`lcd.asm`)
- **`LCD_Init`:** Inicializa as linhas SDA e SCL como open-drain, aguarda a estabilização de energia (50ms) e executa a sequência de comandos de inicialização em modo 4 bits (para o PCF8574) ou comandos nativos de contraste e fonte (para o ST7032).
- **`LCD_Clear`:** Limpa a tela inteira e retorna o cursor para a posição inicial (linha 0, coluna 0). Requer atraso obrigatório de 2ms.
- **`LCD_Set_Cursor`:** Move o cursor para a linha desejada (`temp` = `0` ou `1`) e coluna (`temp2` = `0` a `15`).
- **`LCD_Print_Msg`:** Lê uma string com terminador nulo (`0x00`) armazenada na Flash apontada pelo ponteiro `Z` (carregado com o endereço da string multiplicado por 2) e escreve caractere por caractere no display.
- **`LCD_Print_Dec16`:** Imprime um número inteiro de 16 bits (`r25:r24`) convertendo-o para caracteres ASCII legíveis com **supressão automática de zeros à esquerda**.

---

## 4. Matriz de LEDs 8x8 (`max7219`)

A matriz exibe feedback visual do estado do jogo (ícones estáticos nos menus e animação da bolinha girando ao redor da roleta). A comunicação é feita por Bit-Banging de barramento SPI simplificado nos pinos `DIN` (`PC1`), `SCK` (`PC2`) e `CS` (`PC3`).

### Estrutura do Framebuffer
Uma área de 8 bytes na SRAM (`RAM_SCREEN_BUF` a `RAM_SCREEN_BUF+7`) funciona como o buffer de tela. Cada byte representa os estados acesos/apagados dos 8 LEDs de uma linha da matriz.
- **`Matrix_Refresh`:** Varre os 8 bytes do buffer na SRAM e transmite comandos correspondentes ao MAX7219 via SPI para atualizar as 8 linhas fisicamente.
- **`Matrix_Clear`:** Zera todos os bytes do buffer da SRAM e envia uma atualização para desligar todos os LEDs da matriz.
- **`Matrix_Draw_Icon`:** Copia um bitmap estático de 8 bytes (ex. avatar, cifrão, interrogação) da memória Flash apontada por `Z` para o framebuffer da SRAM e atualiza a tela.
- **`Matrix_Render_Frame`:** Renderiza um frame personalizado combinando um padrão central estático (como um diamante de 2x2 LEDsaceso no centro da roleta) e uma bolinha acesa na borda. Recebe o padrão do centro em `temp` e o índice da bolinha (0-19) em `temp2`. A tabela `border_table` mapeia os índices circulares 0-19 para as coordenadas físicas de linha (1 a 8) e coluna (máscara de bits) na matriz.

---

## 5. LED RGB (`rgb_led`)

O LED RGB indica o jogador ativo ou a cor do número sorteado na rodada. O hardware está conectado aos pinos:
* **Vermelho (R):** `PD2`
* **Verde (G):** `PD1`
* **Azul/Preto (B):** `PD3`

### Subrotinas de Interface
- **`RGB_Clear`:** Desliga todos os três canais.
- **`RGB_Set_By_Player`:** Configura a cor associada ao jogador ativo (`temp` = 1 a 4):
  - **Jogador 1:** Vermelho
  - **Jogador 2:** Azul (Canal Blue conectado no pino)
  - **Jogador 3:** Verde
  - **Jogador 4:** Amarelo (Vermelho + Verde acesos juntos)
- **`RGB_Set_By_Number`:** Lê a cor do número sorteado (`temp` = 0 a 36) consultando a tabela `color_table` na Flash e acende o LED correspondente (Verde para o 0, Vermelho para números vermelhos, Azul/Preto para números pretos).

---

## 6. Displays de 7 Segmentos Multiplexados (`seven_seg`)

Dois displays de sete segmentos (catodo comum) exibem o número sorteado ou o jogador ativo.
- **Segmentos A, B, C:** Conectados a `PD5`, `PD6`, `PD7`.
- **Segmentos D, E, F, G:** Conectados a `PB0`, `PB1`, `PB2`, `PB3`.
- **Habilitação das Dezenas:** Pino `PB4` (Catodo Esquerdo - ativo baixo).
- **Habilitação das Unidades:** Pino `PB5` (Catodo Direito - ativo baixo).

### Multiplexação via Interrupção (Timer 0)
O driver utiliza a técnica de multiplexação de displays controlada por tempo, rodando de forma assíncrona na Rotina de Serviço de Interrupção **`TIMER0_ISR`** gerada a cada **2.0 ms** pelo Timer 0 (modo CTC com comparador A = 124, prescaler = 256).

A cada interrupção de 2ms, a ISR realiza:
1. Desativa ambos os catodos (`PB4 = 1`, `PB5 = 1`) para evitar efeito de "ghosting".
2. Lê o número armazenado em `RAM_ROUND_NUM` e separa as dezenas e unidades via divisões sucessivas por 10.
3. Alterna o display a ser atualizado (se atualizou unidade na anterior, atualiza dezena agora).
4. Carrega a máscara de segmentos correspondente ao dígito (0-9) das tabelas `table_portd` e `table_portb` armazenadas na Flash usando o ponteiro `Z`.
5. Escreve os bits de segmentos nas saídas `PORTD` e `PORTB` preservando os estados de outros pinos (como o do buzzer e I2C).
6. Ativa o catodo do dígito selecionado colocando o pino correspondente em nível baixo (`0`).

### Animações Especiais na ISR
Nas telas de boas-vindas (`STATE_WELCOME`) e seleção de jogadores (`STATE_NUM_PLAYERS`), a ISR assume um comportamento animado:
* **Fading do LED RGB (Soft-PWM):** Como o hardware não usa PWM por hardware nestes estados, a ISR implementa um PWM por software dividindo o tempo em frações de 8 ciclos e controlando dinamicamente a intensidade dos canais R, G, B em background, gerando uma transição suave (Fade) contínua entre as cores.
* **Segmento Giratório:** Em vez de exibir números, a ISR lê a tabela `anim_table_portd_left/right` e faz uma animação circular onde um único segmento de LED aceso percorre a borda externa dos dois displays, criando um efeito de roda girando.
