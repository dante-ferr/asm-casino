# Explicação Técnica Temporária: Arquitetura de Software e Hardware

Este documento serve como material de apoio e rascunho técnico para a elaboração da documentação final do projeto da Roleta Francesa no ATmega328P. Ele detalha as decisões de engenharia adotadas para o gerenciamento de registradores, organização da SRAM e abstração de hardware.

---

## 1. Diretrizes para Gerenciamento de Registradores

No microcontrolador ATmega328P (arquitetura AVR RISC de 8 bits), dispomos de 32 registradores de uso geral (`R0` a `R31`). Para evitar conflitos de dados onde uma subrotina ou uma Rotina de Serviço de Interrupção (ISR) sobrescreve acidentalmente valores em uso no loop principal, dividimos os registradores em categorias funcionais rígidas:

### A. Registradores Temporários de Trabalho (Scratchpad) — `R16` a `R19`
*   **Finalidade:** Realizar operações imediatas (`ldi`, `andi`, `ori`), cálculos locais de curta duração e passagem rápida de parâmetros.
*   **Regra de Uso:** Qualquer função pode usá-los e modificar seu conteúdo livremente. Se o loop principal precisar reter um valor ao longo de várias chamadas de função, ele **não** deve mantê-lo nestes registradores (ou deve salvá-lo na pilha).

### B. Registradores Globais de Estado — `R20` a `R23`
*   **Finalidade:** Armazenar variáveis essenciais para o fluxo geral da Máquina de Estados Finita (FSM) que precisam ser acessadas constantemente e de forma rápida.
*   *   `R20 = CURRENT_STATE`: Controla em qual estado da FSM o jogo se encontra.
    *   `R21 = ACTIVE_PLAYER`: Guarda o ID (1 a 4) do jogador que está operando no momento.
    *   `R22 = SYSTEM_FLAGS`: Guarda flags binárias de controle (ex: bit 0 para buzzer habilitado, bit 1 para rotação em andamento).
*   **Regra de Uso:** São alterados apenas por funções específicas de controle de fluxo de jogo. Nenhuma rotina de hardware de baixo nível tem permissão de usá-los como rascunho.

### C. Par de Argumentos e Retornos — `R24` e `R25`
*   **Finalidade:** Passagem de parâmetros de 8 ou 16 bits para funções de cálculo (como cálculo de saldo ou semente de aleatoriedade) e para receber o valor de retorno de funções de leitura.
*   *   Para valores de 8 bits: Usa-se preferencialmente `R24`.
    *   Para valores de 16 bits: Usa-se o par `R25:R24` (onde `R25` é o byte mais significativo, MSB, e `R24` é o byte menos significativo, LSB).

### D. Ponteiros de Endereçamento Indireto — `X` (`R26:R27`), `Y` (`R28:R29`), `Z` (`R30:R31`)
*   **Ponteiro `X`:** Reservado exclusivamente para apontar para a estrutura do **jogador ativo** na SRAM. Ao carregar `X` com o endereço base do jogador atual no início de um turno, todas as operações subsequentes de apostas e atualização de saldo utilizam instruções do tipo `ld` (Load) ou `st` (Store) usando `X` como base.
*   **Ponteiro `Y`:** Usado para manipulação genérica de memória SRAM secundária (como buffers de exibição do LCD ou histórico global de sorteios).
*   **Ponteiro `Z`:** Reservado obrigatoriamente para a leitura de tabelas ou strings armazenadas na memória Flash (memória de programa) usando a instrução `lpm` (Load Program Memory). Isso inclui mensagens de texto do menu LCD e a tabela de conversão para o display de 7 segmentos.

---

## 2. Organização e Gerenciamento da Memória SRAM

A SRAM é a memória volátil onde são salvos os dados de execução e estados que mudam em tempo de execução. Ela se inicia no endereço `0x0100` no ATmega328P.

