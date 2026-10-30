#!/bin/bash
set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root_dir/build"
iso_dir="$build_dir/isodir"
kernel_path="$iso_dir/boot/kernel.elf"

mkdir -p "$iso_dir/boot/grub"

gcc -m32 -ffreestanding -fno-pie -fno-stack-protector \
	-c "$root_dir/kernel/main.c" -o "$build_dir/kernel.o"
gcc -m32 -ffreestanding -fno-pie \
	-c "$root_dir/kernel/entry.S" -o "$build_dir/entry.o"
ld -m elf_i386 -T "$root_dir/kernel/linker.ld" \
	-o "$kernel_path" "$build_dir/entry.o" "$build_dir/kernel.o"

grub-file --is-x86-multiboot "$kernel_path"
cp "$root_dir/boot/bootloader.cfg" "$iso_dir/boot/grub/grub.cfg"
grub-mkrescue -o "$root_dir/GameXOSTR.iso" "$iso_dir"

echo "GameXOSTR ISO created: $root_dir/GameXOSTR.iso"
