# Guia de Utilização (Funcionamento do Jogo)

O fluxo de execução do ASM Casino é gerenciado por uma Máquina de Estados Finita (FSM) implementada em AVR Assembly com fases que guiam os jogadores da inicialização do circuito até a resolução de suas apostas. Abaixo está o manual completo de operação.


## Tela de Boas-Vindas e Seleção Musical
Ao ligar ou resetar o microcontrolador, o jogo inicia no estado de boas-vindas:
* Display LCD: Exibe o título "Roleta Francesa".
* Matriz de LEDs 8x8: Inicia uma animação contínua da bolinha percorrendo a borda circular da matriz.
* Buzzer: Reproduz em loop a trilha sonora selecionada.
* Displays de 7 Segmentos: Apresentam uma animação de rotação com um único segmento aceso girando.
* LED RGB: Executa um efeito de transição de cores alternando o brilho suavemente.

### Comandos Disponíveis:
* Botão Select: Interrompe a reprodução e alterna a trilha sonora ativa (cicla entre as 5 músicas disponíveis na Flash):
  * Track 0: Ode to Joy (Beethoven)
  * Track 1: Minuet in G (Bach)
  * Track 2: Tetris Theme (Korobeiniki)
  * Track 3: Star Wars (Imperial March)
  * Track 4: Super Mario Bros Theme
* Botões A ou B: Interrompem a música e avançam para a configuração de participantes.


## Configuração do Número de Jogadores
Nesta fase, definimos a quantidade de pessoas que irão participar da partida:
* Matriz de LEDs: Exibe um ícone que representa um grupo de pessoas.
* Display LCD: Apresenta a mensagem "Qtd Jogadores:" e o número de jogadores atual na linha inferior.
* Displays de 7 Segmentos: Continuam com a animação de rotação rápida.
* LED RGB: Continua com o efeito de fade de cores.

### Comandos Disponíveis:
* Botão A (Voltar/Próximo): Decrementa a quantidade de jogadores (limite mínimo de 1). Caso seja menor que 1, retorna para 4.
* Botão B (Soma/Créditos): Incrementa a quantidade de jogadores (limite máximo de 4). Caso seja maior que 4, retorna para 1.
* Botão Select: Confirma o número mostrado no display e avança para o Painel Principal.


## Painel Principal (Saldos)
É o ponto de controle central do jogo. Cada jogador tem um bloco de memória individual para armazenar seus dados:
* Matriz de LEDs: Apresenta o ícone de avatar de usuário.
* Displays de 7 Segmentos: Mostram o número do jogador ativo no formato de dezenas e unidades (ex: 01, 02, 03, 04).
* LED RGB: Assume uma cor fixa correspondente ao jogador ativo:
  * Jogador 1: Vermelho
  * Jogador 2: Azul
  * Jogador 3: Verde
  * Jogador 4: Amarelo (Vermelho + Verde acesos)
* Display LCD: Mostra o número identificador do jogador atual e seu saldo de crédito, que começa com 1000 pontos. Se o jogador estiver no estado especial "En Prison", um indicador "(P)" é mostrado do lado do ID.

### Comandos Disponíveis:
* Botão A: Cicla e altera o jogador ativo na tela (entre 1 e a quantidade selecionada).
* Botão B: Abre a tela de Ajuste de Créditos do jogador ativo.
* Botão Select: Confirma o jogador ativo e vai para a Fase de Apostas do Jogador 1.


## Configuração de Créditos
Permite ajustar manualmente o saldo de créditos do jogador atual antes de fazer as apostas:
* Matriz de LEDs: Exibe o ícone de um cifrão "$".
* Display LCD: Apresenta o número do jogador e o seu saldo ajustável.

### Comandos Disponíveis:
* Botão A: Subtrai 100 pontos de saldo (com limite inferior de 0).
* Botão B: Adiciona 100 pontos de saldo (com limite superior de 9900).
* Botão Select: Salva o novo saldo na memória SRAM e retorna ao Painel Principal.


## Fase de Apostas
Quando o botão Select é pressionado no Painel Principal e a Fase de Apostas é iniciada, o sistema exige que todos os jogadores de 1 até a quantidade definida escolham suas apostas sequencialmente.
* Matriz de LEDs: Exibe um ícone de ponto de interrogação "?".
* LED RGB e Displays de 7 Segmentos: Continuam identificando qual jogador está apostando no momento.

Cada jogador passa por até 3 modos de configuração da sua aposta:

### Modo 0: Escolha do Alvo 
Neste modo, o jogador escolhe em qual casa ou categoria da roleta quer apostar. O display mostra um indicador "<<" ao lado do alvo.
* É possível, através dos botões A ou B, navegar entre os 49 alvos disponíveis:
  * 0 a 5 (Externas de dinheiro par): VERMELHO, AZUL (Preto), PAR, IMPAR, BAIXO (1-18), ALTO (19-36).
  * 6 a 11 (Externas de dúzia/coluna): 1a DUZIA (1-12), 2a DUZIA (13-24), 3a DUZIA (25-36), 1a COLUNA, 2a COLUNA, 3a COLUNA.
  * 12 a 48 (Internas de número exato): Números 0 a 36.
