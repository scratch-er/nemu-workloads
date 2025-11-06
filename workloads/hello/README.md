# Hello Workload

## Description

A simple "Hello, World!" program that prints a greeting message. This is a minimal workload used for basic testing of running Linux on NEMU.

This is a Linux workload.

## How it runs

The workload compiles a simple C program that prints "Hello, argv[1]!" to the console. It uses an inittab configuration that:

1. Runs the hello program with "RISC-V" as an argument
2. Immediately halts the system after execution using nemu-halt
