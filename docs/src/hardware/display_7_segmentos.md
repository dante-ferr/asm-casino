# Rotina ISR e o display de 7 Segmentos
O código é basicamente a função TIMER0_ISR. Neste projeto, foram usados dois displays com multiplexação.
No começo, ela verifica se o jogo está no estado de seleção de jogadores ou boas-vindas: este roda o soft PWM (Pulse Width Modulation) e a animação, enquanto aquele faz escrever o número do jogador através dos displays. Se estiver em algum dos estados, o microprocessador irá executar isr_player_sel, caso contrário irá para isr_normal_seg.
## isr_player_sel
Para controlar as quantidades de vermelho, verde e azul do RGB, o RAM_PWM_COUNTER conta de 0 até 7 e, para cada um desses valores assumidos, compara-se com os valores RAM_PWM_RED, RAM_PWM_GREEN e RAM_PWM_BLACK (aqui está black, pois a ideia é que o azul faz o papel do preto). Assim, durante o ciclo de contagem do RAM_PWM_COUNTER, é possível controlar, ao invés da intensidade do RGB, a largura do pulso (_Duty Cycle_) com que os sinais de Vermelho, Verde e Azul são ativados.
Os valores de RAM_PWM_RED, RAM_PWM_GREEN e RAM_PWM_BLACK são atualizados a cada 50 interrupções (ou seja, 100ms). Por fim, há uma transição suave de cores:
* Estado 0: Diminui gradativamente o vermelho em favor do azul. Acaba quando aquele chega a 0.
* Estado 1: Diminui o Azul em favor do verde, acabando quando aquele torna-se 0.
* Estado 2: Diminui o verde em favor do vermelho. Acaba quando este chega a 0, passando para o Estado 0.

## isr_anim_render
Esta função renderiza, de forma multiplexada, a animação no displayda casa das dezenas e unidades, respectivamente. Para tal, as tabelas anim_table_portb_left e anim_table_portd_left são usadas pela casa das dezenas e anim_table_portb_right e anim_table_portd_right são usadas pelas unidades.

## isr_normal_seg
Imprime o valor escrito em RAM_ROUND_NUM nos dois displays de forma multiplexada através das tabelas table_portd e table_portb, utilizando subtrações sucessivas para a separação das casas das unidades das dezenas. 
