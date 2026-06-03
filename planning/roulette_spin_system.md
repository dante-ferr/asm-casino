# Especificação Técnica: Sistema de Giro Sincronizado da Roleta

Este documento descreve o funcionamento técnico do módulo de giro sincronizado (`roulette_spin.asm`), detalhando o mapeamento físico da roleta e a sincronização síncrona dos periféricos durante a simulação no SimulIDE.

---

## 1. Sequência Numérica da Roleta Real (Layout Europeu/Francês)

A roleta francesa possui 37 casas, numeradas de 0 a 36. A ordem física dos números no prato da roleta (no sentido horário) é a seguinte:

| Índice do Slot ($S$) | Número na Roleta ($N$) | Cor do Número ($C$) |
|:-------------------:|:---------------------:|:-------------------:|
| 0 | 0 | Verde |
| 1 | 32 | Vermelho |
| 2 | 15 | Preto |
| 3 | 19 | Vermelho |
| 4 | 4 | Preto |
| 5 | 21 | Vermelho |
| 6 | 2 | Preto |
| 7 | 25 | Vermelho |
| 8 | 17 | Preto |
| 9 | 34 | Vermelho |
| 10 | 6 | Preto |
| 11 | 27 | Vermelho |
| 12 | 13 | Preto |
| 13 | 36 | Vermelho |
| 14 | 11 | Preto |
| 15 | 30 | Vermelho |
| 16 | 8 | Preto |
| 17 | 23 | Vermelho |
| 18 | 10 | Preto |
| 19 | 5 | Vermelho |
| 20 | 24 | Preto |
| 21 | 16 | Vermelho |
| 22 | 33 | Preto |
| 23 | 1 | Vermelho |
| 24 | 20 | Preto |
| 25 | 14 | Vermelho |
| 26 | 31 | Preto |
| 27 | 9 | Vermelho |
| 28 | 22 | Preto |
| 29 | 18 | Vermelho |
| 30 | 29 | Preto |
| 31 | 7 | Vermelho |
| 32 | 28 | Preto |
| 33 | 12 | Vermelho |
| 34 | 35 | Preto |
| 35 | 3 | Vermelho |
| 36 | 26 | Preto |

---

## 2. Mapeamento Matemático para a Matriz de 20 LEDs

Dado que a matriz de LEDs possui uma borda externa circular composta por apenas 20 LEDs físicos (mapeados de `0` a `19` no arquivo `max7219.asm`), precisamos projetar o slot físico atual da roleta $S \in [0, 36]$ para o índice do LED correspondente $L \in [0, 19]$.

A fórmula matemática linear utilizada é:
$$L = \left( \left\lfloor \frac{S \times 20}{37} \right\rfloor + 3 \right) \bmod 20$$

O offset de $+3$ (com wrap-around em $\bmod 20$) é aplicado para ancorar o slot $0$ (número $0$) na posição física do topo (12 horas / 12 o'clock), que corresponde ao LED índice $3$ na matriz. Isso alinha perfeitamente os quatro quadrantes do prato da roleta real com os eixos da matriz de LEDs:
*   **Slot 0** (número 0) $\rightarrow$ LED 3 (12 horas - topo)
*   **Slot 9** (número 34) $\rightarrow$ LED 7 (3 horas - direita)
*   **Slot 18** (número 10) $\rightarrow$ LED 12 (6 horas - baixo)
*   **Slot 27** (número 9) $\rightarrow$ LED 17 (9 horas - esquerda)

Em código assembly, implementamos este cálculo multiplicando o slot $S$ por 20, dividindo o resultado por 37 via subtrações sucessivas, somando 3 e aplicando o limite circular de 20.

---

## 3. Sincronização Síncrona dos Periféricos

Durante cada passo da animação de giro com atrito (friction deceleration), os seguintes periféricos são atualizados síncronamente:

1. **Displays de 7 Segmentos**: A variável global `RAM_ROUND_NUM` é atualizada com o valor da tabela `Wheel[S]`. O Timer 0, rodando em background (ISR de multiplexação), lê essa variável e atualiza os displays imediatamente.
2. **LED RGB**: O valor de `Wheel[S]` é passado para o driver do LED RGB, acendendo em tempo real a cor correspondente (PD1 para verde, PD2 para vermelho, PD3 para preto/azul).
3. **Matriz de LEDs 8x8**: A bolinha externa é desenhada na posição $L$ correspondente ao slot físico $S$. O centro permanece com os 4 leds acesos estaticamente.
4. **Buzzer**: O pino PD4 é chaveado rapidamente para emitir um bipe curto (`Buzzer_Tick`), criando o som característico da bolinha batendo nos pinos da roleta real.
5. **Decadência do Atraso (Friction)**: A duração do atraso do passo é gradualmente incrementada, desacelerando a roleta de forma suave até parar no número sorteado.
