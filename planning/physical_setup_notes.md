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

### A. Driver de Transistor para os Displays (Opcional / Fallback)
Conectar os catodos comuns dos displays diretamente aos pinos `PB4` e `PB5` do Arduino funciona para demonstrações rápidas, mas sobrecarrega o chip em até **$95\text{mA}$** ao exibir o dígito "8" (o limite do pino é de **$40\text{mA}$**).
* **Sintomas de falha:** O display oscila de brilho (o "8" fica muito mais fraco que o "1"), pisca de forma instável ou o Arduino fica muito quente perto dos pinos 12 e 13.
* **Seu professor pode tirar nota?** Sim. Em projetos acadêmicos de microcontroladores, acionar cargas que passam de $40\text{mA}$ direto pelas portas GPIO (sem transistor) é considerado um erro grave de projeto elétrico nas avaliações.

#### Como montar o transistor no circuito (Passo a Passo na Protoboard):
Você precisará de **2 transistores NPN** (ex: `BC547` ou `2N2222`) e **2 resistores de 1kΩ**.

1. **Identifique os Pinos do Transistor** (Olhando de frente para a parte achatada de plástico preto, com as pernas apontadas para baixo):
   * **Se usar o BC547:** Esquerda = **Coletor**, Meio = **Base**, Direita = **Emissor**.
   * **Se usar o 2N2222:** Esquerda = **Emissor**, Meio = **Base**, Direita = **Coletor**.
2. **Conecte o Transistor 1 (Dígito das Dezenas):**
   * Conecte o pino **Emissor** direto no barramento de **GND (Terra)** do circuito.
   * Conecte um resistor de **1kΩ** entre o pino **PB4** (pino 12 do Arduino) e a **Base** (pino do meio) do transistor.
   * Desconecte o pino de **Catodo Comum** do display de dezenas do Arduino e ligue-o diretamente no pino **Coletor** do transistor.
3. **Conecte o Transistor 2 (Dígito das Unidades):**
   * Faça a mesma ligação: **Emissor** no **GND**, pino **PB5** (pino 13 do Arduino) através de outro resistor de **1kΩ** conectado à **Base** (pino do meio), e o **Catodo Comum** do display de unidades no **Coletor**.
4. **Inverta a lógica no código:** Veja o procedimento de inversão na Seção 3.C acima se decidir aplicar este fallback.

---

### B. Capacitores de Desacoplamento da Matriz MAX7219 (Opcional / Fallback)
A matriz de LEDs consome muita corrente rapidamente para varrer as colunas, gerando oscilações violentas no VCC de 5V.
* **Sintomas de falha:** O jogo trava do nada durante o giro da roleta, o buzzer emite cliques estranhos ou o Arduino reinicia sozinho.
* **Seu professor pode tirar nota?** Geralmente não tiram nota por isso, a menos que o circuito trave bem na hora em que o professor for avaliar o seu projeto!

#### Como ligar os capacitores no circuito (Passo a Passo na Protoboard):
Você precisará de **1 capacitor cerâmico de 100nF** (identificado com o número "104") e **1 capacitor eletrolítico de 10µF a 100µF**.

1. **Ligue o Capacitor Cerâmico (100nF):**
   * Ligue uma perna dele diretamente no pino **VCC** da entrada da placa MAX7219.
   * Ligue a outra perna diretamente no pino **GND** da placa MAX7219.
   * *Nota: Capacitores cerâmicos não têm polaridade (não importa qual perna vai em qual pino).*
2. **Ligue o Capacitor Eletrolítico (10µF a 100µF):**
   * *Atenção: Este capacitor tem polaridade. A perna mais longa é o Positivo (+), e o lado com uma faixa cinza/branca no corpo é o Negativo (-).*
   * Conecte a perna **Positiva (+)** no pino **VCC** do módulo MAX7219.
   * Conecte a perna **Negativa (-)** no pino **GND** do módulo MAX7219.
3. **Posicionamento:** Certifique-se de que ambos os capacitores estejam espetados na protoboard o mais perto possível dos pinos de entrada da matriz MAX7219.

---

## 5. Guia Rápido de Depuração
1. **LCD acende mas não mostra letras**: Gire o trimpot azul de contraste no verso do módulo LCD lentamente até que as letras apareçam.
2. **Endereço I2C incorreto**: Se o LCD não iniciar de jeito nenhum, confirme o endereço. Os módulos PCF8574 costumam usar `0x27` (escrita `0x4E`), enquanto os PCF8574A usam `0x3F` (escrita `0x7E`). Configure o valor correspondente no arquivo `config.inc`.
3. **GND Comum**: Todos os terras (GND do Arduino, da matriz, do LCD e dos displays) devem estar conectados eletricamente no mesmo ponto comum.
