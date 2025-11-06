# CoreMark-PRO Workload

## Description

EEMBC CoreMark-PRO benchmark suite, an extended version of CoreMark with additional workloads. It includes multiple benchmarks covering different aspects of processor performance such as compression, encryption, and signal processing.

This is a Linux workload.

## How it runs

The workload downloads and builds the CoreMark-PRO benchmark suite from source. It uses an inittab configuration that:

1. Executes the run.sh script which runs multiple benchmark executables sequentially.
2. Each benchmark is run with parameters `-c1 -w1 -v1` (single thread verification run).
3. If any benchmark fails, the system halts with the error code from that benchmark.
4. System is halted with nemu-halt after all benchmarks complete.
