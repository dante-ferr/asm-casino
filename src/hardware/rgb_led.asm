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
    
    ; If number >= 37, ignore
    cpi temp, 37
    brsh rgb_done
    
    ; Load Z with color_table * 2 (Flash byte address)
    ldi ZL, low(color_table * 2)
    ldi ZH, high(color_table * 2)
    add ZL, temp
    clr temp
    adc ZH, temp
    
    lpm temp, Z             ; Load color type (0=Green, 1=Red, 2=Black)
    
    cpi temp, 0
    breq rgb_set_g
    cpi temp, 1
    breq rgb_set_r
    cpi temp, 2
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

; Lookup table for roulette number colors (0=Green, 1=Red, 2=Black)
color_table:
    .db 0, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2
    .db 1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 2, 1, 2
    .db 1, 2, 1, 2, 1, 0     ; padded to even length
