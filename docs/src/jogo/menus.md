# Interface de Menus e Estados de Entrada

O sistema gerencia as interações com os usuários por meio de uma máquina de estados principal que controla 4 telas de menu diferentes. A interface atualiza simultaneamente o display LCD de 16x2, os ícones de sinalização na matriz de LEDs 8x8, as cores de indicação do LED RGB, a contagem física nos displays de 7 segmentos e os retornos sonoros no buzzer.

## Estrutura do Subsistema de Menus

Os arquivos que controlam as transições de tela estão localizados em src/game/menu/:
* welcome.asm: Controla a tela inicial de boas-vindas, a rotação visual da bolinha na matriz e a seleção de músicas.
* players_sel.asm: Gerencia a rotina de configuração da quantidade de jogadores ativos.
* main.asm: Implementa o menu de navegação do painel dos jogadores (consulta de saldos e status).
* credits.asm: Responsável pela subrotina de ajuste e recarga manual de créditos na SRAM.

## Detalhamento das Rotinas e Estados

### Tela de Boas-Vindas (STATE_WELCOME)

#### Show_Welcome_Screen
* Descrição: Inicializa a interface limpando os registradores de controle do LCD e envia a string msg_welcome_title ("Roleta Francesa") para a primeira linha do display (linha 0).

#### Run_Welcome
* Funcionamento:
  1. Chama a rotina Show_Welcome_Screen para estabilizar o texto inicial no LCD.
  2. Entra em um loop de execução contínua chamando Buzzer_Play_Current_Track para processar a música de fundo passo a passo e atualizar os registradores de deslocamento da matriz de LEDs, gerando o efeito visual de rotação da bolinha.
  3. Caso a música atinja o final do vetor de notas sem interrupção, o ponteiro de áudio é resetado para reiniciar a música automaticamente.
  4. Ao detectar uma leitura válida no teclado analógico, o fluxo avalia o código de retorno:
     * Botão Select (Código 3): Aguarda a liberação do botão, incrementa o índice da música ativa RAM_CURRENT_TRACK (módulo 5 para ciclar entre as 5 trilhas), emite um bipe de confirmação com Buzzer_Beep e reinicia o estado executando a nova música.
     * Botões A (Código 1) ou B (Código 2): Aguardam a liberação do botão, disparam o bipe de confirmação e alteram o registrador de estado da FSM para STATE_NUM_PLAYERS.

### Seleção de Jogadores (STATE_NUM_PLAYERS)

#### Show_Num_Players_Menu
* Descrição: Carrega o padrão de bits do ícone de grupo (icon_group) diretamente na memória do driver da matriz de LEDs. Limpa o LCD para escrever o rótulo "Qtd Jogadores:" na linha 0 e o valor numérico corrente acompanhado da legenda de comandos " (A/B/S)" na linha 1.

#### Run_Num_Players
* Funcionamento:
  1. Executa Show_Num_Players_Menu para atualizar os periféricos.
  2. Aguarda até que um botão seja pressionado:
     * Botão A (Modificar): Incrementa a variável global de controle RAM_NUM_PLAYERS respeitando o limite mínimo de 1 e máximo de 4 jogadores, voltando para 1 caso o limite seja ultrapassado. Manda um clique sonoro de retorno e atualiza o LCD.
     * Botão B (Modificar): Decrementa o contador RAM_NUM_PLAYERS, voltando para 4 caso decresça abaixo de 1 jogador. Dispara o som de retorno e atualiza o display.
     * Botão Select (Confirmar): Salva o valor final na SRAM, emite o sinal sonoro de confirmação e muda a tela do jogo atual para STATE_MAIN_MENU.

### Menu de Consulta dos Jogadores (STATE_MAIN_MENU)

#### Show_Player_Menu
* Descrição:
  1. Copia o identificador do jogador ativo (active_plyr) para a variável RAM_ROUND_NUM associada aos displays de 7 segmentos, forçando a exibição do ID físico (01 a 04) no hardware.
  2. Executa a subrotina RGB_Set_By_Player para mudar a cor do LED RGB associada ao turno do respectivo jogador.
  3. Atualiza a matriz de LEDs com o ícone de identificação (icon_avatar).
  4. Limpa o LCD e renderiza o número do jogador e seu saldo de créditos na linha 0. Caso o bit de restrição *En Prison* (bit 0 do byte de status na SRAM) esteja ativado, anexa o caractere "(P)" ao lado do nome.
  5. Imprime a linha de navegação de comandos "A:Mudar B:Cred S:Gira" na linha 1.

#### Run_Main_Menu
* Funcionamento:
  1. Chama Show_Player_Menu para ajustar os periféricos aos dados do jogador corrente.
  2. Aguarda a leitura do teclado analógico:
     * Botão A (Alternar Turno): Incrementa o registrador active_plyr. Caso o valor supere a quantidade total de participantes registrados em RAM_NUM_PLAYERS, o ponteiro retorna para 1. A rotina emite um clique sonoro, atualiza os displays de 7 segmentos, reconfigura o LED RGB e limpa o LCD para exibir as informações financeiras do próximo jogador cadastrado.
     * Botão B (Menu de Créditos): Redireciona o estado da FSM principal para o modo de edição de fundos (STATE_SET_CREDITS).
     * Botão Select (Iniciar Rodada): Dispara o bipe de confirmação do buzzer, força o reset do ponteiro active_plyr de volta para 1 (garantindo que o primeiro jogador sempre abra a rodada de apostas) e altera a FSM global para o estado STATE_CHOOSE_CAT.

### 4. Ajuste de Créditos (STATE_SET_CREDITS)

#### Show_Credits_Menu
* Descrição: Envia o padrão binário do ícone de cifrão (icon_dollar) para atualização da matriz de LEDs. Limpa o LCD e formata a linha 0 com a string "P[ID] Set Bal: [Saldo]", aplicando a legenda de ajuste rápido "A:-100 B:+100 S:OK" na linha 1.

#### Run_Set_Credits
* Funcionamento:
  1. Chama a rotina gráfica Show_Credits_Menu.
  2. Intercepta o fluxo de execução até o acionamento de um botão:
     * Botão A (Subtrair): Carrega o saldo atual da SRAM do jogador. Se o montante for superior a zero (limite definido pela constante CREDIT_MIN_LIMIT), deduz 100 créditos do valor, salva o novo saldo na SRAM, emite um estalo sonoro de validação e atualiza o display LCD.
     * Botão B (Somar): Carrega o saldo atual da SRAM do jogador. Se o montante for inferior a 9900 créditos (limite definido pela constante CREDIT_MAX_LIMIT), adiciona 100 créditos ao saldo, armazena o resultado de volta na SRAM, emite o estalo sonoro e atualiza os dados na tela.
     * Botão Select (Confirmar): Salva definitivamente as alterações na memória, emite o bipe de sucesso no buzzer e retorna o estado principal da FSM para o Menu de Consulta (STATE_MAIN_MENU).