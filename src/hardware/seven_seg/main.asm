; 7-segment display multiplexed driver
; Uses PORTD (PD5-PD7) for segments A, B, C
; Uses PORTB (PB0-PB3) for segments D, E, F, G
; Uses PB4 for Tens digit cathode and PB5 for Units digit cathode

.include "hardware/seven_seg/isr.asm"
.include "hardware/seven_seg/tables.asm"
