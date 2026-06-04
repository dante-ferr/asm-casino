; Analog keyboard driver using ADC0 (pin PC0) with a resistor ladder
; Detects three buttons: Button A (Next), Button B (History), and Select

.include "hardware/adc_buttons/read.asm"
.include "hardware/adc_buttons/wait.asm"
