# Documentação do Projeto: Roleta Francesa (ASM Casino)

Este diretório contém a documentação técnica completa do projeto **Roleta Francesa** implementado em **Assembly AVR** para o microcontrolador ATmega328P. O projeto foi projetado para simulação no SimulIDE e montagem em protoboard física.

---

## 📂 Estrutura de Documentos

Para facilitar a leitura e organização, a documentação está modularizada nos seguintes guias detalhados:

1. **[Guia de Inicialização, Compilação e Simulação (getting_started.md)](file:///home/dante/Code/projects/asm-casino/local/docs/getting_started.md)**:
   Instruções para configurar dependências (`avra`, `make`), compilar o firmware, simular no SimulIDE e montar/depurar o circuito físico de protoboard (cálculos de resistores, diodos, transistor do buzzer e contraste).
2. **[Arquitetura de Software e Organização da Memória (architecture.md)](file:///home/dante/Code/projects/asm-casino/local/docs/architecture.md)**:
   Mapeamento de pinos do ATmega328P, convenções e regras de gerenciamento dos registradores de uso geral, layout completo da SRAM (incluindo estrutura do jogador) e Máquina de Estados Finita (FSM).
3. **[Referência dos Drivers de Periféricos (hardware.md)](file:///home/dante/Code/projects/asm-casino/local/docs/hardware.md)**:
   Explicação de baixo nível de todos os drivers físicos desenvolvidos em Assembly: Barramento I2C por software, Matriz de LEDs 8x8 via SPI (MAX7219), LED RGB, Buzzer piezoelétrico/magnético com partituras em Flash, teclado analógico e multiplexação dinâmica de display de 7 segmentos.
4. **[Lógica de Jogo, Regras e Apostas (game.md)](file:///home/dante/Code/projects/asm-casino/local/docs/game.md)**:
   Mapeamento de alvos internos e externos da roleta, geração de números pseudo-aleatórios (PRNG) baseada em Timer 1, física de giro com atrito (friction decay) e a lógica de aprisionamento de apostas ("En Prison").
5. **[Referência Completa de Subrotinas (api.md)](file:///home/dante/Code/projects/asm-casino/local/docs/api.md)**:
   Catálogo de todas as funções e subrotinas estruturadas por módulos de hardware, jogadores, PRNG, menus e regras, com as especificações completas de registradores de entrada, registradores de saída e registradores afetados.

---

## 🛠️ Relação de Materiais Utilizados

Para a montagem física do circuito, foram necessários os seguintes componentes eletroeletrônicos:

| Item | Qtd | Componente | Finalidade / Conexão |
| :---: | :---: | :--- | :--- |
| **1** | 1 | Microcontrolador ATmega328P | Placa Arduino Uno ou chip avulso com cristal de 16 MHz. |
| **2** | 1 | Display LCD 16x2 com I2C Backpack | Exibição de menus e informações de saldo/apostas. |
| **3** | 1 | Matriz de LEDs 8x8 (Driver MAX7219) | Simulação visual da bolinha girando na roleta. |
| **4** | 2 | Displays de 7 Segmentos (Cátodo Comum)| Exibição do número sorteado ou ID do jogador ativo. |
| **5** | 1 | LED RGB | Identificação visual do jogador (R/G/B) ou cor do número sorteado. |
| **6** | 1 | Buzzer Piezoelétrico ou Magnético | Feedback de cliques, avisos e reprodução de melodias. |
| **7** | 3 | Push-Buttons tácteis | Entrada de comandos do usuário (Botões A, B e Select). |
| **8** | 3 | Resistores de $220\,\Omega$ | Proteção de corrente para canais Verde e Azul do RGB e display. |
| **9** | 6 | Resistores de $330\,\Omega$ | Proteção para os segmentos dos displays e RGB Vermelho. |
| **10**| 2 | Resistores de $10\text{ k}\Omega$ | 1x Pull-up externo no pino A0, 1x divisor do Botão B. |
| **11**| 1 | Resistor de $22\text{ k}\Omega$ | Divisor de tensão do Botão Select. |
| **12**| 1 | Resistor de $1\text{ k}\Omega$ | Limitador de corrente de base do transistor do buzzer. |
| **13**| 1 | Transistor NPN (2N2222 ou BC547) | Amplificação de corrente para acionar o buzzer magnético. |
| **14**| 1 | Diodo Retificador (1N4148 ou 1N4007)| Diodo de roda livre para amortecer picos indutivos do buzzer. |
| **15**| - | Protoboard e Cabos Jumpers | Conexão geral dos componentes. |

---

## 💻 Diagrama do Circuito

O circuito completo do projeto está modelado e operacional no SimulIDE.
- **Arquivo virtual:** [circuit/FrenchRoulette.sim1](file:///home/dante/Code/projects/asm-casino/circuit/FrenchRoulette.sim1)

### Visualização do Circuito no SimulIDE
*(Insira aqui um print do diagrama do SimulIDE gerado para o repositório)*
`![Diagrama do Circuito no SimulIDE](../assets/circuit_simulide.png)`

---

## 🎮 Guia de Utilização (Funcionamento do Jogo)

1. **Boas-Vindas:**
   Ao ligar o circuito, a melodia atual toca e a bolinha gira na matriz de LEDs. 
   - Pressione **Select** para alternar a música ativa.
   - Pressione **A** ou **B** para iniciar a configuração de jogadores.
2. **Definição de Jogadores:**
   - Pressione **A** para aumentar ou **B** para diminuir a quantidade de jogadores participantes ($1$ a $4$).
   - Pressione **Select** para confirmar.
3. **Menu Principal (Painel de Balanço):**
   - O display de 7 segmentos indica o jogador ativo. O LED RGB assume a cor do jogador.
   - O LCD exibe o jogador e seu saldo atual (inicialmente 1000).
   - Pressione **A** para alternar o jogador ativo.
   - Pressione **B** para entrar no menu de créditos do jogador ativo.
   - Pressione **Select** para entrar no fluxo de aposta do jogador ativo.
4. **Configuração de Créditos:**
   - Permite ajustar o saldo inicial do jogador selecionado.
   - Pressione **A** para adicionar $+100$ ou **B** para reduzir $-100$ pontos.
   - Pressione **Select** para salvar o novo saldo e retornar.
5. **Fluxo de Aposta:**
   - **Fase 1 (Escolha do Alvo):** Pressione **A** ou **B** para navegar pelos alvos (vermelho, azul/preto, par, ímpar, baixo, alto ou números exatos de 0 a 36). Pressione **Select** para avançar.
   - **Fase 2 (Definição do Valor):** Pressione **A** para adicionar $+100$ ou **B** para reduzir $-100$ à aposta (limitado pelo saldo atual). Pressione **Select** para avançar.
   - **Fase 3 (Confirmação):** Selecione **SIM** (A) para girar a roleta ou **VOLTAR** (B) para corrigir. Pressione **Select** para confirmar a escolha.
6. **Resolução e En Prison:**
   - A roleta gira visual e sonoramente. 
   - O resultado é exibido e os saldos são computados. Se ganhar, toca um som de sucesso. Se perder, toca falha.
   - Se for sorteado **0 (zero)** em aposta externa, o dinheiro é aprisionado. Na próxima vez daquele jogador, a única ação será um giro obrigatório para recuperar ou perder o saldo "En Prison".

---

## 👥 Equipe e Contribuições

Conforme as orientações da disciplina MATA49 (Software Básico - UFBA), segue a relação dos integrantes do grupo e a descrição das responsabilidades de desenvolvimento:

* **Dante Ferreira**
  - Modularização e refatoração do código em subarquivos reutilizáveis.
  - Implementação do suporte para LCD físico com expansor PCF8574.
  - Desenvolvimento da rotina de debounce do teclado analógico.
  - Elaboração da documentação técnica e calibração fina de delays de hardware.
* **Guilherme Souza**
  - Implementação da lógica de pontuação dos jogadores e estruturação da memória SRAM.
  - Desenvolvimento do PRNG de Timer 1 e resolução matemática de ganhos/perdas.
  - Montagem e teste de componentes integrados no simulador.
* **Johanesgauss**
  - Desenvolvimento do driver de áudio (buzzer) e importação das trilhas sonoras.
  - Modelagem do circuito eletrônico virtual no SimulIDE.
  - Testes gerais de depuração das regras da Roleta Francesa ("En Prison").
