// DESCRIPTION: simulation of the Task 8 one-bit PHT
//======================================================================
#include <iostream>
#include <cstdlib>
#include <verilated.h>
#include "VPHT_1BIT.h"

VPHT_1BIT dut;
unsigned counters[256] = {};
unsigned cycles = 0;
unsigned reset_predictions[256] = {};

void check() {
    if (dut.out != counters[dut.rd_sel]) {
        std::cout << "Failed: PHT_1BIT cycle=" << cycles
                  << " rd_sel=" << unsigned(dut.rd_sel)
                  << " expected=" << counters[dut.rd_sel]
                  << " actual=" << unsigned(dut.out) << std::endl;
        exit(1);
    }
}

void read(unsigned index) {
    dut.rd_sel = index;
    dut.eval();
    check();
}

void step(int reset, int enable, unsigned index, int data, unsigned rd_index) {
    ++cycles;
    dut.reset = reset;
    dut.wr_ena = enable;
    dut.wr_sel = index;
    dut.wr_data = data;
    dut.rd_sel = rd_index;
    dut.eval();
    // The task allows synchronous and asynchronous reset implementations.
    // Check normal writes before the edge; check reset after the rising edge.
    if (!reset) check();

    dut.clk = 1;
    if (reset) {
        for (unsigned i = 0; i < 256; ++i) counters[i] = reset_predictions[i];
    } else if (enable) {
        counters[index] = data;
    }
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
    dut.wr_sel = 0;
    dut.wr_data = 0;
    dut.rd_sel = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    // Task 8 does not prescribe the one-bit predictor's initial bias.
    // Learn each entry's initial state, then require reset to restore it.
    for (unsigned i = 0; i < 256; ++i) {
        dut.rd_sel = i;
        dut.eval();
        counters[i] = reset_predictions[i] = dut.out;
    }
    check();
    dut.clk = 0;
    dut.eval();
    for (unsigned i = 0; i < 256; ++i) read(i);

    // Every entry, state, and reset/enable/outcome combination.
    for (unsigned i = 0; i < 256; ++i) {
        for (int state = 0; state < 2; ++state) {
            for (int reset = 0; reset < 2; ++reset) {
                for (int enable = 0; enable < 2; ++enable) {
                    for (int data = 0; data < 2; ++data) {
                        step(0, 1, i, state, i);
                        step(reset, enable, i, data, i);
                        for (unsigned j = 0; j < 256; ++j) read(j);
                    }
                }
            }
        }
    }

    // Independent read and write indices, including same-address access.
    for (unsigned rd = 0; rd < 256; ++rd) {
        for (unsigned wr = 0; wr < 256; ++wr) {
            for (int data = 0; data < 2; ++data) {
                step(0, 1, wr, data, rd);
                read(wr);
            }
        }
    }

    // No update on a high clock level or a falling edge.
    step(1, 1, 255, 1, 255);
    step(0, 0, 255, !reset_predictions[255], 255);
    dut.clk = 1;
    dut.eval();
    dut.wr_ena = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    check();
    dut.final();
    std::cout << "Passed: PHT_1BIT (256 entries, all transitions and address pairs)\n";
    return 0;
}
