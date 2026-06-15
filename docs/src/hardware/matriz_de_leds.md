# Matriz de LEDs
A matriz de LEDs é controlada pelo chip MAX7219 que, por sua vez, recebe pacotes de 16 bits via o barramento de comunicação SPI (Serial Peripherical Interface):
*     DIN (Data IN): O dado em si, que pode ser 1 ou 0;
*     SCK (Serial Clock): A sua subida faz a matriz ler o dado em DIN;
*     CS (Chip Select): Se e somente se estiver em 0, a matriz receberá bit a bit da informação através da sincronia entre DIN e SCK.
O MAX7219 também tem um sistema próprio de registradores. Assim, o primeiro byte informa o endereço do registrador e o segundo byte o dado a ser armazenado.
Os principais registradores são:
1. Os de 0x00 até 0x08, onde cada um deles controla uma linha.
2. MAX7219_SHUTDOWN: no 1 ele opera normalmente e no 0 ele entra em modo de suspensão e apaga.
3. MAX7219_INTENSITY: Controla o nível de luminosidade, que varia de 0x00 até 0x0F.
4. MAX7219_DECODE: Define o modo de decodificação do chip. Neste projeto, ele é inútil.
5. MAX7219_SCAN_LIMIT: Controla o número de linhas devem ser atualizadas ciclicamente em sua multiplexação interna.
6. MAX7219_TEST: Se 1, força todos os LEDs a acenderem em brilho máximo. Serve para verificar se algum deles está com defeito, por isso o nome.
## max7219_write (temp = endereço do registrador do MAX7219, temp2 = dado)
Envia o endereço do registrador e seu dado para o chip.
## Matrix_Init
Esta função inicializa o chip MAX7219 da seguinte forma:
1. Inicializa DIN, SCK e CS como 0.
2. Escreve 1 no registrador MAX7219_SHUTDOWN.
3. Desligam o modo de teste no MAX7219_TEST.
4. Desliga a decodificação no MAX7219_DECODE.
5. Configura o número de linhas a serem varridas como 8 MAX7219_SCAN_LIMIT.
6. Configura o valor MAX7219_BRIGHTNESS em MAX7219_INTENSITY.
7. Chama a função Matrix_Clear.
### Matrix_Refresh
Reescreve todos os dados de RAM_SCREEN_BUF.
### Matrix_Clear 
Zera todos os valores de RAM_SCREEN_BUF e depois chama Matrix_Refresh.
### Matrix_Render_Frame
Renderiza o padrão central e faz a "bolinha" girar através da atualização de RAM_SCREEN_BUF.

### Matrix_Draw_Icon
Renderiza um "ícone" de acordo com o conteúdo de RAM_SCREEN_BUF.

