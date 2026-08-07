#include <am.h>
#include <stdint.h>

extern char sdata;
extern char edata;
extern char _sidata;
extern char _bss_start;
extern char _bss_end;
extern char _heap_start;
extern char _pmem_end;

int main(void);
void __am_init_16550(void);
void __am_16550_putchar(char ch);

_Area _heap = {
    .start = &_heap_start,
    .end = &_pmem_end,
};

void _putc(char ch)
{
#ifdef UART16550
    __am_16550_putchar(ch);
#else
    (void)ch;
#endif
}

void _halt(int code)
{
    (void)code;
    for (;;) {
        __asm__ volatile("wfi");
    }
}

static void copy_data(void)
{
    char *src = &_sidata;
    char *dst = &sdata;

    while (dst != &edata) {
        *dst++ = *src++;
    }
}

static void clear_bss(void)
{
    char *dst = &_bss_start;

    while (dst != &_bss_end) {
        *dst++ = 0;
    }
}

void _trm_init(void)
{
    copy_data();
    clear_bss();

#ifdef UART16550
    __am_init_16550();
#endif

    _halt(main());
}
