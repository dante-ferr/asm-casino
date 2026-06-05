# Notas de Montagem Física e Verificação de Hardware

Este documento contém a análise detalhada de hardware, cálculos de temporização e a lista de verificação (checklist) para compilação e deploy do firmware do Cassino ASM em hardware físico ATmega328P.

---

## 1. Delays de Software Calibrados

Os loops de delay de software em `i2c.asm` foram calibrados com precisão para uma frequência de clock do sistema de **16 MHz**.

### Calibração do Delay de 1ms (`delay_1ms`)
Para obter um delay exato de 1 ms, o loop requer precisamente 16.000 ciclos de clock.

* **Fórmula e Ciclos:**
  $$\text{Ciclos Totais} = 17 \text{ (overhead de chamada/retorno/salvamento)} + 20 \times 762 \text{ (iterações do loop externo)} + 761 \text{ (última iteração)} = 16.018 \text{ ciclos}$$
* **Tempo Real:**
  $$16.018 \text{ ciclos} / 16.000.000 \text{ Hz} \approx 1,0011 \text{ ms (precisão de 99.9\%)}$$

Esta precisão de tempo garante que delays críticos (como a inicialização e a limpeza da tela do LCD) atendam estritamente aos requisitos dos datasheets físicos.

---

## 2. Interface I2C do Display LCD (Módulo PCF8574)

A configuração física de hardware utiliza um LCD HD44780 conectado por meio de um expansor I2C PCF8574 (backpack).

### Mapeamento de Pinos
O firmware escreve bytes no PCF8574, que por sua vez define o estado dos pinos do HD44780:
* **Bit 0 (P0):** RS (Register Select) — Define `0` para comandos, `1` para dados.
* **Bit 1 (P1):** RW (Read/Write) — Conectado diretamente ao GND (modo de escrita).
* **Bit 2 (P2):** EN (Enable) — Pulsado de High para Low para registrar os dados.
* **Bit 3 (P3):** Controle do Backlight — Mantido ligado no código (`0x08`).
* **Bits 4–7 (P4–P7):** Linhas de dados de alta ordem (`D4`–`D7`).

### Latch de Nibbles (4 bits)
O HD44780 faz a leitura das linhas de dados na **borda de descida** do pino Enable (EN).
1. O código envia o nibble desejado (alto ou baixo) com `EN = 1`.
2. O código envia o mesmo nibble com `EN = 0`.
O tempo gasto para transmitir um byte via barramento I2C emulador por software ($\approx 90\mu\text{s}$) funciona como um delay natural extremamente seguro, superando com folga o tempo de pulso mínimo do EN ($450\text{ns}$) e o tempo de setup de dados do LCD ($80\text{ns}$).

### Sequência de Inicialização (Modo 4 bits)
1. **Estabilização de Energia:** Aguarda $50\text{ms}$ após ligar o circuito.
2. **Forçar Modo de 8 bits:** Envia o nibble `0x3` três vezes com delays específicos ($5\text{ms}$ após o primeiro, e $1\text{ms}$ após os seguintes).
3. **Mudar para Modo 4 bits:** Envia o nibble `0x2` e aguarda $1\text{ms}$.
4. **Configuração Básica:** Envia Function Set (`0x28`), Display Control (`0x0C`) e Entry Mode (`0x06`).

---

## 3. Conexões e Adições de Hardware Obrigatórias

Para montar este circuito em uma protoboard física, são necessárias as seguintes adições elétricas:

### A. Resistor de Pull-up em A0 (Teclado Analógico)
* **Requisito:** Conectar um resistor físico de **10kΩ (pull-up)** do pino `A0` (`PC0`) do ATmega328P ao `5V` (VCC).
* **Motivo:** O pull-up interno do microcontrolador é desativado para não distorcer as tensões do divisor resistivo. Sem um pull-up externo, o pino A0 flutua captando ruído eletromagnético, o que causará cliques fantasmas nos botões.

