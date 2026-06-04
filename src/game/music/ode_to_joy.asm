; Ode to Joy Track
; Tempo definition: pause between notes in ms
.equ ODE_TO_JOY_TEMPO_PAUSE = 30

ode_to_joy_table:
    ; Phrase 1
    .db 202, 98    ; B4
    .db 202, 98    ; B4
    .db 191, 104   ; C5
    .db 170, 117   ; D5
    .db 170, 117   ; D5
    .db 191, 104   ; C5
    .db 202, 98    ; B4
    .db 227, 88    ; A4
    .db 255, 78    ; G4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 202, 98    ; B4
    .db 202, 148   ; B4 (dotted quarter)
    .db 227, 44    ; A4 (eighth)
    .db 227, 176   ; A4 (half)
    
    ; Phrase 2
    .db 202, 98    ; B4
    .db 202, 98    ; B4
    .db 191, 104   ; C5
    .db 170, 117   ; D5
    .db 170, 117   ; D5
    .db 191, 104   ; C5
    .db 202, 98    ; B4
    .db 227, 88    ; A4
    .db 255, 78    ; G4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 202, 98    ; B4
    .db 227, 148   ; A4 (dotted quarter)
    .db 255, 39    ; G4 (eighth)
    .db 255, 156   ; G4 (half)
    
    ; Phrase 3
    .db 227, 88    ; A4
    .db 227, 88    ; A4
    .db 202, 98    ; B4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 202, 49    ; B4 (eighth)
    .db 191, 52    ; C5 (eighth)
    .db 202, 98    ; B4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 202, 49    ; B4 (eighth)
    .db 191, 52    ; C5 (eighth)
    .db 202, 98    ; B4
    .db 227, 88    ; A4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 170, 234   ; D5 (half)
    
    ; Phrase 4
    .db 202, 98    ; B4
    .db 202, 98    ; B4
    .db 191, 104   ; C5
    .db 170, 117   ; D5
    .db 170, 117   ; D5
    .db 191, 104   ; C5
    .db 202, 98    ; B4
    .db 227, 88    ; A4
    .db 255, 78    ; G4
    .db 255, 78    ; G4
    .db 227, 88    ; A4
    .db 202, 98    ; B4
    .db 227, 148   ; A4 (dotted quarter)
    .db 255, 39    ; G4 (eighth)
    .db 255, 156   ; G4 (half)
    
    .db 0, 0       ; End marker