* Pressionando o botão Select, o alvo é salvo e avançamos para a escolha do valor.

### Modo 1: Escolha do Valor
Neste modo, o display mostra o cursor "<<" ao lado do valor da aposta.
* Botão A: subtrai 100 pontos da aposta (mínimo de 0).
* Botão B: adicionar 100 pontos ao valor a ser apostado. O sistema impede que a aposta ultrapasse o saldo de créditos disponível no jogador.
* Botão Select: salva o valor e avança para a confirmação.

### Modo 2: Confirmação da Aposta
O display exibe a mensagem de confirmação "Conf: SIM" ou "Conf: VOLTAR".
* Botão A ou B: alterna a opção entre SIM (para confirmar e avançar) e VOLTAR (para corrigir a aposta).
* Botão Select: confirma a ação.
  * Se selecionado VOLTAR: A FSM retorna ao Modo 0 para que você edite novamente.
  * Se selecionado SIM: O valor apostado é descontado do saldo do jogador na SRAM, a estrutura de aposta é salva e o turno passa para o próximo jogador colocar sua aposta.

### Caso Especial: Jogador em Prisão ("En Prison")
Se o jogador ativo iniciar seu turno no estado especial "En Prison", devido a um zero sorteado na rodada anterior em uma aposta externa simples:
* O teclado analógico é desativado para edição de alvos ou valores.
* O display LCD exibe travado: "P[ID]: PRISAO" e o valor da aposta aprisionada.
* A única ação possível é pressionar Select para validar o turno. O valor aprisionado continua retido, e o turno de apostas passa para o próximo jogador.

### Erro: Sem Apostas na Mesa
Se após a rodada de apostas de todos os jogadores, nenhuma aposta válida maior do que zero tiver sido registrada, a roleta se recusa a girar. O LCD exibirá "Erro: Sem Aposta", o buzzer tocará o som de erro, e após 4 segundos o jogo retornará automaticamente para o Painel Principal.


## Giro Físico e Desaceleração
Se pelo menos uma aposta válida tiver sido registrada, o sistema avança para a animação do giro da roleta:
* Display LCD: Mostra a mensagem "Girando roleta.".
* Matriz de LEDs: Uma bolinha acesa percorre os 20 LEDs da borda externa no sentido horário, simulando um giro.
* Buzzer: Emite um clique rápido a cada passo da bolinha.
* Displays de 7 Segmentos: Mudam rapidamente em sincronia, mostrando por qual número a bola está passando.
* LED RGB: Muda de forma síncrona, exibindo a cor da casa correspondente na roleta (Verde para 0, Vermelho para vermelhos, Azul para pretos).
* Física do atrito: À medida que a animação avança, o intervalo de delay entre os passos aumenta gradualmente (de 10ms até 250ms), simulando a perda de velocidade, até o número ser sorteado. A bolinha para na posição correspondente do número sorteado pelo PRNG.


## Resolução da Rodada e Payouts
Ao parar a roleta, o sistema calcula os resultados individuais de cada jogador sequencialmente:
1. O display indica o número do jogador analisado na linha 0.
2. O LED RGB mostra a cor da casa sorteada e os displays de 7 segmentos mostram o número vencedor.
3. O buzzer emite a melodia correspondente:
   * Melodia de Sucesso (3 notas agudas crescentes): Se o jogador ganhar a aposta.
   * Melodia de Falha (tom grave arrastado): Se o jogador perder a aposta.
4. O LCD mostra o resultado específico:
   * "NAO JOGOU": O jogador não realizou nenhuma aposta na rodada (passou o turno).
   * "GANHOU! +[Valor]": O jogador venceu a aposta. O saldo é recalculado aplicando o multiplicador da aposta e o prêmio é somado ao saldo na SRAM.
   * "PERDEU! -[Valor]": A aposta normal foi perdida. Como o valor foi debitado no início, nenhuma alteração é feita.
   * "VAI P/ PRISAO!": O jogador possuía uma aposta externa de dinheiro par ativa e o número sorteado foi o zero. A aposta foi aprisionada pela banca e sua flag de prisão ativada ("En Prison").
   * "LIBERADO! +[Valor]": O jogador estava sob a regra "En Prison", girou a roleta, e seu palpite preso foi sorteado. O valor retido é devolvido ao saldo do jogador.
   * "PERDEU PRISAO": O jogador sob a regra "En Prison" errou o giro de resolução ou saiu o número zero de novo. O saldo aprisionado é recolhido.
5. A linha 1 exibe "Novo Bal: [Saldo]" com o saldo atualizado.
6. O sistema aguarda 3,5 segundos (delay de leitura) e passa para a resolução do próximo jogador participante.
7. Depois de processar todos os jogadores, a FSM redefine as apostas temporárias na SRAM para zero e retorna ao Painel Principal para iniciar uma nova rodada.