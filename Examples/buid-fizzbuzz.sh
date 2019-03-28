#!/bin/sh
./.build/debug/minswift Examples/fizzbuzz.swift 2> Examples/fizzbuzz.ll &&
gcc -c Examples/fizzbuzz-driver.c -o Examples/fizzbuzz-driver.o &&
llc Examples/fizzbuzz.ll -o=Examples/fizzbuzz.s &&
clang -o Examples/fizzbuzz.out Examples/fizzbuzz-driver.o Examples/fizzbuzz.s
