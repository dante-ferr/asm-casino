```.asm
.org 0x0000
    rjmp RESET ; Handler de reset
.org OC0Aaddr ; Vetor de comparação A do Timer0
    rjmp TIMER0_ISR ; Handler de comparação A do Timer0
.org 0x0034 ; Fim dos vetores de interrupção
```
Garante que o ATMEGA328 pule direto para RESET, além de colocarmos para que, toda vez que uma interrupção for acionada através do Timer0, o microcontrolador pule para a rotina TIMER0_ISR.
# A função RESET faz as seguintes funções:
## Drivers:
1. Inicializa o ponteiro da pilha para o fim da SRAM (RAMEND).
2. Configura:
    a. PB0-PB5 como saídas
    b. PD1-PD3 e PD5-PD7 como saídas, PD4 como entrada
    c. PC1-PC3 
3. Desligas as saídas dos dois Displays (que estão em multiplexação).
4. Chama as rotinas de inicialização e limpeza do LCD, junto com a rotina de inicialização da Matriz de leds e a rotina de inicialização dos dados dos jogadores na SRAM.
5. Configura o Timer0:
    a. Coloca apenas o bit WGM01 (Waveform Generation Mode bit 1) ligado no TCCR0A (Timer/Counter 0 Control Register A). Isso ativa o CTC (Clear Timer on Compare) match A.
        Observação: foi utilizado somente o channel A. 
    b. Através da ativação do bit CS02 (Clock Select 02) do TCCR0B (Timer/Counter 0 Control Register B), divide-se os 16 MHz do processador por 256.
    c. O OCR0A (Output Compare Register 0A) assume o valor 124. Isso faz com que o Timer0 pare no 124 ao invés de 255.
    d. Por fim, a interrupção através do Timer 0 é habilitada por meio da ativação do bit OCIE0A(Output Compare Interruption Enable A bit 0) do registrador TIMSK0 (Timer 0 Mask).
    Ou seja, isso faz com que o Timer 0, utilizando o channel A, conte de 0 até 124 em 16MHz/256 e, ao atingir esse valor, faça a interrupção (habilitada através do bit OCIE0A do TIMSK0) e faça o valor do Timer 0 voltar para 0.
6. Configura o ADC:
    a. Através da ativação do bit REFS0 (Reference Select bit 0) do ADMUX (ADC Multiplexer Selection Register), a tensão de referência é configurada como sendo a tensão Vcc padrão (ou seja, 5V).
    b. Os bits ADEN (ADC Enable) e ADPS0, ADPS1 e ADPS2 (ADC Prescaler Select) do ADCSRA (ADC Control and Status Register A) são ativados, habilitando o ADC e dividindo a frequência do ADC pela opção 0b111 = 8 da tabela de divisores do chip, ou seja, escolhe-se a 8ª opção da tabela, que é 128.. Isso porque o ADC precisa estar na faixa entre 50 kHz e 200 kHz para operar de maneira segura: assim, a frequência de operação do ADC é 16 MHz/128 = 125 kHz. 
7. Configura o Timer 1 para gerar entropia no clock máximo (através da ativação do bit CS10 do TCCR1B).
## Lógica do jogo
1. Inicializa as variáveis que começam com RAM_PWM: RAM, pois fica armazenada na SRAM, e PWM porque vem de Pulse Width modulation. Essas variáveis servem para o Led RGB, pois não há, realmente, uma variação de intensidade. Ao invés disso, esses dispositivos são ativados e desativados muito rapidamente e em frequências tais que enganam o cérebro humano, fazendo-o acreditar estar vendo uma intensidade menor quando, na verdade, há períodos ativação numa intensidade fixa e outros sem ativação -- daí o nome.
    Configuração inicial das variáveis
    * RAM_PWM_COUNTER (0): Serve para contar as interrupções de 0 a 7 (módulo 8), servindo para ditar o _Duty Cycle_ do Soft_PWM para o LED RGB.
    * RAM_PWM_TICK (0): Quando esta variável atinge o valor 50, a animação dos displays de 7 segmentos e a configuração de cores do LED RGB são atualizados.
    * RAM_FADE_STATE (0): Guarda o estado de transição de cores do LED RGB.
    * RAM_PWM_GREEN (0), RAM_PWM_BLACK e RAM_PWM_RED(7): trabalham juntos para ditar os brilhos desejados de verde, azul (que representa os números pretos) e vermelho.
    * RAM_ROUND_NUM (0): Serve dois propósitos:
        a. guarda o número vencedor
        b. guarda o índice de frame, de 0 a 7, do segmento luminoso giratório durante a tela de boas-vindas.
    * RAM_BALL_IDX (0): Guarda o índice atual da posição da bolinha da roleta -- que fica girando pela borda da matriz de leds.
2. A matrix é inicializada
3. O Led RGB correspondente ao primeiro jogador é configurada.
4. Por fim, através da instrução sei, as interrupções globais são habilitadas.
# Main Loop
O jogo funciona como um autômato finito, então o fms_state é salvo através do RAM_FSM_STATE (que fica na SRAM). Após isso, através de várias verificações, ele obtém o estado atual e chama uma subrotina correspondente.
