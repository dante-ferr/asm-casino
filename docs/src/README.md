# Introdução - ASM Casino

Este livro contém a documentação técnica detalhada do projeto ASM Casino, que é uma implementação em Assembly AVR da Roleta Francesa (com a regra "en prison") para o microcontrolador ATmega328P. O trabalho foi desenvolvido como projeto prático final para a disciplina MATA49 (Programação de Software Básico) no semestre de 2026.1 na Universidade Federal da Bahia, ministrada pelo professor Euclério Ornellas.

A simulação e modelagem do circuito virtual foram realizadas no SimulIDE, e as especificações de drivers e regras do jogo são compatíveis com a gravação e montagem em hardware real.

---

## Estrutura da Documentação

A documentação do livro está organizada de forma modular para cobrir os principais pilares do projeto:

- Introdução e Apresentação: Esta página inicial, trazendo o escopo e créditos da equipe.
- Guia de Utilização: O manual detalhado do fluxo de estados da máquina, comandos dos botões e as regras de jogo.
- Arquitetura do Sistema: O mapeamento de pinos do microcontrolador, as convenções de registradores adotadas e a organização da memória SRAM.
- Periféricos e Drivers: Detalhes de baixo nível de cada driver físico implementado em Assembly AVR (Teclado, displays, LCD, LED RGB, Buzzer e Matriz de LEDs).
- Subsistemas do Jogo: Funcionamento das regras, da mecânica especial "en prison", do gerador pseudo-aleatório e da gerência de jogadores.
- Referência da API: Detalhes das subrotinas, parâmetros de entrada, parâmetros de saída e registradores afetados.

---

## Diagrama do Circuito Virtual

O circuito do projeto foi completamente modelado no SimulIDE e pode ser aberto através do arquivo localizado em [circuit/FrenchRoulette.sim1](file:///home/dante/Code/projects/asm-casino/circuit/FrenchRoulette.sim1).

Uma representação visual dele pode ser vista [na página sobre mapeamento](./arquitetura/mapeamento.md).

---

## Referências usadas para estudo
1. Microcontrolador ATmega328P MICROCHIP TECHNOLOGY INC. ATmega48A/PA/88A/PA/168A/PA/328/P Data Sheet Complete. Chandler: Microchip Technology Inc., 2018. Disponível em: https://ww1.microchip.com/downloads/en/DeviceDoc/ATmega48A-PA-88A-PA-168A-PA-328-P-DS-DS40002061A.pdf. 
2. Controlador de Matriz de LEDs (MAX7219) ANALOG DEVICES. MAX7219/MAX7221: Serially Interfaced, 8-Digit LED Display Drivers. Norwood: Analog Devices. Disponível em: https://www.analog.com/media/en/technical-documentation/data-sheets/MAX7219-MAX7221.pdf.
3. Controlador de Display LCD (HD44780) HITACHI. HD44780U (LCD-II): Dot Matrix Liquid Crystal Display Controller/Driver. Tóquio: Hitachi. Disponível em: https://www.sparkfun.com/datasheets/LCD/HD44780.pdf. 
4. Módulo Expansor I2C do LCD (PCF8574) TEXAS INSTRUMENTS. PCF8574 Remote 8-Bit I/O Expander for I2C Bus. Dallas: Texas Instruments. Disponível em: https://www.ti.com/lit/ds/symlink/pcf8574.pdf. 
5. Especificação Oficial do Protocolo I2C NXP SEMICONDUCTORS. I2C-bus specification and user manual. Eindhoven: NXP Semiconductors. Disponível em: https://www.nxp.com/docs/en/user-guide/UM10204.pdf. 
6. Material Complementar sobre PWM SPARKFUN ELECTRONICS. Pulse Width Modulation. Niwot: SparkFun Electronics. Disponível em: https://learn.sparkfun.com/tutorials/pulse-width-modulation/all.

