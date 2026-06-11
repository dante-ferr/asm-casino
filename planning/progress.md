# Status do Desenvolvimento - Roleta Francesa AVR Assembly

## Etapas Concluídas:
- [x] Configuração de Arquitetura e Estruturação Modular (`src/main.asm` e `src/config.inc`)
- [x] Criação de todos os arquivos de stubs de hardware e lógica do jogo
- [x] Implementação do driver do LCD I2C (`src/hardware/lcd_i2c.asm` via bit-banging)
- [x] Implementação do teclado analógico (`src/hardware/adc_buttons.asm`) com leitura de resistores via ADC
- [x] Implementação da multiplexação dos displays de 7 segmentos (`src/hardware/seven_seg.asm`) com Timer 0
- [x] Implementação do driver serial MAX7219 para matriz de LEDs 8x8 (`src/hardware/max7219.asm`)
- [x] Implementação da lógica de animação de giro e desaceleração por atrito (`src/game/roulette_spin.asm`)
- [x] Mapeamento de LEDs e alinhamento do Slot 0 (número 0) à 4ª coluna do topo da matriz
- [x] Configuração do barramento RGB LED (`src/hardware/rgb_led.asm`) sincronizado por número sorteado
- [x] Lógica das regras da roleta francesa e mecânica "En Prison" (`src/game/roulette_rules.asm`)
- [x] Integração da gerência de múltiplos jogadores (1-4) com dados persistidos em SRAM (`src/game/players.asm`)
- [x] Implementação do estado de FSM para definição de créditos iniciais (`STATE_SET_CREDITS`)
- [x] Resolução de bugs críticos de colisão de registradores (restauração de `active_plyr` em `r21` e preservação de `S_win`)
- [x] Adição do indicador visual de prisão `(P)` na tela principal do LCD (ex. `P1(P) Bal: 900`)
- [x] Validação interativa completa da mecânica de En Prison no SimulIDE
- [x] Correção do loop infinito de resolução (remoção do push/pop indesejado de `fsm_state` e `active_plyr` no retorno da resolução)


## Próximas Etapas:
- [x] Implementação de toda a navegação e seleção de apostas na FSM (Estados 1, 2 e 3)
  - Seleção de categoria (Aposta Interna vs. Externa)
  - Seleção do alvo (números de 0 a 36, ou categorias como Vermelho/Preto, Par/Ímpar, Alto/Baixo)
  - Confirmação e cancelamento de aposta antes do giro (com tela de confirmação SIM/VOLTAR e ciclo multiplayer)
- [x] Correção de bugs de ajuste de apostas (conversão de `subi` assinado para adição/subtração de registradores de 16 bits livre de carry ambíguo)
- [x] Implementação do seletor inicial de quantidade de jogadores (1-4) com novo ícone crowd na matriz de LEDs
- [x] Validação de rodada sem apostas (exibe erro "Erro: Sem Aposta" no LCD se ninguém apostar, retornando ao menu)
- [x] Sincronização dos displays/LEDs com o jogador ativo na fase de apostas e menu principal (com cores customizadas: P1=Vermelho, P2=Azul, P3=Verde, P4=Amarelo)
- [x] Efeito gradual fade (soft PWM) no LED RGB e animação de traço único rotativo contínuo de 8 frames cruzando ambos os displays de 7 segmentos (com eliminação de ruído no buzzer por máscara de porta) no menu de seleção inicial
- [ ] Gravação e exibição do histórico de rodadas (local e global) na SRAM
- [ ] Otimizações e limpeza final de código para produção

