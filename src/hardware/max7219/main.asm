; MAX7219 8x8 LED matrix driver via software SPI
; Pins used: DIN on PC1, SCK on PC2, CS on PC3
; Uses a framebuffer in SRAM (RAM_SCREEN_BUF) for stable rendering

.include "hardware/max7219/driver.asm"
.include "hardware/max7219/icons.asm"
