; Waits for a button to be pressed and then fully released
; Returns the pressed button code in temp
Wait_Button_Press:
    rcall Read_Buttons
    tst temp
    breq Wait_Button_Press
    
    push temp
    
    ; Debounce press: wait 20ms
    ldi temp, 20
    call delay_ms
    
wait_release:
    rcall Read_Buttons
    tst temp
    brne wait_release
    
    ; Debounce release: wait 20ms
    ldi temp, 20
    call delay_ms
    
    pop temp
    ret

