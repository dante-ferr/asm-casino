; Pseudo-Random Number Generator (PRNG) using hardware timer 1
; Returns a pseudo-random number 0-36 in temp2

PRNG_Spin:
    push temp
    lds temp2, TCNT1L       ; Read Timer 1 low byte (incrementing at 16MHz)
prng_mod_loop:
    cpi temp2, ROULETTE_SLOTS
    brlo prng_mod_done      ; If temp2 < ROULETTE_SLOTS, we have our modulo result
    subi temp2, ROULETTE_SLOTS
    rjmp prng_mod_loop
prng_mod_done:
    pop temp
    ret
