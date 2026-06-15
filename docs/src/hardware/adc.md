# ADC
O sistema utiliza uma escada de resistores para dividir a voltagem. Por tratar-se de resistência em paralelo, utiliza-se fórmula:
V_out = 5V x (R_gnd) / (R_pullup + R_gnd)
E, convertendo para o valor digital do ADC de 10 bits (já que o bit ADLAR não foi ativado):
Valor = (V_out/5V) x 1023
* Nenhum botão: a resistência do botão é considerada infinita, logo tempos o valor: lim R_botão -> infinito 1023 x (R_botão)/(10k+R_botão) = 1023.
* Select: 1023 x (22k)/(10k + 22k) ≈ 703
* B: 1023 x (10k)/(10k + 10) ≈ 512
* A: 1023 x (0)/(10k + 0) ≈ 0
Para os BNT_THRES_*, foram escolhidos os pontos médios entre esses valores para minimizar a chance de erro ou ruído:
* BTN_THRES_NONE = (1023 + 703)/2 = 863
* BTN_THRES_SELECT = (703 + 512)/2 = 607
* BTN_THRES_B = (512 + 0)/2 = 607
## Read_buttons
Inicialmente, ela ativa o bit ADSC (ADC Start Conversion) do ADCSRA (ADC State Register A). Logo depois, em wait_adc, os valores lidos por ADC são comparados com BTN_THRES_NONE, BTN_THRES_SELECT, BTN_THRES_B e, caso não seja nenhum desses, assume-se que o botão apertado foi A. Assim, temp será configurado:
*   0, caso nenhum botão esteja sendo apertado
*   3, para select
*   2, para B
*   1, para A
### wait_Button_Press
Faz um debounce dos botões quando apertado um deles.
### wait_release
Faz um debounce dos botões quando soltos.
