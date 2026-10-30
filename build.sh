#!/bin/bash
set -e

mkdir -p build/isodir/boot/grub

gcc -m32 -ffreestanding -c kernel/main.c -o build/kernel.o

ld -m elf_i386 -Ttext 0x1000 -o build/kernel.bin build/kernel.o

cp build/kernel.bin build/isodir/boot/
cp boot/grub.cfg build/isodir/boot/grub/

grub-mkrescue -o GameXOSTR.iso build/isodir

echo "GameXOSTR ISO created!"
