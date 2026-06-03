; 7-segment display multiplexed driver

TIMER0_ISR:
    ; Timer 0 ISR for multiplexing 7-segment displays (runs every 2ms)
    push temp
    in temp, SREG
    push temp

    ; TODO: Implement cathode switching and segment loading logic

    pop temp
    out SREG, temp
    pop temp
    reti
