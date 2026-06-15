# Lógica de Giro e Resolução do Jogo

O sistema gerencia o sorteio do número vencedor, a execução das animações físicas da roleta e a contabilização financeira dos resultados por meio de estados específicos da máquina de estados principal. A interface fornece feedback visual imediato limpando e escrevendo dados no display LCD, animando a matriz, disparando efeitos sonoros de sucesso ou falha no buzzer, e atualizando dinamicamente o saldo dos jogadores na SRAM.

## Estrutura do Subsistema de Resolução

Os arquivos que controlam a animação da roleta, as regras de pontuação e as strings de resultado estão localizados em src/game/resolution/:

* main.asm: Contém a lógica dos possíveis resultados de uma aposta, ativação do buzzer e do LCD, usando as strings em strings.asm
* spin_seq.asm: Implementa a sequência de animação visual do giro da roleta na matriz de LEDs e o cálculo do atrito simulado.
* rules.asm: Contém a lógica de verificação de apostas (vencedora/perdedora) e a aplicação matemática das regras de pagamento e prisão (*En Prison*).
* strings.asm: Armazena as mensagens de texto exibidas no LCD durante a rotação e a revelação dos resultados individuais de cada jogador.

## Detalhamento das Rotinas e Estados

### Giro da Roleta (STATE_SPIN_ROULET)

#### Run_Spin_Roulette

* Funcionamento:
    1. Limpa o display LCD e posiciona o cursor no início da linha 0 para imprimir a string msg_spinning ("Girando roleta.").
    2. Invoca a subrotina modular Run_Roulette_Spin_Sequence. Esta rotina realiza o sorteio, faz a animação e salva o número final sorteado no registrador temp2 e na variável global de rodada.
    3. Transiciona o registrador de controle da FSM global para o estado de avaliação financeira (STATE_RESOLUTION).



#### Run_Roulette_Spin_Sequence

* Funcionamento:
    1. Invoca o gerador de números pseudoaleatórios do sistema através da rotina PRNG_Spin para sortear o índice do slot vencedor (um valor contido entre 0 e 36) e o copia para o registrador r22.
    2. Calcula a quantidade total de passos mecânicos que a animação deve executar somando uma constante de voltas inteiras (SPIN_BASE_STEPS) ao índice do slot sorteado, armazenando o contador decrescente em r23.
    3. Entra em um loop de animação (spin_anim_loop) incremental que lê o caractere/número correspondente ao slot corrente da roleta, acionando os registradores de deslocamento para rotacionar o LED aceso na matriz.
    4. A cada iteração, chama a subrotina get_friction_delay que avalia os passos restantes em temp e devolve um tempo de atraso progressivamente maior em milissegundos (simulando a perda de velocidade por atrito).
    5. Salva o número final sorteado na variável física RAM_ROUND_NUM e retorna este mesmo valor no registrador temp2.



### Resolução da Rodada (STATE_RESOLUTION)

#### Run_Resolution

