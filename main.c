void kernel_main()
{
    char *video = (char*)0xb8000;

    char text[] =
    "GAME X O S T R\n"
    "Liquid Glass System Starting...";

    int i = 0;

    while(text[i])
    {
        video[i*2] = text[i];
        video[i*2+1] = 0x07;
        i++;
    }

    while(1){}
}
