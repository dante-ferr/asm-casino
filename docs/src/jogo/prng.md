# Gerador de Números Pseudoaleatórios

A natureza aleatória dos resultados da roleta desse circuito provem de um gerador de números pseudoaleatórios por meio de um timer implementado no próprio hardware do ATmega328P.

---
### `src`
Na inicialização do programa no arquivo [main.asm](../../../src/main.asm), o registrador B de configuração do timer1 `TCCR1B`, o qual é responsável pela velocidade do timer1, é configurado de tal maneira:
```
ldi temp, (1 << CS10)
sts TCCR1B, temp
```
`CS10` guarda a posição em offset (`.equ CS10 = 0` em m328pdef.inc) do bit Clock Select 10 do `TCCR1B`, cujo é um dos bits que controlam a velocidade do timer1. Assim, carrega-se `0b00000001` em `temp` e, em seguida, configura `TCCR1B` com `temp`, tornando `1` o bit Clock Select 10.

Isso permite que o timer1 conte sem prescaler, em toda sua completude de 16MHz. A velocidade e natureza cáotica do timer1 proporciona uma geração pseudoaleatória de números ao ler os bits iniciais do contador do timer1.

---

### `src/game/prng`

O arquivo [main.asm](../../../src/game/prng/main.asm) lida com a lógica da geração dos números. 

A subrotina `PRNG_Spin` lê o byte baixo do timer1 (`TCNT1L`) e guarda em `temp2`. Em seguida, a subrotina `prng_mod_loop` garante que o número em temp2 seja um número da roleta válido, entre `1` e `36`, por meio da instrução `subi` e um loop contido pela instrução `brlo`.
```
prng_mod_loop:
    cpi temp2, ROULETTE_SLOTS
    brlo prng_mod_done
    subi temp2, ROULETTE_SLOTS
    rjmp prng_mod_loop
```
Em que `ROULETTE_SLOTS` é `.equ ROULETTE_SLOTS = 37`. Por fim, `prng_mod_done` retorna.