# MATA49 - Programação de Software Básico[cite: 1]
**Semestre:** 2026.1
**Universidade Federal da Bahia**

## Projeto Final: Construção de Jogos Eletrônicos utilizando Assembly do ATMEGA328P no Arduino
**Valor:** 10,0 pontos

---

### Avisos Legais
* Este projeto possui objetivos apenas acadêmicos e não visa de forma alguma o incentivo à prática de jogos de azar.
* Caso haja algum impedimento acerca do tema, enviar e-mail imediatamente para eucleriofilho@ufba.br.

---

### Orientações Gerais
* O projeto deve ser realizado em equipes de 5 pessoas.
* Existem 7 equipes e os temas de jogos serão definidos por sorteio.
* Os jogos eletrônicos possíveis são:
  * Caça-níqueis
  * Bac Bo
  * Roleta Francesa (La Partage)
  * Roleta Francesa (En Prision)
  * Roleta Americana
  * Blackjack
  * Bacará
  * Bingo Eletrônico
  * Keno

* O projeto consiste em duas etapas de avaliação:
  1. Construção de um repositório no GitHub (documentação e código).
  2. Apresentação do circuito físico em sala de aula.

* Todos os integrantes da equipe devem realizar pelo menos 1 commit no repositório. Integrantes sem commits terão a nota zero (0,0) em todo o projeto, o que inclui ambas as etapas.
* Apenas o conteúdo presente na branch principal do repositório (geralmente nomeada de "main" ou "master") será avaliado.
* O repositório deve estar público no GitHub para que o acesso seja possível. Caso um repositório esteja privado, a avaliação não será possível e a equipe corre o risco de ficar sem nota.
* O link do repositório final deverá ser inserido na planilha de definição das equipes.

---

### Sobre a Avaliação
* Esta atividade deve ser feita apenas por alunos que realizaram a 1ª Prova. Caso um aluno não tenha realizado a 1ª Prova, o Projeto Final será substituído por uma 2ª Prova com os conteúdos de todo o semestre, caso uma justificativa de ausência seja apresentada, conforme o Art. 134. do REGPG da UFBA.
* As equipes devem informar obrigatoriamente na documentação do repositório o que cada integrante fez durante o período de elaboração do projeto.
* A equipe possui o direito de indicar que um ou mais integrantes tiveram contribuição apenas parcial, isto é, que realizaram apenas X% do que foi acordado. Nesse caso, tais integrantes terão apenas X% da nota total da equipe em todo o projeto, o que inclui ambas as etapas.

---

## Etapa 1 - Repositório no GitHub (4,0 pontos)
O produto desta atividade deve estar em um repositório do GitHub. Se você não tem familiaridade com GitHub, Git e conceitos adjacentes ou nunca ouviu falar, veja esta playlist do YouTube para entender como funcionam essas ferramentas.

O repositório deve conter os seguintes entregáveis:

### 1. Códigos do Projeto (1,5 pontos)
* Obrigatoriamente em Assembly para ATMEGA328P.
* Devem estar comentados e seguir boas práticas de programação.
* Devem empregar obrigatoriamente:
  * Técnica de multiplexação.
  * Pelo menos uma interrupção.
* Devem ser funcionais em todos os sistemas operacionais.
* Integração com C é permitida, mas com restrições:
  * Apenas para rotinas ou dispositivos cuja implementação em Assembly seja inconveniente ou extensa.
  * Exemplos permitidos: LCD, algoritmos de ordenação complexos (Merge Sort, Heap Sort, Radix Sort).
  * O código principal deve ser em Assembly.
  * O código em C deve compor menos de 50% do total.
* Critérios adicionais de avaliação:
  * Clareza dos comentários.
  * Estrutura modular.
  * Uso eficiente de registradores e memória.
  * Correção lógica e ausência de erros de execução.

