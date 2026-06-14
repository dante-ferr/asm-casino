# Roleta Francesa - Assembly AVR

Este projeto é uma implementação em Assembly AVR do jogo de Roleta Francesa para o microcontrolador ATmega328P (usado no Arduino Uno). O circuito e a simulação foram desenvolvidos no software SimulIDE, sendo também compatível com hardware físico.

A implementação inclui o sistema de apostas, além da regra especial "En Prison" para apostas simples quando o resultado é zero.

---

## 📖 Documentação do Projeto

A documentação detalhada com guias de hardware, regras e estrutura de código está disponível em:

👉 **[Acesse a Documentação Online](https://dante-ferr.github.io/asm-casino/)**

---

## 🛠️ Compilação e Build

O projeto é compilado utilizando o assembler `avra`. O `Makefile` na raiz facilita o processo de build e a limpeza de arquivos temporários.

### Requisitos

- `avra` (AVR Assembler)
- `make`

### Como compilar

Para compilar o código e gerar o arquivo HEX final (`src/main.hex`):

```bash
make
```

O comando acima compila o código-fonte e remove automaticamente os arquivos intermediários gerados pelo assembler (como `.obj`, `.lst`, `.cof`, `.eep`).

### Limpeza de arquivos temporários

Para remover o arquivo HEX gerado e limpar o ambiente de build:

```bash
make clean
```

### Gravação no Hardware Físico (Upload / Update)

Para compilar o código-fonte com as configurações de hardware real (ativando a mochila do display LCD I2C `USE_PCF8574_BACKPACK = 1`) e gravar o firmware diretamente no Arduino Uno conectado via USB:

```bash
make upload
```

O script do Makefile tentará detectar automaticamente a porta USB utilizada (como `/dev/ttyUSB0` ou `/dev/ttyACM0`). Se necessário, você pode especificar manualmente a porta e a taxa de transmissão:

```bash
make upload PORT=/dev/ttyUSB1 BAUD=57600
```

---

## ⚙️ Documentação Local (mdBook)

Se preferir gerar ou visualizar a documentação localmente utilizando o `mdBook`:

* **`make docs`**: Compila a documentação a partir da pasta `/docs` e gera os arquivos estáticos na pasta `/docs/book/`.
* **`make docs-serve`**: Inicia um servidor web local em `http://localhost:3000` com live-reload para edição da documentação em tempo real.
