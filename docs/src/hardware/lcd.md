# Protocolo I2C
Neste protocolo -- i2c vem de _inter-intergrated circuit_, há duas vias seriais:
* SDA (Serial Data): Responsável pelos dados.
* SCL (Serial Clock): Responsável, principalmente, por indicar se o que é transmitido via SDA é para ser lido ou não.
A passagem de dados via SDA é feita através da variação de impedância dentro da situação de um pull-up. Configura-se os pinos conectados aos seriais para sempre emitir 0 caso saída. Assim, a transmissão é feita da seguinte forma:
*   Para transmitir o bit 1, o bit do pino correspondente é configurado como entrada, caracterizando-se alta impedância. Consequentemente, é passado Vcc.
*   Para transmitir o bit 0, o bit do pino correspondente é configurado como saída, caracterizando-se baixa impedância. Consequentemente, há o aterramento do serial.
Observação: para se enviar um dado via SDA, é necessário que o valor de SCL esteja baixo.
## i2c_start
Ao descer SDA _durante_ SCL alto, ativamos a condição de início no protocolo I2C.    
## i2c_stop
Ao subir SDA _durante_ SCL alto, ativamos a condição de parada no protocolo I2C.    
## i2c_write_byte(temp = byte a ser transmitido)
   É enviado o byte mais significativo de temp através do protocolo, enviando do MSB até o LSB dele. No final, há um envio de um 9ª bit. Nota-se que SDA é configurado para 1 no código, devendo-se ao fato de, segundo o protocolo, o dispositivo desce o valor do SDA como sinal de reconhecimento do dado (sinal de ACKNOWLEDGE). Assim, em tese, ele assim o fará e, através da descida do SCL:
```.asm
        cbi DDRC, LCD_SDA ; libera SDA
        rcall i2c_delay ; espera o retorno do dispositivo
        cbi DDRC, LCD_SCL ; SCL = 1
        rcall i2c_delay
        sbi DDRC, LCD_SCL ; SCL = 0
        rcall i2c_delay
```

Ele é feito de maneira tal que seja possível a comunicação entre diversos dispositivos através dele. Portanto, é 
O LCD, em si, não opera sob o protocolo i2c, sendo necessário um chip convertor -- no nosso caso, o PCF8574 --. 
# Driver do LCD

Na comunicação com o LCD, são necessários, a cada informação enviada, informar -- além da informação em si, os bits RS, EN e R/W:
*   RS (Register Select): Responsável por informar se a informação enviada trata-se de um comando ou um caractere.
*   EN (Enable): Serve para habiltiar a absorção de dados por parte do LCD. O LCD só recebe a informação na *descida* desse bit.
*   R/W (Read/Write): 1 para Read e 0 para Write.
Adicionalmente, é necessário enviar o bit BL para ativar (1) ou desativar (0) a luz de fundo, pois, assim, o PCF8574 ativará ou desativará um transistor ligado ao bit 3 (BL). Ou seja, o brilho em si não é diretamente controlado pelo LCD.

O PCF8574 envia os dados para o LCD por nibbles ao invés de bytes, devido ao fato de que seriam necessários 8+4=12 bits (8 dos pinos e o resto para os bits RS, EN, R/W e BL): por nibbles, sobram 4 pinos para os bits de controle.
Assim, temos as seguintes funções:
## Funções de escrita
### lcd_write_nibble (temp = dados+controle)
Inicialmente, é enviado, através de i2c_write_byte, o _endereço_ LCD_I2C_ADDR. _Endereço_, pois, no protocolo I2C, é possível acessar múltiplos dispositivos. Assim, é necessário informar, antes, a qual endereço deseja-seenviar os dados. Para isso, informa-se um "_endereço_" que o identifica, sendo, neste caso, o LCD_I2C_ADDR.
Depois, o dado e os demais bits de controle são enviados com EN=1 e EN=0 -- ou seja, havendo uma descida de EN e, consequentemente, a leitura da informação por parte do LCD. Por fim, i2c_stop é chamada para informar ao PCF8574 que aquele trecho de informação já foi transmitido, liberando assim a possibilidade de um futuro i2c_start.
### lcd_write_byte (temp = byte do dado, temp2 = flags RS e BL)
Escreve, chamando lcd_write_nibble, o byte desejado nibble a nibble de temp junto com as flags RS e BL.
### lcd_write_data (temp = byte do dado)
Serve para enviar um dado armazenado em temp.
### lcd_write_cmd (temp = byte do comando)
Serve para transmitir um comando para o LCD.
## LCD_Init
Realiza as seguintes operações de inicialização:
1. Configura LCD_SDA e LCD_SCL como "dreno aberto".
2. Envia o comando 0b00110000 três vezes (ativando o BLna comunicação com o PCF8574). Isso faz com que haja um _reset_ no LCD, garantindo que não haja alguma interferência com um possível estado prévio.
3. Envia o comando 0b00100000, que faz com que o LCD passe para o modo de 4 bits.
4. Envia o comando 0x28, onde o nibble mais significativo 0x2 confirma o modo de 4 bits e o nibble menos significativo configura o display para ter 2 linhas e fonte 5x8
5. Liga a tela e desliga o cursor
6. Ativa o modo de auto-incremento. Assim, a posição de escrita será incrementada automaticamente pelo LCD.
## LCD_Clear
Envia o comando LCD_CMD_CLEAR para limpar a tela do LCD.

## Envio da mensagem
### LCD_Set_Cursor (temp = linha, temp2=coluna)
Reposiciona o cursor, necessária para o caso de uma quebra de linha -- sem esta função, o texto iria ir para adireita até regiões indefinidas. É carregado o endereço de hardware fixo 0xC0 da linha 1 ou 0x80 para a linha 0.
### LCD_Print_Msg
Imprime, caractere a caractere, uma mensagem no registrador Z, terminando após identificar o caractere ASCII nulo.
### LCD_Print_Dec16 (r25:r24 = número a ser impresso)
Realiza uma série de operações para imprimir um número com supressão de zeros à esquerda (assim, 100 não poderá ser visto como 0100).

## Sobre a flag USE_PCF8574_BACKPACK
Como o LCD do SimulIDE difere do físico (incompatíveis), logo há a flag USE_PCF8574_BACKPACK para selecionar o trecho de código na hora de compilar. Até aqui, foi documentado as funções referentes ao circuito _físico_.
A diferença é que, no LCD do SimulIDE, é primeiro enviado o byte de controle e depois o de dados (ou seja, não há comunicação nibble a nibble como no hardware real)