* Funcionamento:
    1. Força o reset do ponteiro de turnos inicializando o registrador active_plyr = 1 (Jogador 1).
    2. Entra no laço de conferência (resolution_plyr_loop) e invoca Player_Get_Pointer para apontar o registrador Z para a ficha de 16 bytes do jogador corrente na SRAM.
    3. Faz uma cópia de segurança na Pilha (Stack) de todos os parâmetros originais da aposta (Status Z+2, Tipo Z+3, Alvo Z+4 e Valor de 16 bits Z+5:Z+6) antes que o processador lógico os limpe.
    4. Chama a rotina central Calculate_Payout para processar matematicamente as regras do jogo e atualizar permanentemente os saldos e o byte of status na SRAM.
    5. Recupera os valores originais salvos na pilha e atualiza o display LCD com base em estruturas condicionais ramificadas:
        * Sem Aposta: Se o valor original da aposta for igual a zero, imprime a string msg_p_passed (" NAO JOGOU") ao lado do identificador "P[ID]".
        * Vitória Normal: Dispara o aviso acústico de vitória (Buzzer_Success), anexa o prefixo msg_p_won_prefix (" GANHOU! +") e calcula o montante ganho em tempo de execução (multiplicando o valor apostado por 35 se for aposta Interna, ou aplicando o multiplicador de 1x ou 2x se for Externa/Dúzia/Coluna).
        * Derrota Normal: Dispara o aviso de erro (Buzzer_Failure), anexa o prefixo msg_p_lost_prefix (" PERDEU! -") e exibe o valor integral que foi deduzido.
        * Entrada na Prisão: Se o jogador não estava preso mas o bit 0 do status foi ativado nesta rodada, exibe a string msg_p_went_prison (" VAI P/ PRISAO!").
        * Saída da Prisão (Libertado): Se o jogador já iniciou a rodada preso e sua aposta condicional foi vencedora, emite o som de sucesso e exibe msg_p_win_ext (" LIBERADO!+").
        * Perda na Prisão: Se o jogador já estava preso e errou a previsão de escape, emite o som de falha e exibe msg_p_lost_prison (" PERDEU PRISAO").


    6. Posiciona o cursor na linha 1 do LCD para renderizar o rótulo msg_novo_bal ("Novo Bal: ") seguido pelo saldo financeiro atualizado em tempo real obtido via Player_Get_Balance.
    7. Inicia um loop de atraso controlado pela constante RESULT_DELAY_COUNT multiplicada por chamadas estáveis de delay_ms(250) para assegurar que os usuários consigam ler confortavelmente os seus resultados na tela antes que o sistema mude de turno.
    8. Incrementa active_plyr e o compara com a quantidade total de competidores registrados em RAM_NUM_PLAYERS. Se houver mais jogadores, o fluxo salta de volta para o topo do laço; caso contrário, reinicializa active_plyr = 1 e devolve o estado da FSM para o Menu Principal (STATE_MAIN_MENU).



#### Calculate_Payout


* Funcionamento:
    1. Carrega o endereço base do jogador ativo no registrador Z e inspeciona o byte de status (Z+2). Se o Bit 0 estiver setado, desvia imediatamente o fluxo de processing para a subrotina isolada de custódia (resolution_prison).
    2. No fluxo de resolução padrão, carrega o valor da aposta de 16 bits (Z+5:Z+6). Se o resultado da operação lógica OR entre a parte alta e baixa for zero, a rotina aborta a execução saltando para o encerramento por ausência de fundos em jogo.
    3. Puxa o número vencedor de RAM_ROUND_NUM e invoca a função Check_Bet_Win. A função analisa os limites geométricos da roleta e retorna temp = 1 para vitória ou temp = 0 para derrota.
    4. Em caso de Vitória: Multiplica o valor investido pelo multiplicador regulamentar da mesa (35 vezes para números exatos na seção interna; ou 1 para chances simples externas e 2 para dúzias/colunas na seção externa). Soma o prêmio calculado ao saldo do jogador através de instruções de adição com transporte (add / adc) e salva na SRAM.
    5. Em caso de Derrota: Avalia uma regra especial da Roleta Francesa. Se a aposta realizada foi do tipo Externa de chance simples (como as cores Vermelho/Azul, as paridades Par/Ímpar ou as metades Baixo/Alto) E o número sorteado pela roleta foi o Zero (0), a penalidade de perda total é suspensa. Em vez disso, o sistema ativa o bit de confinamento (Bit 0 do status Z+2), confiscando temporariamente o valor que fica retido na mesa. Caso a derrota ocorra em qualquer outra condição, o saldo é decrementado normalmente.
    6. Limpeza de Turno: Exceto nos casos em que o jogador é enviado para a prisão (onde os valores devem ficar travados para a próxima rodada), limpa os bytes de Tipo (Z+3), Alvo (Z+4) e Valor da Aposta (Z+5:Z+6) gravando zero nesses endereços da SRAM, deixando a ficha limpa para o próximo ciclo de apostas.