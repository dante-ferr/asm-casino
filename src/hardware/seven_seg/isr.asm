; Rotina de Interrupção do Timer 0 para multiplexação dos displays de 7 segmentos (roda a cada 2ms)
TIMER0_ISR:
    push temp
    in temp, SREG
    push temp
    push temp2
    push r23
    push r24
    push r25
    push ZL
    push ZH

    ; Verifica se está no estado de seleção de jogadores ou boas-vindas para rodar o soft PWM e a animação
    lds temp, RAM_FSM_STATE
    cpi temp, STATE_NUM_PLAYERS
    breq isr_players_sel
    cpi temp, STATE_WELCOME
    breq isr_players_sel
    rjmp isr_normal_seg

    isr_players_sel: ; Estado de boas-vindas
            ; --- SOFT PWM EM SEGUNDO PLANO ---
            lds temp, RAM_PWM_COUNTER
            inc temp
            andi temp, 0x07 ; módulo 8
            sts RAM_PWM_COUNTER, temp
            
            ; Calcula os bits do LED RGB no r23 (PD1=G, PD2=R, PD3=B)
            clr r23
            
            ; Canal vermelho (PD2)
            lds temp2, RAM_PWM_RED
            cp temp, temp2
            brlo pwm_red_bit_on
            rjmp pwm_check_green_bit
        pwm_red_bit_on:
            ori r23, (1 << RGB_RED)
            
        pwm_check_green_bit:
            ; Canal verde (PD1)
            lds temp2, RAM_PWM_GREEN
            cp temp, temp2
            brlo pwm_green_bit_on
            rjmp pwm_check_black_bit
        pwm_green_bit_on:
            ori r23, (1 << RGB_GREEN)
            
        pwm_check_black_bit:
            ; Canal azul (PD3)
            lds temp2, RAM_PWM_BLACK
            cp temp, temp2
            brlo pwm_black_bit_on
            rjmp pwm_bits_done
        pwm_black_bit_on:
            ori r23, (1 << RGB_BLACK)

        pwm_bits_done:
            rjmp pwm_tick_fade

        pwm_tick_fade:
            ; --- ATUALIZA EFEITO FADE E ANIMAÇÃO (A cada 100ms / 50 interrupções) ---
            lds temp, RAM_PWM_TICK
            inc temp
            cpi temp, 50
            brsh pwm_update_fade
            rjmp pwm_save_fade_tick
        pwm_update_fade:
            ; Dispara atualização:
            ldi temp, 0
            sts RAM_PWM_TICK, temp
            
            ; Avança o quadro de animação do display (RAM_ROUND_NUM vai de 0 a 7)
            lds temp2, RAM_ROUND_NUM
            inc temp2
            cpi temp2, 8
            brlo pwm_save_anim_frame
            ldi temp2, 0
        pwm_save_anim_frame:
            sts RAM_ROUND_NUM, temp2
            
            ; Atualiza as cores do fade
            lds temp, RAM_FADE_STATE
            cpi temp, 0
            breq pwm_fade_r_to_b
            cpi temp, 1
            breq pwm_fade_b_to_g
            
            ; fade_g_to_r: diminui Verde, aumenta Vermelho
            lds temp2, RAM_PWM_GREEN
            tst temp2
            breq pwm_g_to_r_done
            dec temp2
            sts RAM_PWM_GREEN, temp2
            
            lds temp2, RAM_PWM_RED
            inc temp2
            sts RAM_PWM_RED, temp2
            rjmp isr_anim_render
        pwm_g_to_r_done:
            ldi temp, 0 ; muda estado para 0 (R para B)
            sts RAM_FADE_STATE, temp
            rjmp isr_anim_render
            
        pwm_fade_r_to_b:
            ; diminui Vermelho, aumenta Azul/Preto
            lds temp2, RAM_PWM_RED
            tst temp2
            breq pwm_r_to_b_done
            dec temp2
            sts RAM_PWM_RED, temp2
            
            lds temp2, RAM_PWM_BLACK
            inc temp2
            sts RAM_PWM_BLACK, temp2
            rjmp isr_anim_render
        pwm_r_to_b_done:
            ldi temp, 1 ; muda estado para 1 (B para G)
            sts RAM_FADE_STATE, temp
            rjmp isr_anim_render

        pwm_fade_b_to_g:
            ; diminui Azul/Preto, aumenta Verde
            lds temp2, RAM_PWM_BLACK
            tst temp2
            breq pwm_b_to_g_done
            dec temp2
            sts RAM_PWM_BLACK, temp2
            
            lds temp2, RAM_PWM_GREEN
            inc temp2
            sts RAM_PWM_GREEN, temp2
            rjmp isr_anim_render
        pwm_b_to_g_done:
            ldi temp, 2 ; muda estado para 2 (G para R)
            sts RAM_FADE_STATE, temp
            rjmp isr_anim_render

        pwm_save_fade_tick:
            sts RAM_PWM_TICK, temp

    isr_anim_render:
            ; --- RENDERIZA QUADRO DE ANIMAÇÃO DO 7-SEGMENTOS ---
            lds temp, RAM_ROUND_NUM ; carrega passo atual da animação (0-7)
            
            ; Lê o estado do cátodo no PORTB (usa temp2, não r23!)
            in temp2, PORTB
            sbrs temp2, DISP_DEC ; se PB4 estiver apagado, pula para unidades
            rjmp show_units_anim
            
        show_tens_anim:
            sbi PORTB, DISP_UNI ; desliga cátodo das unidades (PB5=1)
            
            clr temp2
            ldi ZL, low(anim_table_portd_left * 2)
            ldi ZH, high(anim_table_portd_left * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r24, Z ; r24 = segmentos do PORTD (bits 5, 6, 7)
            
            ldi ZL, low(anim_table_portb_left * 2)
            ldi ZH, high(anim_table_portb_left * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r25, Z ; r25 = segmentos do PORTB (bits 0 a 3)
            
            ; Junta segmentos (r24) e bits do RGB (r23) para PORTD, preservando PD4 (Buzzer) e PD0
            andi r24, 0xE0 ; mantém apenas bits de segmentos (PD5-PD7)
            andi r23, 0x0E ; mantém apenas bits do LED RGB (PD1-PD3)
            in temp, PORTD
            andi temp, 0x11 ; mantém PD0 (RX) e PD4 (Buzzer)
            or r24, temp ; junta bits preservados
            or r24, r23 ; junta bits do LED RGB
            out PORTD, r24
            
            ; Escreve segmentos no PORTB (preservando PB4-PB5)
            in temp, PORTB
            andi temp, 0xF0
            or temp, r25
            out PORTB, temp
            
            cbi PORTB, DISP_DEC ; liga cátodo das dezenas (PB4=0)
            rjmp isr_exit
            
        show_units_anim:
            sbi PORTB, DISP_DEC ; desliga cátodo das dezenas (PB4=1)
            
            clr temp2
            ldi ZL, low(anim_table_portd_right * 2)
            ldi ZH, high(anim_table_portd_right * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r24, Z ; r24 = segmentos do PORTD
            
            ldi ZL, low(anim_table_portb_right * 2)
            ldi ZH, high(anim_table_portb_right * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r25, Z ; r25 = segmentos do PORTB
            
            ; Junta segmentos (r24) e bits do RGB (r23) para PORTD, preservando PD4 (Buzzer) e PD0
            andi r24, 0xE0 ; mantém apenas bits de segmentos (PD5-PD7)
            andi r23, 0x0E ; mantém apenas bits do LED RGB (PD1-PD3)
            in temp, PORTD
            andi temp, 0x11 ; mantém PD0 (RX) e PD4 (Buzzer)
            or r24, temp ; junta bits preservados
            or r24, r23 ; junta bits do LED RGB
            out PORTD, r24
            
            ; Escreve segmentos no PORTB (preservando PB4-PB5)
            in temp, PORTB
            andi temp, 0xF0
            or temp, r25
            out PORTB, temp
            
            cbi PORTB, DISP_UNI ; liga cátodo das unidades (PB5=0)
            rjmp isr_exit

        isr_exit_bridge:
            rjmp isr_exit

    isr_normal_seg:
        ; Lê o número da rodada atual para exibir
        lds temp, RAM_ROUND_NUM

        ; Separa dezenas e unidades por subtração sucessiva
        ldi temp2, 0
        div_loop:
            cpi temp, 10
            brlo div_done
            subi temp, 10
            inc temp2
            rjmp div_loop
        div_done:
            ; temp = units, temp2 = tens

            ; Lê o cátodo no PORTB para ver qual dígito atualizar
            in r23, PORTB
            sbrs r23, DISP_DEC ; se cátodo de dezenas estiver desligado (PB4=1), pula para dezenas
            rjmp show_units ; se cátodo de dezenas estiver ligado (PB4=0), mostra unidades

        show_tens:
            ; Desliga o cátodo das unidades (ativo em nível baixo)
            sbi PORTB, DISP_UNI
            
            ; Carrega o valor das dezenas
            mov temp, temp2
            ; Busca os segmentos para o PORTD
            clr temp2
            ldi ZL, low(table_portd * 2)
            ldi ZH, high(table_portd * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r24, Z ; r24 contém segmentos A, B, C (PD7-PD5)

            ; Busca os segmentos para o PORTB
            ldi ZL, low(table_portb * 2)
            ldi ZH, high(table_portb * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r25, Z ; r25 contém segmentos D, E, F, G (PB3-PB0)

            ; Escreve segmentos no PORTD (preservando PD0-PD4)
            in temp, PORTD
            andi temp, 0x1F
            or temp, r24
            out PORTD, temp

            ; Escreve segmentos no PORTB (preservando PB4-PB5)
            in temp, PORTB
            andi temp, 0xF0
            or temp, r25
            out PORTB, temp

            ; Liga o cátodo das dezenas (ativo em nível baixo)
            cbi PORTB, DISP_DEC
            rjmp isr_exit_bridge

        show_units:
            ; Desliga o cátodo das dezenas (ativo em nível baixo)
            sbi PORTB, DISP_DEC

            ; Busca os segmentos para o PORTD
            clr temp2
            ldi ZL, low(table_portd * 2)
            ldi ZH, high(table_portd * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r24, Z
            

            ; Busca os segmentos para o PORTB
            ldi ZL, low(table_portb * 2)
            ldi ZH, high(table_portb * 2)
            add ZL, temp
            adc ZH, temp2
            lpm r25, Z
            

            ; Escreve segmentos no PORTD (preservando PD0-PD4)
            in temp, PORTD
            andi temp, 0x1F
            or temp, r24
            out PORTD, temp

            ; Escreve segmentos no PORTB (preservando PB4-PB5)
            in temp, PORTB
            andi temp, 0xF0
            or temp, r25
            out PORTB, temp

            ; Liga o cátodo das unidades (ativo em nível baixo)
            cbi PORTB, DISP_UNI

    isr_exit:
        pop ZH
        pop ZL
        pop r25
        pop r24
        pop r23
        pop temp2
        pop temp
        out SREG, temp
        pop temp
        reti
