__attribute__((__noreturn__))
void halt(int code) {
    asm volatile("mv a0, %0; .word 0x0000006b" : :"r"(code));
    while (1);
}

int atoi_lite(char *a) {
    int ans = 0;
    for (int i=0; a[i]; ++i) {
        ans = (ans<<3) + (ans<<1);
        ans = ans + a[i] - '0';
    }
    return ans;
}

int main(int argc, char** argv) {
    if (argc <= 1) {
        halt(0);
    } else {
        halt(atoi_lite(argv[1]));
    }
}
