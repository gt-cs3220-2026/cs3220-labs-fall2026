// DESCRIPTION: simulation of PHT
//======================================================================
#include <iostream>
#include <cstdlib>
#include <verilated.h>
#include "VPHT.h"

VPHT dut;
unsigned counters[256];

void check() {
    unsigned expected = counters[dut.rd_sel] >> 1;
    if (dut.out != expected) {
        std::cout << "expected output: " << expected << '\n'
                  << "actual output: " << unsigned(dut.out) << std::endl;
        exit(1);
    }
}

void read(unsigned index) {
    dut.rd_sel = index;
    dut.eval();
    check();
}

void step(int reset, int enable, unsigned index, int data, unsigned rd_index) {
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
        for (unsigned i = 0; i < 256; ++i) counters[i] = 1;
    } else if (enable) {
        if (data && counters[index] < 3) ++counters[index];
        if (!data && counters[index] > 0) --counters[index];
    }
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    check();
}

void set_counter(unsigned index, unsigned value) {
    while (counters[index] != value)
        step(0, 1, index, counters[index] < value, index);
}

// Distinguish 00 from 01, and 10 from 11 through the one-bit output.
// The second write restores the original counter value.
void probe(unsigned index) {
    int data = counters[index] < 2;
    step(0, 1, index, data, index);
    step(0, 1, index, !data, index);
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
    for (unsigned i = 0; i < 256; ++i) counters[i] = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    for (unsigned i = 0; i < 256; ++i) probe(i);

    // Every entry, counter state, and reset/enable/outcome combination.
    for (unsigned i = 0; i < 256; ++i) {
        for (unsigned state = 0; state < 4; ++state) {
            for (int reset = 0; reset < 2; ++reset) {
                for (int enable = 0; enable < 2; ++enable) {
                    for (int data = 0; data < 2; ++data) {
                        set_counter(i, state);
                        step(reset, enable, i, data, i);
                        probe(i);
                        for (unsigned j = 0; j < 256; ++j) read(j);
                    }
                }
            }
        }
    }

    // All read/write address pairs, in both prediction directions.
    for (unsigned rd = 0; rd < 256; ++rd) {
        for (unsigned wr = 0; wr < 256; ++wr) {
            for (int data = 0; data < 2; ++data) {
                set_counter(rd, data ? 1 : 2);
                set_counter(wr, data ? 1 : 2);
                step(0, 1, wr, data, rd);
                probe(rd);
                if (rd != wr) probe(wr);
            }
        }
    }

    // Repeated reset, including a simultaneous write.
    step(1, 1, 255, 1, 255);
    step(1, 1, 0, 1, 0);
    for (unsigned i = 0; i < 256; ++i) probe(i);

    // No write on a high clock level or a falling edge.
    step(0, 0, 0, 1, 0);
    dut.clk = 1;
    dut.eval();
    dut.wr_ena = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    check();

    dut.final();
    std::cout << "Passed!" << std::endl;
    return 0;
}
