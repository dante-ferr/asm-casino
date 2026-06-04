; RGB LED driver (Red, Black/Blue, Green)
; Controls PD1 (Green), PD2 (Red), PD3 (Blue/Black)

; Turn off all channels of the RGB LED
RGB_Clear:
    cbi PORTD, RGB_GREEN
    cbi PORTD, RGB_RED
    cbi PORTD, RGB_BLACK
    ret

; Set RGB LED according to roulette number in temp (0-36)
; Inputs:
;   temp = drawn number (0-36)
RGB_Set_By_Number:
    push temp
    push ZL
    push ZH
    
    ; Clear current color first
    rcall RGB_Clear
    
    ; If number >= ROULETTE_SLOTS, ignore
    cpi temp, ROULETTE_SLOTS
    brsh rgb_done
    
    ; Load Z with color_table * 2 (Flash byte address)
    ldi ZL, low(color_table * 2)
    ldi ZH, high(color_table * 2)
    add ZL, temp
    clr temp
    adc ZH, temp
    
    lpm temp, Z             ; Load color type (COLOR_GREEN, COLOR_RED, COLOR_BLACK)
    
    cpi temp, COLOR_GREEN
    breq rgb_set_g
    cpi temp, COLOR_RED
    breq rgb_set_r
    cpi temp, COLOR_BLACK
    breq rgb_set_b
    rjmp rgb_done
    
rgb_set_g:
    sbi PORTD, RGB_GREEN
    rjmp rgb_done
rgb_set_r:
    sbi PORTD, RGB_RED
    rjmp rgb_done
rgb_set_b:
    sbi PORTD, RGB_BLACK
    
rgb_done:
    pop ZH
    pop ZL
    pop temp
    ret

; Lookup table for roulette number colors
color_table:
    .db COLOR_GREEN, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK
    .db COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_BLACK, COLOR_RED, COLOR_BLACK
    .db COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_BLACK, COLOR_RED, COLOR_GREEN     ; padded to even length

; Set RGB LED color according to active player (1 to 4)
; Inputs:
;   temp = active_plyr (1 to 4)
; Colors:
;   P1: Red
;   P2: Blue (mapped to RGB_BLACK pin)
;   P3: Green
;   P4: Yellow (Red + Green)
RGB_Set_By_Player:
    push temp
    
    rcall RGB_Clear
    
    cpi temp, 1
    breq set_p1_color
    cpi temp, 2
    breq set_p2_color
    cpi temp, 3
    breq set_p3_color
    cpi temp, 4
    breq set_p4_color
    rjmp rgb_plyr_done
    
set_p1_color:
    sbi PORTD, RGB_RED
    rjmp rgb_plyr_done
set_p2_color:
    sbi PORTD, RGB_BLACK
    rjmp rgb_plyr_done
set_p3_color:
    sbi PORTD, RGB_GREEN
    rjmp rgb_plyr_done
set_p4_color:
    sbi PORTD, RGB_RED
    sbi PORTD, RGB_GREEN
    
rgb_plyr_done:
    pop temp
    ret
