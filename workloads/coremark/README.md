# CoreMark Workload

## Description

EEMBC CoreMark benchmark for measuring CPU performance. CoreMark is a small benchmark that measures the performance of embedded processors by running several tasks including list processing, matrix manipulation, and state machine execution.

This is a Linux workload.

## How it runs

The workload downloads and builds the CoreMark benchmark from source. It uses an inittab configuration that:

1. Runs the coremark executable with specific parameters for reproducible results
2. Halts the system with nemu-halt, passing the exit code from coremark

The benchmark runs with these parameters, which is a "standard" verification run of CoreMark:

- 0x0 0x0 0x66 0 7 1 2000
