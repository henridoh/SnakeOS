# SnakeOS
___
SnakeOS is a simple snake-game that is its own BIOS-bootloader and fits entirely in a single boot sector.  
It is entirely written in 16-bit real-mode x86 assembly and uses BIOS-Interrupts for I/O.

### How to use it?  
1. Download this repository using `git clone https://github.com/henridoh/SnakeOS`
2. Enter the repository using `cd SnakeOS`
3. Use NASM to compile the code by typing `nasm -fbin snake-bootsector.asm`
4. Run the code in an emulator or flash it to a USB-stick and boot of it on real hardware.
