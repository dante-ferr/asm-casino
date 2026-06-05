# ASM Casino

An AVR assembly casino game project designed for ATmega328P.

## Compilation and Build

The project is compiled using the `avra` assembler. A `Makefile` is provided at the root of the project to simplify the build process and clean up temporary files.

### Requirements

- `avra` (AVR Assembler)
- `make`

### Build Instructions

To compile the project and generate the target HEX file (`src/main.hex`):

```bash
make
```

This compiles the code and automatically removes any temporary intermediary files (such as `.obj`, `.lst`, `.cof`, `.eep`, etc.).

### Clean Instructions

To clean the target output and any remaining intermediary files:

```bash
make clean
```
