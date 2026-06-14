# Máquina de Estados Finita (FSM)

Gerenciamos o fluxo operacional do jogo no loop principal (MAIN_LOOP) do arquivo [src/main.asm](../../src/main.asm), que atua como o controlador de estados do sistema. Para isso, utilizamos o registrador r20 como a variável global de controle (fsm_state).

## Detalhamento Técnico dos Estados Lógicos

### STATE_WELCOME (9)
* Finalidade: Tela de abertura e apresentação do sistema da roleta.
* Comportamento: Toca músicas selecionadas e rotaciona LEDs na borda da matriz e nos displays de 7 segmentos.
* Transição: Clicar em qualquer botão válido (A ou B) desvia o fluxo para a tela de jogadores. Pressionar Select apenas alterna a música e reinicia a melodia.

### STATE_NUM_PLAYERS (8)
* Finalidade: Menu de seleção de quantidade de jogadores participantes.
* Comportamento: Permite configurar de 1 a 4 jogadores utilizando os botões A e B e exibe o ícone de grupo na matriz.
* Transição: Ao pressionar Select, o número é salvo na variável RAM_NUM_PLAYERS e a FSM transiciona para o Menu Principal.

### STATE_MAIN_MENU (0)
* Finalidade: Menu Principal de controle da partida.
* Comportamento: Mostra o ID do jogador ativo e seu saldo correspondente no LCD, além de sincronizar a cor do LED RGB e o display de 7 segmentos.
* Transição:
  * Botão A: Cicla o ID do jogador ativo.
  * Botão B: Desvia para a configuração de saldo (STATE_SET_CREDITS).
  * Botão Select: Entra na rodada de apostas (STATE_CHOOSE_CAT) definindo active_plyr = 1.

### STATE_SET_CREDITS (7)
* Finalidade: Permite ajustar ou adicionar fundos para um jogador.
* Comportamento: Incrementa ou decrementa o saldo do jogador ativo em passos de 100 pontos pelos botões A/B.
* Transição: O botão Select salva o novo saldo no registro SRAM e retorna ao Menu Principal.

### STATE_CHOOSE_CAT (1)
* Finalidade: Rotina de seleção de aposta individual.
* Comportamento: Gerencia a navegação entre alvos de aposta, montagem de valores em passos de 100 e validação.
* Transição: Depois de o último jogador confirmar a aposta:
  * Se houver apostas registradas, transiciona para o giro (STATE_SPIN_ROULET).
  * Se não houver apostas, mostra um erro e retorna ao Menu Principal (STATE_MAIN_MENU).

### STATE_SPIN_ROULET (4)
* Finalidade: Execução da animação e simulação física da roleta.
* Comportamento: Bloqueia a CPU para processamento de entrada de usuário, realiza a trajetória circular da bolinha na matriz de LEDs, atualiza as telas e RGB e desacelera com uma simulação de atrito para dar o aspecto de que a roleta está parando.
* Transição: Ao parar a roleta, chama PRNG_Spin para validar o número vencedor final e transiciona para a resolução.

### STATE_RESOLUTION (5)
* Finalidade: Fase de verificação e contabilidade matemática de saldo.
* Comportamento: Compara as apostas registradas de cada jogador contra as regras, calcula ganhos ou aprisionamento de fundos (*En Prison*), exibe mensagens explicativas e atualiza a SRAM.
* Transição: Após a vez do último jogador, limpa os campos temporários de apostas e retorna ao Menu Principal.

## Estados Adicionais Reservados

* STATE_CHOOSE_BET (2) / STATE_CONFIRM_BET (3): Separam o momento em que o jogador escolhe o valor do momento em que ele confirma a aposta, facilitando a organização das funções no código.
* STATE_EN_PRISON (6): Controla a regra especial de "prisão" da roleta francesa, bloqueando os botões da interface enquanto as apostas simples ficam retidas para a próxima rodada.