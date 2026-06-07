# Guia de Inicialização, Compilação e Simulação

Este documento orienta sobre o processo de preparação do ambiente, compilação do código Assembly AVR, simulação virtual no SimulIDE e montagem e depuração do circuito físico.

---

## 1. Requisitos de Compilação

Para compilar o firmware do cassino, você precisará dos seguintes utilitários instalados no seu sistema operacional:

- **avra** (AVR Assembler): Assembler de código aberto compatível com a sintaxe oficial do assembler da Microchip/Atmel.
- **make** (GNU Make): Gerenciador de compilação automatizada.

### Instalação dos Requisitos

- **Linux (Debian/Ubuntu):**
  ```bash
  sudo apt-get update
  sudo apt-get install avra make
  ```
- **macOS (via Homebrew):**
  ```bash
  brew install avra make
  ```
- **Windows:**
  Recomenda-se a utilização de ambientes como MSYS2 ou WSL, ou o download direto dos binários pré-compilados do `avra` e `make` configurados no PATH do sistema.

---

## 2. Instruções de Compilação

O projeto conta com um [Makefile](file:///home/dante/Code/projects/asm-casino/Makefile) configurado na raiz para automatizar o processo.

### Compilação do Firmware (HEX)
Para compilar o código fonte principal ([src/main.asm](file:///home/dante/Code/projects/asm-casino/src/main.asm)) e gerar o arquivo de imagem executável ([src/main.hex](file:///home/dante/Code/projects/asm-casino/src/main.hex)):
```bash
make
```
Este comando compilará o código e limpará automaticamente os arquivos intermediários gerados pelo assembler (como `.obj`, `.lst`, `.cof`, `.eep`, etc.).

### Limpeza de Arquivos de Build
Para remover o arquivo executável `.hex` compilado e qualquer resíduo temporário:
```bash
make clean
```

---

## 3. Simulação no SimulIDE

O circuito virtual do projeto foi desenhado no **SimulIDE** e está localizado na pasta [circuit/](file:///home/dante/Code/projects/asm-casino/circuit).

- **Arquivo do Circuito:** [FrenchRoulette.sim1](file:///home/dante/Code/projects/asm-casino/circuit/FrenchRoulette.sim1)
- **Instruções para Simular:**
  1. Abra o **SimulIDE** (versão recomendada: 1.0.0 ou superior).
  2. Carregue o arquivo `FrenchRoulette.sim1`.
  3. Clique com o botão direito sobre o microcontrolador **ATmega328P** no painel do circuito.
  4. Selecione a opção **"Load Firmware"** e aponte para o arquivo compilado [src/main.hex](file:///home/dante/Code/projects/asm-casino/src/main.hex).
  5. Pressione o botão vermelho de **"Power"** para iniciar a simulação.
  6. Divirta-se nos menus de boas-vindas, escolha de jogadores, apostas e giros!

---

## 4. Guia de Conexão Física (Deploy Real)

Para montar este jogo de forma física utilizando um microcontrolador real (ex. placa Arduino Uno ou chip ATmega328P avulso), atente-se às especificações de pinagem e às adições elétricas essenciais:

### A. Escada de Resistores (Teclado Analógico no pino A0)
* **Conexão Obrigatória:** É necessário conectar um resistor físico de **10 kΩ de pull-up externo** do pino `A0` (`PC0`) ao terminal `5V` (VCC).
* **Motivo:** O pull-up interno do microcontrolador é desativado para garantir a linearidade das leituras analógicas do divisor de tensão. Sem o resistor físico externo, o pino analógico flutua e gera ruído, resultando em falsos cliques ou leituras inconsistentes.
* **Componentes:**
  - Botão A (Cima/Próximo) $\rightarrow$ Conexão direta ao GND.
  - Botão B (Baixo/Créditos) $\rightarrow$ Resistor de $10\text{ k}\Omega$ em série para o GND.
  - Botão Select (Confirmação) $\rightarrow$ Resistor de $22\text{ k}\Omega$ em série para o GND.

### B. Interface do LCD 16x2 com Módulo I2C PCF8574 (Backpack)
* **Configuração:** Mude a constante `.equ USE_PCF8574_BACKPACK` para `1` no arquivo [src/config.inc](file:///home/dante/Code/projects/asm-casino/src/config.inc#L144) antes de compilar para hardware real.
* **Endereço I2C:**
  - **Módulo PCF8574 padrão (mais comum):** Endereço `0x27` (Endereço de escrita de 8 bits: `0x4E`).
  - **Módulo PCF8574A:** Endereço `0x3F` (Endereço de escrita de 8 bits: `0x7E`). Se possuir esta versão, altere `.equ LCD_I2C_ADDR = 0x7E` no arquivo de configurações.
* **Ajuste de Contraste (Crítico):** Caso o LCD acenda mas nada seja exibido de imediato, gire devagar o trimpot azul no verso da placa de expansão I2C com uma chave de fenda até os caracteres aparecerem nítidos.

### C. Conexão do Buzzer (PD4)
Conectar o buzzer diretamente ao pino digital do microcontrolador pode danificar a porta caso o consumo ultrapasse 20mA. Utilize a seguinte configuração:
- **Buzzer Piezoelétrico:** Pode ser conectado diretamente com um resistor de $100\,\Omega$ em série para limitar corrente (Pino PD4 $\rightarrow$ Resistor $100\,\Omega$ $\rightarrow$ Buzzer (+) $\rightarrow$ GND).
- **Buzzer Eletromagnético (Recomendado):** Requer chaveamento com transistor.
  1. Conecte o terminal positivo (+) do Buzzer ao **5V (VCC)**.
  2. Conecte o terminal negativo (-) do Buzzer ao **Coletor** do transistor NPN (ex. 2N2222 ou BC547).
  3. Adicione um diodo de proteção (ex. 1N4148) em paralelo com o buzzer (Catodo listrado no 5V, Anodo no Coletor).
  4. Insira um resistor de $1\text{ k}\Omega$ entre o pino **PD4** do microcontrolador e a **Base** do transistor.
  5. Conecte o **Emissor** do transistor diretamente ao **GND (Terra)**.

---

## 5. Checklist de Depuração Rápida
1. **Os pinos de terra (GND) estão todos conectados?** display LCD, matriz de LEDs, protoboards e placa microcontroladora precisam compartilhar o mesmo GND comum.
2. **A velocidade do processador está correta?** O projeto assume um oscilador de cristal de **16 MHz**. Se rodar em frequências diferentes, as notas de áudio e os tempos do barramento I2C ficarão distorcidos.
3. **Endereço do LCD não responde?** Utilize um sketch "I2C Scanner" no Arduino para descobrir o endereço exato do seu módulo físico e atualize o [src/config.inc](file:///home/dante/Code/projects/asm-casino/src/config.inc).
