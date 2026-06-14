# Roleta Francesa - Assembly AVR

Este projeto consiste em uma implementação em Assembly AVR do jogo de cassino de Roleta Francesa, com a regra En Prison, para o Arduino UNO (com microcontrolador ATmega328P).

O circuito foi desenvolvido com o auxílio da simulação do SimulIDE, mas com aplicação principal em hardware físico.

---

## Documentação do Projeto

A documentação detalhada com guias de hardware, regras e estrutura de código está disponível em:

-> **[Acesse a Documentação Online](https://dante-ferr.github.io/asm-casino/)**

---

## Comandos de desenvolvimento

O projeto deve ser compilado utilizando o assembler `avra`. O `Makefile` fornece uma interface simples para compilar e gravar o código-fonte.

### Requisitos

- `avra` (AVR Assembler)
- `make`

### Como compilar

Rode o comando abaixo para compilar o código e gerar um arquivo HEX dentro da pasta `src`. Ele também remove automaticamente todos os arquivos intermediários gerados pelo assembler.

```bash
make
```

### Limpeza de arquivos temporários

Para remover o arquivo HEX gerado e limpar o ambiente de build, execute:

```bash
make clean
```

### Gravação no Hardware Físico (Upload / Update)

Execute o comando a seguir para compilar o código fonte com as configurações de hardware real (ativando a mochila do display LCD I2C `USE_PCF8574_BACKPACK = 1`) e injetar o firmware diretamente no Arduino Uno conectado via USB:

```bash
make upload
```

Esse script tentará detectar automaticamente a porta USB utilizada (como `/dev/ttyUSB0` ou `/dev/ttyACM0`). Se necessário, uma porta e uma taxa de transmissão pode ser manualmente especificada no seguinte comando:

```bash
make upload PORT=/dev/ttyUSB1 BAUD=57600
```

---

## Documentação Local (mdBook)

Caso prefira gerar ou visualizar a documentação localmente, os seguintes comandos possibilitam o uso local do `mdBook`:

* **`make docs`**: Compila a documentação a partir da pasta `/docs` e gera os arquivos estáticos na pasta `/docs/book/`.
* **`make docs-serve`**: Inicia um servidor web local em `http://localhost:3000`.
