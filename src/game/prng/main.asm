; Gerador de números pseudoaleatórios (PRNG) usando o timer 1 do hardware
; Retorna um número pseudoaleatório de 0 a 36 em temp2

PRNG_Spin:
    push temp
    lds temp2, TCNT1L ; lê o byte baixo do Timer 1 (incrementa a 16MHz)
prng_mod_loop:
    cpi temp2, ROULETTE_SLOTS
    brlo prng_mod_done ; se temp2 for menor que as posições da roleta, encerra o cálculo do resto
    subi temp2, ROULETTE_SLOTS
    rjmp prng_mod_loop
prng_mod_done:
    pop temp
    ret
