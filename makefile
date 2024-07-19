all: bootgame.img

bootloader : bootloader.asm
	nasm -o bootloader bootloader.asm

basketball : basketball.asm
	nasm -o basketball basketball.asm

bootgame.img : bootloader basketball
	dd if=bootloader of=bootgame.img
	dd if=basketball of=bootgame.img bs=512 seek=1

clean:
	rm bootloader basketball

