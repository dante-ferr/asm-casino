# ADC
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
