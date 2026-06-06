; Betting strings and tables

msg_bet_val_label:  .db "Apos:", 0
msg_bet_keys_label: .db " (A/B/S)", 0, 0
msg_bet_prison_status: .db ": PRISAO", 0, 0
msg_bet_prison_keys:   .db " (S)", 0, 0

target_strings_table:
    .dw msg_tgt_red * 2
    .dw msg_tgt_black * 2
    .dw msg_tgt_even * 2
    .dw msg_tgt_odd * 2
    .dw msg_tgt_low * 2
    .dw msg_tgt_high * 2
    .dw msg_tgt_doz1 * 2
    .dw msg_tgt_doz2 * 2
    .dw msg_tgt_doz3 * 2
    .dw msg_tgt_col1 * 2
    .dw msg_tgt_col2 * 2
    .dw msg_tgt_col3 * 2

msg_tgt_red:    .db "VERMELHO", 0, 0
msg_tgt_black:  .db "AZUL", 0, 0
msg_tgt_even:   .db "PAR", 0
msg_tgt_odd:    .db "IMPAR", 0
msg_tgt_low:    .db "BAIXO", 0
msg_tgt_high:   .db "ALTO", 0, 0
msg_tgt_doz1:   .db "1a DUZIA", 0, 0
msg_tgt_doz2:   .db "2a DUZIA", 0, 0
msg_tgt_doz3:   .db "3a DUZIA", 0, 0
msg_tgt_col1:   .db "1a COLUNA", 0
msg_tgt_col2:   .db "2a COLUNA", 0
msg_tgt_col3:   .db "3a COLUNA", 0

msg_num_prefix:    .db "NUM: ", 0
msg_conf_prefix:   .db " Conf: ", 0
msg_conf_sim:      .db "SIM", 0
msg_conf_voltar:   .db "VOLTAR", 0, 0
msg_err_no_bets:      .db "Erro: Sem Aposta", 0, 0
msg_err_return_menu:  .db "Volta p/ Menu...", 0, 0

