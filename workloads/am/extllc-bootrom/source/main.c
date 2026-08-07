#include <klib.h>

void extllc_config_init(void);
void extllc_enter_payload(void) __attribute__((noreturn));

int main(void)
{
#ifdef BOOTROM_PRINT
    printf("ExtLLC bootrom: configuration start\n");
#endif

    extllc_config_init();

#ifdef BOOTROM_PRINT
    printf("ExtLLC bootrom: configuration complete\n");
#endif

    extllc_enter_payload();
}