### A. Dados dos Jogadores (Estruturação Orientada a Registros/Objetos)
Para suportar o limite de 4 jogadores simultâneos de forma simples e escalável, criamos uma estrutura uniforme de 16 bytes para cada jogador. A SRAM é particionada da seguinte forma:
*   **Jogador 1:** `0x0100` até `0x010F`
*   **Jogador 2:** `0x0110` até `0x011F`
*   **Jogador 3:** `0x0120` até `0x012F`
*   **Jogador 4:** `0x0130` até `0x013F`

Para acessar as informações de forma limpa no código, calculamos o endereço dinamicamente no início de cada ação:
$$\text{Endereço Base} = 0x0100 + (\text{ACTIVE\_PLAYER} - 1) \times 16$$

Uma vez carregado o endereço base no ponteiro `X`, usamos deslocamentos fixos (offsets) para manipular os dados do jogador ativo:
*   `X + 0` e `X + 1`: **Saldo Atual** (Inteiro de 16 bits: MSB em `X+0`, LSB em `X+1`).
*   `X + 2`: **Status do Jogador** (Flags de controle: Bit 0 indica se o jogador está com saldo bloqueado pela regra *En Prison*).
*   `X + 3`: **Tipo de Aposta** (Define se a aposta é interna/número único ou externa/categoria como par/ímpar, cor, etc.).
*   `X + 4`: **Alvo da Aposta** (O número exato escolhido entre 0-36 ou o código identificador da categoria externa).
*   `X + 5` e `X + 6`: **Valor da Aposta Atual** (Inteiro de 16 bits bloqueado para o giro atual).
*   `X + 7` a `X + 11`: **Histórico Local** (Buffer circular ou linear de 5 bytes contendo os últimos 5 números sorteados enquanto este jogador estava ativo).

### B. Variáveis Globais de Jogo
Ficam alocadas logo após os blocos de memória dos jogadores (a partir do endereço `0x0140`):
*   `CURRENT_ROUND_NUM` (`0x0140`): Número inteiro (0 a 36) sorteado na rodada atual da roleta.
*   `GLOBAL_HISTORY` (`0x0141` - `0x0145`): Vetor com os últimos 5 números sorteados de forma geral na roleta (exibidos na tela de histórico geral).
*   `TMR1_SEED` (`0x0146` - `0x0147`): Semente capturada a partir do temporizador de hardware de 16 bits `TCNT1` no momento em que um botão é pressionado, garantindo uma fonte de entropia real para o gerador de números pseudo-aleatórios.

---

## 3. Arquitetura de Hardware e Abstração dos Drivers

A comunicação com os periféricos do projeto é feita através de rotinas isoladas no diretório `hardware/`, garantindo que o loop principal do jogo não precise gerenciar portas lógicas diretamente.

### A. Display LCD 16x2 (I2C AIP31068) via Bit-Banging
O controlador AIP31068 utiliza o protocolo I2C. Como a biblioteca nativa em Assembly para I2C por hardware (`TWI`) pode ser extensa, implementamos a comunicação por **Bit-Banging** nas portas `PC4` (SDA) e `PC5` (SCL) do ATmega328P:
*   A linha SCL é chaveada manualmente via software com pequenos atrasos (delays de poucos microssegundos) para atender às especificações de temporização do barramento I2C.
*   A inicialização e envio de comandos/dados são abstraídos em funções como `lcd_init`, `lcd_clear` e `lcd_print_string`.

### B. Teclado Analógico (ADC0 - PC0) com Escada de Resistores
Para economizar pinos digitais, três botões (Próximo, Histórico e Select) são conectados a uma única entrada analógica (`PC0/ADC0`) através de um divisor de tensão (escada de resistores).
*   **Operação:** O ADC do microcontrolador é configurado para resolução de 10 bits ($V_{REF} = 5\text{V}$, gerando leituras digitais de 0 a 1023).
*   **Janelas de Comparação:** A rotina do ADC realiza a leitura e compara o valor contra limiares fixados no arquivo de configuração (`config.inc`):
    *   Botão A (Próximo): $0 \le ADC < 150$ (Teórico: 0)
    *   Botão B (Histórico): $450 \le ADC < 600$ (Teórico: 512)
    *   Botão Select (Confirmação): $650 \le ADC < 800$ (Teórico: 703)
    *   Nenhum botão: $ADC \ge 900$ (Teórico: 1023)
