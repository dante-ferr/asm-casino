# Guia de Montagem Física e Documentação de Hardware

Este documento serve como referência técnica para a montagem do circuito físico do Cassino ASM no microcontrolador ATmega328P (Arduino Uno) e para a elaboração do relatório final do projeto.

---

## 1. Configurações de Firmware (Checklist de Compilação)

Antes de gravar o firmware no microcontrolador físico, certifique-se de configurar o arquivo [src/config.inc](../src/config.inc) corretamente:

* **LCD I2C Backpack**: Altere a constante `.equ USE_PCF8574_BACKPACK = 1` para ativar o protocolo de inicialização de 4 bits para módulos I2C HD44780 (mochila PCF8574).
* **Frequência de Operação**: O código foi projetado para **16 MHz**. Todos os delays (como os de comunicação I2C de 100 kHz e geração de tons do buzzer) estão calibrados com base nesta frequência.

---

## 2. Pinagem e Conexões de Hardware

| Dispositivo | Pinos do Arduino | Descrição Física |
| :--- | :--- | :--- |
| **Buzzer Piezoelétrico** | `PD4` | Conectado com um resistor de $220\,\Omega$ em série para proteger o pino. |
| **Teclado Analógico** | `PC0 (A0)` | Resistor ladder conectado à entrada analógica. |
| **Matriz de LEDs MAX7219**| `PC1` (DIN), `PC2` (SCK), `PC3` (CS) | Barramento SPI via bit-banging para controle da matriz 8x8. |
| **Display LCD I2C** | `PC4` (SDA), `PC5` (SCL) | Comunicação I2C com resistores de pull-up de $4.7\,\text{k}\Omega$ ligados ao VCC. |
| **LED RGB** | `PD1` (G), `PD2` (R), `PD3` (B) | Controlado dinamicamente para indicar o jogador ativo e resultados. |
| **Displays de 7 Segmentos**| `PD5-PD7` & `PB0-PB3` | Pinos de segmentos (A-G), cada um com um resistor de $220\,\Omega$ em série. |
| **Controle de Dígito (Mux)**| `PB4` (Dezena), `PB5` (Unidade) | Pinos de controle de catodo comum (multiplexação). |

---

## 3. Detalhes Importantes de Montagem

### A. Teclado Analógico (Resistor Ladder)
* **Requisito**: Conecte um resistor físico de **10kΩ (pull-up)** do pino `A0` ao `5V`.
* **Sem zona morta (Modificação de Firmware)**: O código foi ajustado para eliminar "zonas mortas". Qualquer leitura abaixo de 350 é atribuída ao Botão A, evitando que mau contato ou variações de resistores façam o botão ser ignorado.
* **Filtro de Ruído (Opcional)**: Caso ocorram cliques fantasmas causados pelo ruído da multiplexação, adicione um capacitor cerâmico de **10nF a 100nF** entre o pino `A0` e o **GND**.

### B. Buzzer Piezoelétrico
* **Requisito**: Um resistor de **220Ω** deve ser colocado em série com o piezo conectado ao pino `PD4` para limitar picos de corrente capacitiva e proteger as portas do chip.

### C. Barramento I2C (Pull-ups)
* **Requisito**: Conecte resistores de pull-up de **4.7kΩ** nas linhas SDA (`PC4`) e SCL (`PC5`) para o terminal de `5V`. (Resistores muito altos causam falha de comunicação física devido à capacitância dos cabos).

---

## 4. Recomendações e Fallbacks (Caso ocorram problemas)

### A. Estresse Térmico nos Displays (Opcional / Fallback)
Conectar os catodos comuns dos displays de 7 segmentos diretamente aos pinos `PB4` e `PB5` funciona para projetos de demonstração rápida. Porém, ao exibir o número "8", o pino correspondente drena até **$95\text{mA}$** (o limite de segurança do ATmega328P é de **$40\text{mA}$**).
* **Sintoma de falha**: Displays piscando, brilho oscilando de acordo com o dígito (o "8" fica muito mais fraco que o "1"), ou superaquecimento do chip.
* **Correção**: Adicione dois transistores NPN (ex: BC547 ou 2N2222) ou MOSFETs canal N (ex: 2N7000) como chaves de lado baixo, acionados pelos pinos do Arduino via resistor de $1\text{k}\Omega$. Nesse caso, inverta a lógica de acionamento do display no código ([isr.asm](file:///home/dante/Code/projects/asm-casino/src/hardware/seven_seg/isr.asm)) de active-low (0) para active-high (1).

### B. Instabilidade e Travamentos (Decoupling Fallback)
A matriz MAX7219 liga e desliga muitos LEDs simultaneamente, gerando muito ruído na alimentação de 5V.
* **Sintoma de falha**: O jogo trava aleatoriamente durante o giro da roleta ou o Arduino reinicia sozinho.
* **Correção**: Conecte um capacitor eletrolítico de **10µF a 100µF** em paralelo com um capacitor cerâmico de **100nF** diretamente nos pinos de alimentação ($V_{CC}$ e $GND$) da placa da Matriz MAX7219.

---

## 5. Guia Rápido de Depuração
1. **LCD acende mas não mostra letras**: Gire o trimpot azul de contraste no verso do módulo LCD lentamente até que as letras apareçam.
2. **Endereço I2C incorreto**: Se o LCD não iniciar de jeito nenhum, confirme o endereço. Os módulos PCF8574 costumam usar `0x27` (escrita `0x4E`), enquanto os PCF8574A usam `0x3F` (escrita `0x7E`). Configure o valor correspondente no arquivo `config.inc`.
3. **GND Comum**: Todos os terras (GND do Arduino, da matriz, do LCD e dos displays) devem estar conectados eletricamente no mesmo ponto comum.
