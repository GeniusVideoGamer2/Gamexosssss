.DEFAULT_GOAL := all
.PHONY: all check

all:
	bash ./build.sh

check:
	bash -n build.sh
	sh -n live-build/auto/config
	python3 -c 'import ast; ast.parse(open("live-build/config/includes.chroot/usr/share/gamexos/welcome.py", encoding="utf-8").read())'
	$(CC) -std=c11 -Wall -Wextra -Werror -fsyntax-only apps/*.c desktop/*.c dock/*.c hardware/*.c installer/*.c kernel/main.c recovery/*.c services/*.c ui/*.c