*   **Debounce por Software:** Evitamos leituras falsas decorrentes do ruído mecânico dos botões através de um mecanismo de debounce, comparando leituras consecutivas com intervalo mínimo de tempo regulado pelos ticks da interrupção do Timer 0.

### C. Display de 7 Segmentos e Multiplexação por Interrupção (Timer 0)
Os displays de dezenas e unidades compartilham os mesmos pinos de controle de segmentos nas portas `PORTD` (PD5-PD7) e `PORTB` (PB0-PB3). 
*   **Problema:** Se tentarmos acender ambos os dígitos ao mesmo tempo com os mesmos fios, eles mostrarão o mesmo valor.
*   **Solução (Multiplexação Dinâmica):** Acendemos apenas um dígito por vez de forma muito rápida. 
*   **Implementação na ISR:** O **Timer 0** é configurado para gerar uma interrupção periódica a cada **2 ms** (~500 Hz). Na Rotina de Serviço de Interrupção (`TIMER0_COMPA_vect` ou `TIMER0_OVF_vect`):
    1.  Desliga o catodo comum do dígito atualmente ativo (pino `PB4` ou `PB5` em nível alto).
    2.  Lê o valor numérico correspondente ao próximo dígito (unidade ou dezena).
    3.  Busca o padrão de segmentos equivalente na memória Flash utilizando o ponteiro `Z`.
    4.  Escreve os segmentos correspondentes nas portas de saída `PORTD` e `PORTB`.
    5.  Liga o catodo comum do dígito atualizado (pino correspondente em nível baixo).
    6.  Alterna o estado lógico de controle para a próxima interrupção.
*   Essa taxa de alternância de 250 Hz por dígito engana o olho humano devido ao fenômeno da persistência retiniana, criando a ilusão de que ambos os displays estão continuamente acesos.

### D. Matriz de LEDs 8x8 (MAX7219 via SPI por Software)
A matriz de LEDs é controlada pelo driver serial MAX7219, que se comunica por um barramento SPI simplificado de 3 fios: Dados (`DIN` / `PC1`), Clock (`CLK` / `PC2`) e Seleção de Chip (`CS` / `PC3`).
*   A transmissão de cada pacote de 16 bits (endereço do registrador MAX7219 + dado de controle) é feita através de software deslocando os bits sequencialmente para fora, pulsando o clock a cada bit e habilitando a linha `CS` no início e fim do pacote.
*   A animação do giro da roleta move um pixel aceso pelas bordas da matriz, reduzindo a velocidade gradualmente (simulando atrito físico) através de delays crescentes até parar no número sorteado.

### E. Controle Isolado de Buzzer (`buzzer.asm`)
*   O buzzer é acionado pelo pino `PD4`. O driver expõe subrotinas para emitir beeps rápidos de confirmação de clique e alertas de erro ou vitória.
*   Para efeitos sonoros sem travar a execução geral, a rotina define o tempo de duração da nota baseada no temporizador de ticks gerados pela interrupção do Timer 0.

### F. Controle Isolado de LED RGB (`rgb_led.asm`)
*   Controla três pinos digitais conectados às cores Vermelha (`PD2`), Preta/Azul (`PD3`) e Zero/Verde (`PD1`).
*   Subrotinas como `RGB_Show_Red`, `RGB_Show_Black`, `RGB_Show_Green` e `RGB_Clear` abstraem a escrita de níveis lógicos altos/baixos nesses pinos específicos, sincronizando a indicação luminosa ao número sorteado na rodada.
