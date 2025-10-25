WARN=-Wall -Wextra -Wno-unused-function -Wno-unused-parameter
CC=$(CROSS_COMPILE)gcc
CFLAGS=-march=rv64gcv -O3 ${WARN}

