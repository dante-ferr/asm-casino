# Fluxo da Fase de Apostas e Mapeamento de Palpites

O gerenciamento da fase de apostas é feito no estado principal STATE_CHOOSE_CAT, localizado no diretório src/game/betting/. Neste estado, o sistema processa sequencialmente o turno de cada jogador ativo (de 1 até a quantidade cadastrada na SRAM), coletando o palpite (alvo) e a quantidade de créditos a ser apostada na rodada.

## Estrutura do Subsistema

O código de controle foi modularizado nos seguintes arquivos:
* main.asm: Gerencia a máquina de estados local, controle de turnos dos jogadores e as regras da flag *En Prison*.
* map.asm: Contém as subrotinas aritméticas que traduzem os índices da interface em dados lógicos de apostas.
* screen.asm: Concentra a renderização de menus no LCD e a leitura das tabelas de strings guardadas na memória Flash (Program Memory).

## Controle da Subrotina Run_Choose_Cat

O controle das etapas de aposta por jogador é feito por uma máquina de estados local codificada através do registrador r22 (sys_flags), que atua como ponteiro do modo de edição ativo:

O fluxo transita de forma sequencial a cada pressão do botão Select: inicia-se no Modo 0 (Seleção de Alvo), avança para o Modo 1 (Definição do Valor) e encerra no Modo 2 (Confirmação da Aposta). Na etapa de confirmação, caso o usuário selecione a opção "VOLTAR", o sistema retorna o ponteiro diretamente para o Modo 0, permitindo a reedição do palpite.

### Modo 0: Escolha do Alvo (Edit Target)
* Interface Visual: O LCD exibe o indicador << apontando para o palpite selecionado pelo usuário.
* Tratamento de Entradas (Teclado):
  * Botão A: Decrementa o índice de seleção (faixa de 0 a 48) armazenado no offset de configuração do jogador (Z+4). Possui lógica para retornar a 48 caso decresça abaixo de 0.
  * Botão B: Incrementa o índice de seleção, retornando a 0 caso ultrapasse 48.
  * Botão Select: Dispara um sinal sonoro curto de confirmação e atualiza sys_flags = 1, avançando para o Modo 1.

### Modo 1: Escolha do Valor (Edit Value)
* Interface Visual: O indicador << altera sua posição para o campo de volume de créditos.
* Tratamento de Entradas (Teclado):
  * Botão A: Subtrai 100 créditos do valor temporário da aposta. A rotina bloqueia decrementos abaixo de zero, disparando uma sinalização sonora de aviso no buzzer.
  * Botão B: Adiciona 100 créditos ao montante da aposta. O sistema faz uma leitura prévia do saldo restante do jogador na SRAM e impede que a aposta exceda o saldo disponível. Tentativas de ultrapassar o limite disparam a subrotina Buzzer_Failure e barram o incremento.
  * Botão Select: Valida o valor e define sys_flags = 2, avançando para a etapa de confirmação.

### Modo 2: Confirmação da Aposta (Confirm)
* Interface Visual: O LCD exibe as opções de alternância "Conf: SIM" ou "Conf: VOLTAR".
* Tratamento de Entradas (Teclado):
  * Botões A ou B: Invertem a escolha atual alternando o bit mais significativo (bit 7) de sys_flags.
  * Botão Select: Executa o desvio com base na escolha:
    * "VOLTAR": Reseta o indicador (sys_flags = 0) e retorna o jogador para a edição do alvo (Modo 0).
    * "SIM":
      1. Invoca a rotina Map_Selection_To_Bet para decodificar o índice visual em tipo e alvo reais.
      2. Salva as variáveis estruturadas na SRAM do jogador (offsets 3 e 4).
      3. Executa a subtração dos créditos diretamente no saldo armazenado do jogador e atualiza o balanço na SRAM.
      4. Zera sys_flags e incrementa o ponteiro de turno active_plyr para passar o controle ao próximo jogador.

### Restrição "En Prison"
Caso o jogador ativo possua o bit de restrição de prisão ativado em seu byte de status na SRAM (bit 0), a rotina principal intercepta o fluxo normal de apostas:
* Força a renderização da tela para show_betting_prison, exibindo a string fixa "P[ID]: PRISAO" acompanhada do valor retido.
* Bloqueia as entradas dos botões A e B, emitindo um sinal sonoro de erro caso sejam pressionados.
* Limita o fluxo ao botão Select, que confirma a manutenção da aposta presa e transfere diretamente o turno para próximo jogador.

---

## Subrotinas Auxiliares

### Map_Selection_To_Bet
* Localização: src/game/betting/map.asm
* Entrada: r16 (temp) = Índice numérico da interface (0 a 48).
* Saída: r16 (temp) = Tipo de aposta escolhida (0 = Interna/Número Direto, 1 = Externa/Categoria); r17 (temp2) = Alvo real da aposta.
* Lógica Matemática:
  A rotina avalia se o índice atingiu o limite de corte FIRST_INTERNAL_IDX (constante de valor 12):
  * Índices de 0 a 11 (Apostas Externas): Retorna Tipo = 1 e Alvo correspondente ao próprio índice (0 a 11).
  * Índices de 12 a 48 (Apostas Internas): Retorna Tipo = 0. O alvo numérico da roleta é obtido por subtração direta da base de deslocamento:
  
  $$\text{Alvo} = \text{Índice} - 12 \implies \text{Alvo} \in [0, 36]$$

---

### Check_Any_Bets
* Localização: src/game/betting/main.asm
* Saída: r16 (temp) = 1 se houver fundos ativos na mesa de apostas; 0 se a rodada estiver vazia.
* Descrição: Realiza uma varredura linear varrendo as partições de memória de todos os jogadores ativos (de 1 até RAM_NUM_PLAYERS). A rotina executa uma operação lógica OR cumulativa entre os bytes de aposta. Caso qualquer valor seja diferente de zero, o laço é interrompido antecipadamente com retorno positivo.

---

### Show_Betting_Screen
* Localização: src/game/betting/screen.asm
* Descrição: Renderiza o menu do display LCD condizente com o sub-estado armazenado em sys_flags. Para converter os índices dinâmicos das apostas externas (0 a 11) em texto legível, a rotina manipula o registrador de ponteiro Z (ZH:ZL) para ler as strings estáticas mapeadas na memória de programa (Flash) através da tabela target_strings_table:

| Índice | String na Flash | Tipo de Aposta Associada |
| :---: | :--- | :--- |
| 0 | "VERMELHO" | Cor Vermelha |
| 1 | "PRETO" | Cor Preta |
| 2 | "PAR" | Paridade Par |
| 3 | "IMPAR" | Paridade Ímpar |
| 4 | "BAIXO" | Números de 1 a 18 |
| 5 | "ALTO" | Números de 19 a 36 |
| 6 | "1a DUZIA" | Intervalo de 1 a 12 |
| 7 | "2a DUZIA" | Intervalo de 13 a 24 |
| 8 | "3a DUZIA" | Intervalo de 25 to 36 |
| 9 | "1a COLUNA" | Alinhamento vertical 1 |
| 10 | "2a COLUNA" | Alinhamento vertical 2 |
| 11 | "3a COLUNA" | Alinhamento vertical 3 |

## Apostas
Como o sistema tem o saldo dos jogadores em 16 bits e o valor de retorno pode causar overflow (como a aposta em número), logo foi feito um monitoramento da flag carry através de brcc nas rotinas de pagamento de rules.asm:
    Se houver carry, o valor é fixado para o limite máximo de 16 bits, 0xFFFF (65.535) pela rotina payout_clamp_max.
