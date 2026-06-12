; Driver da matriz de LED 8x8 MAX7219 via SPI por software
; Pinos usados: DIN no PC1, SCK no PC2, CS no PC3
; Usa um framebuffer na SRAM (RAM_SCREEN_BUF) para renderização estável

.include "hardware/max7219/driver.asm"
.include "hardware/max7219/icons.asm"
