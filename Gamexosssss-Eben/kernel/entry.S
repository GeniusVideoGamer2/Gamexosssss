    .globl _start
_start:
    call kernel_main
1:
    jmp 1b
