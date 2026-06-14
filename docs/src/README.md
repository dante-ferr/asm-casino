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