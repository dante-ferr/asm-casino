# Buzzer
Notas musicais são basicamente diferentes frequências para ondas sonoras. No caso do Buzzer, o timbre é simples, pois tratam-se de ondas quadradas: assim, basta controlar o tempo em que a onda está em 1 ou em 0.
### Buzzer_Tick
Gera um bipe curto, através de "Buzzer_Play_Tone(temp=TONE_TICK_PITCH, temp2=TONE_TICK_LEN)".
### Buzzer_Beep
Mesma estrutura da subrotina acima, exceto que o beep é um beep padrão de confirmação.
### Buzzer_Sucess
Toca 3 notas: Uma de 1 kHz, de 60 de duração, seguida de uma pausa de 20 ms; Outra de ~1.3 kHz, que dura 80; e uma última, 2 kHz, que dura 120;
### Buzzer_Failure
Toca 1 nota de 400 Hz por 120 ciclos.
## Buzzer_Play_Tone (temp = atraso do meio período o qual determina a frequência, temp2 = total de ciclos de alternância que determina a duração)
O atraso de meio período -- ou seja, o número de ciclos do nível 0 da onda quadrada, ou a metade do período da onda -- determinará a frequência que tocará durante o número de ciclos indicado por temp2
### buzzer_delay_loop
Função de delay.
## Buzzer_Play_Current_Track
Através de RAM_CURRENT_TRACK, verifica a música a ser tocada na abertura do projeto. A cada nota tocada, a função atualiza a posição da bolinha. De 16 em 16 ciclos dentro de uma nota, a música é rapidamente interrompida para verificar se algum botão foi pressionado e, caso for, a função retorna.

