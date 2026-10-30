void kernel_main(void)
{
	volatile unsigned short *video_memory = (volatile unsigned short *)0xB8000;
	const char message[] = "GameXOSTR booted";

	for (unsigned int index = 0; message[index] != '\0'; index++) {
		video_memory[index] = (unsigned short)(0x0700 | message[index]);
	}

	while (1) {
		__asm__ volatile ("hlt");
	}
}