### 2. Diagrama do Circuito no SimulIDE (1,0 ponto)
* O circuito virtual deve ser idêntico ao físico.
* Deve estar funcionando.
* Deve seguir boas práticas de montagem de circuitos, entre elas:
  * Apenas um GND na parte inferior.
  * Apenas um VCC na parte superior.
  * Fios legíveis e organizados.
* Critérios adicionais de avaliação:
  * Clareza visual.
  * Organização dos componentes.
  * Fidelidade ao circuito físico.

### 3. Documentação em Markdown (1,0 ponto)
Para entender como escrever um arquivo Markdown, consulte a documentação oficial do GitHub.

Deve conter obrigatoriamente:
* Relação de materiais utilizados.
* Prints do diagrama no SimulIDE.
* Explicação do funcionamento.
* Guia de utilização.
* Fotos do circuito físico.
* Nomes dos integrantes da equipe.

* Recomenda-se múltiplos arquivos md, mas deve haver pelo menos um README.md.
* A documentação não pode ser feita com IA. O uso de IA fará com que a equipe tenha nota zero (0,0) em todo o projeto, o que inclui ambas as etapas.
* Todos os entregáveis devem estar linkados na documentação.
* Critérios adicionais de avaliação:
  * Clareza e organização textual.
  * Uso adequado de Markdown.
  * Estrutura lógica e didática.

### 4. Estruturação do Repositório (0,5 ponto)
Estrutura sugerida:

└── Projeto-Jogo-Arduino
├── src/            # Códigos Assembly e C
├── circuit/        # Diagramas SimulIDE
├── docs/           # Documentação em Markdown
├── assets/         # Imagens e fotos
└── exemplos/       # Testes e códigos auxiliares
├── LICENSE
├── .gitignore
└── README.md

* Critérios adicionais de avaliação:
  * Organização clara.
  * Padronização de nomes.
  * Uso adequado de commits.

Todas as alterações no repositório devem ser realizadas até o dia 11/06, às 23:59. Após esse prazo, não é mais permitido alterar o repositório, e qualquer alteração realizada será desconsiderada.

---

## Etapa 2 - Apresentação em Sala (6,0 pontos)
* As apresentações ocorrerão em 2 dias:
  * Dia 1: 4 equipes.
  * Dia 2: 3 equipes.
* A ordem será definida por sorteio no início do 1º dia.
* Tempo máximo por dia: 110 minutos
* Distribuição de tempo por equipe (aproximadamente 27 minutos cada):
  * 5 minutos - Preparação.
  * 15 minutos - Apresentação.
  * 7 minutos - Comentários e dúvidas.

* Conteúdo obrigatório da apresentação:
  * Repositório no GitHub.
  * Todos os entregáveis da Etapa 1.
  * Demonstração do circuito físico funcional. O não funcionamento do circuito físico resultará em nota zero (0,0) para a equipe em todo o projeto, o que inclui ambas as etapas.
  * Explicações teóricas baseadas na documentação.
  * Participação de todos os integrantes. O não comparecimento de um integrante fará com que este tenha a nota de apresentação zerada (0,0), salvo se for apresentada justificativa válida pelo Art. 134. do REGPG da UFBA enviando e-mail para eucleriofilho@ufba.br.

* Critérios de avaliação:
  * Clareza e objetividade na apresentação.
  * Funcionamento correto do circuito físico.
  * Demonstração prática do circuito virtual.
  * Domínio teórico dos integrantes.
  * Organização e divisão de falas entre os membros.

* As apresentações ocorrerão nos dias 12/06 e 17/06, durante as aulas da disciplina.

---

### Capacidades Adquiridas
* Domínio prático da arquitetura ATMEGA328P.
* Uso de Assembly com interrupções e multiplexação.
* Integração eficiente entre Assembly e C.
* Construção de circuitos físicos e virtuais.
* Organização e documentação de projetos no GitHub.
* Apresentação técnica e defesa de projeto em equipe.

---

### Links Úteis
* Conjunto de Instruções do ATMEGA328P
* Manual do ATMEGA328P
* Diretivas da Arquitetura AVR
* Interrupções do ATMEGA328P