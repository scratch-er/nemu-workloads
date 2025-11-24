#include <stdio.h>

int main(int argc, char **argv) {
    const char *name = argc>=2 ? argv[1] : "world";
    printf("Hello, %s!\n", name);
    return 0;
}
