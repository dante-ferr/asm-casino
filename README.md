# Roleta Francesa "En Prison" - Assembly AVR

Este projeto consiste em uma implementação em **Assembly AVR** da **Roleta Francesa** para o microcontrolador ATmega328P (utilizado no Arduino Uno), desenvolvida com foco em simulação no software **SimulIDE** e também compatível com hardware físico.

A roleta francesa neste projeto inclui regras clássicas de apostas (internas e externas) e a mecânica especial **"En Prison"** para resultados de valor zero em apostas simples.

---

## 📖 Documentação do Projeto

A documentação detalhada com guias de hardware, regras e organização do código está hospedada no GitHub Pages:

👉 **[Acesse a Documentação Online (GitHub Pages)](https://dante-ferr.github.io/asm-casino/)**

---

## ⚙️ Comandos do Makefile

O projeto inclui comandos no [Makefile](file:///home/dante/Code/projects/asm-casino/Makefile) para auxiliar na geração e visualização da documentação localmente utilizando o `mdBook`.

*   **`make docs`**:
    Compila a documentação a partir da pasta `/docs` e gera os arquivos estáticos HTML na pasta `/docs/book/`.
*   **`make docs-serve`**:
    Inicia um servidor web de desenvolvimento local (por padrão em `http://localhost:3000`) que atualiza automaticamente no navegador sempre que um arquivo de documentação for modificado.

---

## 👥 Autores

- **Dante Ferreira** ([dante-ferr](https://github.com/dante-ferr))
- **André Barata**
- **Guilherme Souza**
- **Paulo Ravazzano** ([Johannesgauss](https://github.com/Johannesgauss))
