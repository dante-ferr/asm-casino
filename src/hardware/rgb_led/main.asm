; RGB LED driver (Red, Black/Blue, Green)
; Controls PD1 (Green), PD2 (Red), PD3 (Blue/Black)

; Turn off all channels of the RGB LED
RGB_Clear:
    cbi PORTD, RGB_GREEN
    cbi PORTD, RGB_RED
    cbi PORTD, RGB_BLACK
    ret

.include "hardware/rgb_led/color_mapping.asm"
.include "hardware/rgb_led/player_color.asm"
