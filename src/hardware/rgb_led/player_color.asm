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
