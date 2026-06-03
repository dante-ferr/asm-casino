# Planejamento: Tela de Configuração de Crédito (Set Credits)

Para permitir que os usuários definam, adicionem e reduzam os créditos/balanços iniciais de cada um dos 4 jogadores antes de iniciarem as apostas, adicionaremos um estado dedicado na FSM.

---

## 1. Nova Transição de Estados da FSM

No **Estado 0 (Menu Principal)**, o botão B não chamará mais diretamente o histórico de sorteios. Em vez disso, ele levará o jogador para uma tela de configuração de créditos para o jogador ativo.

```
       [Menu Principal (Estado 0)]
             |              ^
             | (Botão B)    | (Botão Select)
             v              |
       [Configurar Créditos (Novo Estado)]
             | (Botões A/B)
             v
       [Ajusta Saldo (+100 / -100)]
```

---

## 2. Layouts Visuais do LCD

### A. Estado 0: Menu Principal (Idle)
Exibe o jogador ativo e seu saldo atual. O botão B agora direciona para o menu de créditos ("Cred"):
*   **Linha 0**: `P1 Bal: 1000 pts`
*   **Linha 1**: `A:Mudar B:Cred S:Bet`

### B. Novo Estado: Configuração de Crédito
Permite incrementar ou decrementar o saldo em passos de 100 pontos:
*   **Linha 0**: `P1 Set Bal: 1000`
*   **Linha 1**: `A:+100 B:-100 S:OK`

---

## 3. Mapeamento de Ações dos Botões

### No Menu Principal (Estado 0):
*   **Botão A**: Alterna o jogador ativo ($P_1 \rightarrow P_2 \rightarrow P_3 \rightarrow P_4 \rightarrow P_1$).
*   **Botão B**: Transiciona para a tela de Configuração de Crédito.
*   **Botão Select**: Inicia o fluxo de aposta (transiciona para o Estado 1 - Escolha de Categoria).

### Na Tela de Configuração de Crédito:
*   **Botão A**: Incrementa o saldo do jogador ativo em $+100$ pontos (limite máximo de $9900$ pontos).
*   **Botão B**: Decrementa o saldo do jogador ativo em $-100$ pontos (limite mínimo de $0$ pontos).
*   **Botão Select**: Salva o novo saldo em SRAM, emite um bipe de confirmação e retorna para o Menu Principal.
