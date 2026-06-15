# API: Módulo Principal

Ponto de entrada e fluxo de controle principal do programa, localizados em [src/main.asm](../../../src/main.asm).

---

- RESET
  - Entrada: Nenhuma (acionado direto pelo hardware no boot).
  - Saída: Nenhuma.
  - Registradores alterados: r16 (temp) e r17 (temp2).
  - Descrição: Rotina de inicialização executada assim que o microcontrolador liga. Ela configura o ponteiro de pilha (SPL e SPH), define as direções de entrada/saída dos pinos nos registradores DDRB, DDRD e DDRC, e inicia o LCD e a matriz de LEDs. Também limpa a memória RAM associada aos jogadores, configura o Timer 0 para gerar a interrupção de multiplexação (a cada 2ms), liga o ADC para ler os botões, inicia o Timer 1 (usado para gerar entropia no gerador de números aleatórios), inicializa as variáveis globais e, por fim, libera as interrupções globais com a instrução sei.

- MAIN_LOOP
  - Entrada: fsm_state (r20).
  - Saída: Nenhuma (é um loop infinito).
  - Registradores alterados: Depende de qual estado for chamado.
  - Descrição: É o loop principal da máquina de estados (FSM). Ele fica verificando constantemente o valor de fsm_state e desvia o fluxo de execução para a função correspondente ao estado atual (como Run_Welcome, Run_Main_Menu, Run_Choose_Cat, Run_Confirm_Bet, Run_Spin_Roulette, Run_Resolution, Run_Num_Players, Run_Set_Credits, entre outras).