### B. Conexão do Buzzer (PD4)
Dependendo do tipo de buzzer que você possui, a conexão deve ser feita de uma das duas formas a seguir:

#### Caso 1: Buzzer Piezoelétrico (Conexão Direta Simples)
Se você tem um buzzer piezoelétrico (fundo aberto mostrando um disco de metal prateado/dourado):
1. **Pino Positivo (+)** do Buzzer: Conecte ao pino digital **PD4** (Pino Digital 4 do Arduino). *Dica: Insira um resistor de 100Ω em série com este pino para proteger a porta de picos de corrente.*
2. **Pino Negativo (-)** do Buzzer: Conecte diretamente ao terminal **GND (Terra)** do Arduino.

#### Caso 2: Buzzer Eletromagnético (Conexão com Transistor NPN)
Se você tem um buzzer eletromagnético (fundo selado de plástico ou resina preta), utilize um transistor NPN (como 2N2222 ou BC547) e um diodo (como 1N4148):
1. **Pino Positivo (+)** do Buzzer: Conecte diretamente ao terminal **5V (VCC)** do Arduino.
2. **Pino Negativo (-)** do Buzzer: Conecte ao terminal **Coletor** do transistor.
3. **Diodo (1N4148):** Conecte em paralelo com o buzzer, de forma que:
   * O lado com a listra preta (Catodo) seja conectado ao **5V (VCC)**.
   * O lado sem a listra (Anodo) seja conectado ao **pino negativo (-)** do buzzer (junto com o Coletor do transistor).
4. **Pino Digital PD4:** Conecte a um resistor de **1kΩ**. A outra extremidade deste resistor deve ir diretamente ao terminal **Base** do transistor.
5. **Terminal Emissor** do Transistor: Conecte diretamente ao terminal **GND (Terra)** do Arduino.

#### Como identificar as pernas (pinos) do Transistor (Pacote TO-92 de plástico preto):
Olhando para a parte achatada do transistor (onde está o texto impresso), com os terminais (pernas) apontados para baixo:
* **Se estiver usando o 2N2222:**
  * Perna da **esquerda**: **Emissor** (conecta ao GND)
  * Perna do **meio**: **Base** (conecta ao resistor de 1kΩ)
  * Perna da **direita**: **Coletor** (conecta ao pino negativo do buzzer)
* **Se estiver usando o BC547 (Cuidado: a ordem é invertida!):**
  * Perna da **esquerda**: **Coletor** (conecta ao pino negativo do buzzer)
  * Perna do **meio**: **Base** (conecta ao resistor de 1kΩ)
  * Perna da **direita**: **Emissor** (conecta ao GND)

* **Motivo:** Controlar o buzzer eletromagnético diretamente excede o limite de corrente recomendado de 20mA por pino do microcontrolador, causando superaquecimento, queda de tensão na alimentação (sags de VCC que resetam o processador) e ruído na leitura analógica dos botões.


---

## 4. Guia Prático de Depuração Física (Checklist)

Se o circuito for montado e a tela não exibir nada de imediato, siga este checklist:

1. **Ajuste o Potenciômetro de Contraste (CRÍTICO):**
   No verso do backpack I2C há um trimpot/potenciômetro azul. Ligue o circuito e gire este potenciômetro lentamente com uma chave de fenda até que os caracteres apareçam de forma nítida.
2. **Verifique o Endereço I2C do Módulo:**
   * **PCF8574 Padrão (Mais comum):** Endereço `0x27` (Endereço de escrita `0x4E`). Defina `.equ USE_PCF8574_BACKPACK = 1` em `config.inc`.
   * **PCF8574A:** Endereço `0x3F` (Endereço de escrita `0x7E`). Altere `.equ LCD_I2C_ADDR = 0x7E` no arquivo `config.inc`.
3. **Compartilhamento de Terra (GND Comum):**
   Garanta que a trilha de terra (GND) do Arduino, do display LCD e da matriz de LEDs estejam interconectadas no mesmo ponto comum.
