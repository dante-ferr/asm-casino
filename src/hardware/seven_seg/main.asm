; Driver multiplexado de display de 7 segmentos
; Usa PORTD (PD5-PD7) para os segmentos A, B, C
; Usa PORTB (PB0-PB3) para os segmentos D, E, F, G
; Usa PB4 para o cátodo das dezenas e PB5 para o cátodo das unidades

.include "hardware/seven_seg/isr.asm"
.include "hardware/seven_seg/tables.asm"
