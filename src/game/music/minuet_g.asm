; Bach's Minuet in G Major (BWV Anh. 114)
; Scaled for casino player
.equ MINUET_G_TEMPO_PAUSE = 10

minuet_g_table:
    .db  85, 255   ; D6 (240ms) part 1/3
    .db  85, 255   ; D6 (240ms) part 2/3
    .db  85,  28   ; D6 (240ms) part 3/3
    .db 128,  94   ; G5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db  96, 126   ; C6 (120ms)
    .db  85, 255   ; D6 (240ms) part 1/3
    .db  85, 255   ; D6 (240ms) part 2/3
    .db  85,  28   ; D6 (240ms) part 3/3
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db  76, 255   ; E6 (240ms) part 1/3
    .db  76, 255   ; E6 (240ms) part 2/3
    .db  76,  62   ; E6 (240ms) part 3/3
    .db  96, 126   ; C6 (120ms)
    .db  85, 255   ; D6 (120ms) part 1/2
    .db  85,  14   ; D6 (120ms) part 2/2
    .db  76, 255   ; E6 (120ms) part 1/2
    .db  76,  31   ; E6 (120ms) part 2/2
    .db  68, 255   ; FS6 (120ms) part 1/2
    .db  68,  51   ; FS6 (120ms) part 2/2
    .db  64, 255   ; G6 (240ms) part 1/3
    .db  64, 255   ; G6 (240ms) part 2/3
    .db  64, 122   ; G6 (240ms) part 3/3
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db  96, 255   ; C6 (240ms) part 1/2
    .db  96, 124   ; C6 (240ms) part 2/2
    .db  85, 255   ; D6 (120ms) part 1/2
    .db  85,  14   ; D6 (120ms) part 2/2
    .db  96, 126   ; C6 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 101, 255   ; B5 (240ms) part 1/2
    .db 101, 110   ; B5 (240ms) part 2/2
    .db  96, 126   ; C6 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 128,  94   ; G5 (120ms)
    .db 135, 255   ; FS5 (240ms) part 1/2
    .db 135,  51   ; FS5 (240ms) part 2/2
    .db 128,  94   ; G5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db 128,  94   ; G5 (120ms)
    .db 114, 255   ; A5 (720ms) part 1/5
    .db 114, 255   ; A5 (720ms) part 2/5
    .db 114, 255   ; A5 (720ms) part 3/5
    .db 114, 255   ; A5 (720ms) part 4/5
    .db 114, 126   ; A5 (720ms) part 5/5
    .db  85, 255   ; D6 (240ms) part 1/3
    .db  85, 255   ; D6 (240ms) part 2/3
    .db  85,  28   ; D6 (240ms) part 3/3
    .db 128,  94   ; G5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db  96, 126   ; C6 (120ms)
    .db  85, 255   ; D6 (240ms) part 1/3
    .db  85, 255   ; D6 (240ms) part 2/3
    .db  85,  28   ; D6 (240ms) part 3/3
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db  76, 255   ; E6 (240ms) part 1/3
    .db  76, 255   ; E6 (240ms) part 2/3
    .db  76,  62   ; E6 (240ms) part 3/3
    .db  96, 126   ; C6 (120ms)
    .db  85, 255   ; D6 (120ms) part 1/2
    .db  85,  14   ; D6 (120ms) part 2/2
    .db  76, 255   ; E6 (120ms) part 1/2
    .db  76,  31   ; E6 (120ms) part 2/2
    .db  68, 255   ; FS6 (120ms) part 1/2
    .db  68,  51   ; FS6 (120ms) part 2/2
    .db  64, 255   ; G6 (240ms) part 1/3
    .db  64, 255   ; G6 (240ms) part 2/3
    .db  64, 122   ; G6 (240ms) part 3/3
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db 128, 255   ; G5 (240ms) part 1/2
    .db 128,  61   ; G5 (240ms) part 2/2
    .db  96, 255   ; C6 (240ms) part 1/2
    .db  96, 124   ; C6 (240ms) part 2/2
    .db  85, 255   ; D6 (120ms) part 1/2
    .db  85,  14   ; D6 (120ms) part 2/2
    .db  96, 126   ; C6 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 101, 255   ; B5 (240ms) part 1/2
    .db 101, 110   ; B5 (240ms) part 2/2
    .db  96, 126   ; C6 (120ms)
    .db 101, 119   ; B5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 128,  94   ; G5 (120ms)
    .db 114, 255   ; A5 (240ms) part 1/2
    .db 114,  84   ; A5 (240ms) part 2/2
    .db 101, 119   ; B5 (120ms)
    .db 114, 106   ; A5 (120ms)
    .db 128,  94   ; G5 (120ms)
    .db 135,  89   ; FS5 (120ms)
    .db 128, 255   ; G5 (720ms) part 1/5
    .db 128, 255   ; G5 (720ms) part 2/5
    .db 128, 255   ; G5 (720ms) part 3/5
    .db 128, 255   ; G5 (720ms) part 4/5
    .db 128,  56   ; G5 (720ms) part 5/5
    .db   0,   0   ; End marker
