; Map selection index (0-42) to real bet type/target
; Inputs:
;   temp = selection index (0-42)
; Outputs:
;   temp = real bet type (0=Int, 1=Ext)
;   temp2 = real bet target (0-36 or 0-5)
Map_Selection_To_Bet:
    cpi temp, FIRST_INTERNAL_IDX
    brsh map_internal
    
    ; External: Type=1, Target = temp (0 to 5)
    mov temp2, temp
    ldi temp, 1
    ret
    
map_internal:
    ; Internal: Type=0, Target = temp - FIRST_INTERNAL_IDX (0 to 36)
    mov temp2, temp
    subi temp2, FIRST_INTERNAL_IDX
    ldi temp, 0
    ret
