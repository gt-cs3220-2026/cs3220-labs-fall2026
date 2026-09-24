// DESCRIPTION: simulation of BHR
//======================================================================
#include <iostream>
#include <cstdlib>
#include <verilated.h>
#include "VBHR.h"

VBHR dut;
unsigned history = 0;

void check() {
    if (dut.out != history) {
        std::cout << "expected output: " << history << '\n'
                  << "actual output: " << unsigned(dut.out) << std::endl;
        exit(1);
    }
}

void step(int reset, int enable, int data) {
    dut.reset = reset;
    dut.wr_ena = enable;
    dut.wr_data = data;
    dut.eval();
    // The task allows synchronous and asynchronous reset implementations.
    // Check normal writes before the edge; check reset after the rising edge.
    if (!reset) check();

    dut.clk = 1;
    if (reset) history = 0;
    else if (enable) history = ((history << 1) | data) & 255;
    dut.eval();
    check();

    dut.clk = 0;
    dut.eval();
    check();
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    dut.clk = 0;
    dut.reset = 1;
    dut.wr_ena = 0;
    dut.wr_data = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();

    // Every history value and every reset/enable/data combination.
    for (unsigned value = 0; value < 256; ++value) {
        for (int reset = 0; reset < 2; ++reset) {
            for (int enable = 0; enable < 2; ++enable) {
                for (int data = 0; data < 2; ++data) {
                    for (int bit = 7; bit >= 0; --bit)
                        step(0, 1, (value >> bit) & 1);
                    step(reset, enable, data);
                }
            }
        }
    }

    // Changing inputs while the clock is high must not shift history.
    step(1, 1, 1);
    step(1, 1, 0);
    step(1, 0, 0);
    step(0, 0, 0);
    dut.clk = 1;
    dut.eval();
    dut.wr_ena = 1;
    dut.wr_data = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    check();

    dut.final();
    std::cout << "Passed!" << std::endl;
    return 0;
}
