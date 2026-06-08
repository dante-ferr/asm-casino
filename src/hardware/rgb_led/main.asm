; Driver do LED RGB (Vermelho, Preto/Azul, Verde)
; Controla os pinos PD1 (Verde), PD2 (Vermelho), PD3 (Azul/Preto)

; Apaga todas as cores do LED RGB
RGB_Clear:
    cbi PORTD, RGB_GREEN
    cbi PORTD, RGB_RED
    cbi PORTD, RGB_BLACK
    ret

.include "hardware/rgb_led/color_mapping.asm"
.include "hardware/rgb_led/player_color.asm"
