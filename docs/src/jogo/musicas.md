# Sistema de Áudio e Trilhas Sonoras

O sistema de áudio do jogo é responsável por emitir efeitos sonoros durante o jogo e reproduzir as músicas na tela de boas-vindas. Como o microcontrolador ATmega328 não possui um sintetizador de áudio dedicado, a geração de som e o controle das músicas são feitos diretamente por software e gerenciados por uma estrutura de dados armazenada na memória Flash.

## Funcionamento do Hardware e Emissão de Tons

O som é gerado através de um buzzer conectado fisicamente ao pino PD4 (pino 4 do PORTD). A emissão de som ocorre de forma manual através da alternância rápida do estado lógico desse pino. A função que gera os tons recebe dois parâmetros de entrada através dos registradores:
* Registrador temp: Define o atraso do meio período da onda quadrada. Valores menores fazem o pino oscilar mais rápido, gerando frequências mais agudas. Se o valor for 0, o sistema interpreta como uma pausa (silêncio).
* Registrador temp2: Define o total de ciclos de oscilação, controlando a duração de tempo que a nota permanece ativa.

O pino é configurado como saída, colocado em nível alto, espera pelo tempo definido, é colocado em nível baixo e aguarda o mesmo tempo. Depois do fim dos ciclos, o pino é reconfigurado como entrada para desativar o buzzer e evitar ruídos de fundo.

## Estrutura e Formato das Músicas na Flash

Convertemos as partituras digitais em tabelas de dados binários inseridas diretamente no código usando a diretiva .db (Define Byte). Cada nota musical dentro de uma música ocupa exatamente 2 bytes na memória Flash:
* Primeiro Byte (Tom): O valor numérico que determina a frequência (atraso do meio período).
* Segundo Byte (Duração): O número total de ciclos da nota.

O término de uma música é identificado pelo Marcador de Fim, que consiste em dois bytes zerados (.db 0, 0). Quando a rotina de leitura encontra esse padrão, ela reconhece que a trilha terminou.

## Gerenciamento e Seleção de Trilhas (player.asm)

Existem 5 opções de trilhas sonoras na memória do microcontrolador:
* Música 0: Ode to Joy (Beethoven)

* Música 1: Minuet in G (Christian Petzold)

* Música 2: Tema do Tetris 

* Música 3: Marcha Imperial (Star Wars)

* Música 4: Tema do Super Mario Bros

O índice da música ativa fica salvo na posição de memória RAM_CURRENT_TRACK. Quando o jogo está na tela de boas-vindas, a função Buzzer_Play_Current_Track lê essa variável e aponta o registrador de ponteiro Z (ZH:ZL) para o início da tabela correspondente na Flash usando a instrução lpm (Load Program Memory).

### Ajustes Específicos

* Modificação de Velocidade: Para ajustar o andamento do Minuet in G (Música 1), o código faz um cálculo matemático em tempo real. Ele divide a duração da nota por 4 utilizando deslocamentos lógicos para a direita (lsr) e soma o resultado ao valor original, reduzindo a velocidade da música em 25%.

* Controle de Pausas: A Ode to Joy (Música 0) executa uma pausa obrigatória de 30ms definida por ODE_TO_JOY_TEMPO_PAUSE entre cada nota. As outras músicas utilizam o bit 7 do byte de duração como um sinalizador: se o bit 7 estiver ativo, a pausa é ignorada e a próxima nota é tocada, criando um efeito de som contínuo.

## Botões e Concorrência

Para evitar que a reprodução da música trave o funcionamento do jogo e impeça a leitura dos comandos do usuário, o código divide a execução de cada nota em blocos menores. Ao invés de enviar a duração total da nota para a rotina do buzzer, o laço principal envia partes de no máximo 16 ciclos por vez. Entre a execução de uma parte e outro, a função chama a rotina Read_Buttons. Se o usuário pressionar qualquer botão, como o Botão Select para alternar a música ou os botões A/B para iniciar o jogo, o laço de reprodução intercepta o clique, interrompe a música atual e retorna o código do botão no registrador temp para a Máquina de Estados Finita (FSM) processar a mudança de estado do sistema.

## Efeitos Sonoros do Jogo

Além das músicas, o sistema tem quatro funções de efeitos sonoros pelas outras fases do jogo:

| Função | Comportamento | Contexto |
| :--- | :--- | :--- |
| `Buzzer_Tick` | Dispara um bipe curto de alta frequência. | Executado a cada avanço de casa durante o giro da roleta. |
| `Buzzer_Beep` | Emite um som padrão de confirmação. | Utilizado ao validar ações nos botões. |
| `Buzzer_Success` | Executa uma sequência rápida de 3 notas ascendentes (1 kHz, 1.3 kHz e 2 kHz). | Acionado na resolução da rodada quando o jogador ganha pontos. |
| `Buzzer_Failure` | Gera um zumbido grave contínuo de 400 Hz com duração aproximada de 300ms. | Acionado quando o jogador perde a aposta ou quando ocorre um erro. |