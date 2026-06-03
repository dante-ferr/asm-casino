; Map selection index (0-42) to real bet type/target
; Inputs:
;   temp = selection index (0-42)
; Outputs:
;   temp = real bet type (0=Int, 1=Ext)
;   temp2 = real bet target (0-36 or 0-5)
Map_Selection_To_Bet:
    cpi temp, 6
    brsh map_internal
    
    ; External: Type=1, Target = temp (0 to 5)
    mov temp2, temp
    ldi temp, 1
    ret
    
map_internal:
    ; Internal: Type=0, Target = temp - 6 (0 to 36)
    mov temp2, temp
    subi temp2, 6
    ldi temp, 0
    ret
