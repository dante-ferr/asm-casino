; Waits for a button to be pressed and then fully released
; Returns the pressed button code in temp
Wait_Button_Press:
    rcall Read_Buttons
    tst temp
    breq Wait_Button_Press
    push temp
wait_release:
    rcall Read_Buttons
    tst temp
    brne wait_release
    pop temp
    ret
