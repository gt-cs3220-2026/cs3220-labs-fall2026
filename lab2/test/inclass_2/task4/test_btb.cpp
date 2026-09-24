// DESCRIPTION: simulation of BTB
//======================================================================
#include <iostream>
#include <cstdlib>
#include <cstdint>
#include <verilated.h>
#include "VBTB.h"

VBTB dut;
struct Entry {
    bool valid;
    uint32_t tag;
    uint32_t target;
};
Entry entries[16] = {};

void check() {
    Entry entry = entries[(dut.rd_sel >> 2) & 15];
    bool hit = dut.rd_ena && entry.valid && entry.tag == (dut.rd_sel >> 6);
    if (dut.outs_valid != hit || (hit && dut.out_data != entry.target)) {
        std::cout << "expected output: valid=" << hit;
        if (hit) std::cout << ", target=0x" << std::hex << entry.target;
        std::cout << "\nactual output: valid=" << unsigned(dut.outs_valid);
        if (hit) std::cout << ", target=0x" << std::hex << dut.out_data;
        std::cout << std::dec << std::endl;
        exit(1);
    }
}

void read(uint32_t pc, int enable = 1) {
    dut.rd_sel = pc;
    dut.rd_ena = enable;
    dut.eval();
    check();
}

void step(int reset, int enable, uint32_t pc, uint32_t target,
          int rd_enable, uint32_t rd_pc) {
    dut.reset = reset;
    dut.wr_ena = enable;
    dut.wr_sel = pc;
    dut.wr_data = target;
    dut.rd_ena = rd_enable;
    dut.rd_sel = rd_pc;
    dut.eval();
    // The task allows synchronous and asynchronous reset implementations.
    // Check normal writes before the edge; check reset after the rising edge.
    if (!reset) check();

    dut.clk = 1;
    if (reset) {
        for (unsigned i = 0; i < 16; ++i) entries[i].valid = false;
    } else if (enable) {
        entries[(pc >> 2) & 15] = {true, pc >> 6, target};
    }
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    check();
}

void fill() {
    for (unsigned i = 0; i < 16; ++i)
        step(0, 1, i * 4, 0x80000000u + i * 4, 1, i * 4);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    dut.clk = 0;
    dut.reset = 1;
    dut.rd_ena = 1;
    dut.rd_sel = 0;
    dut.wr_ena = 0;
    dut.wr_sel = 0;
    dut.wr_data = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    check();
    dut.clk = 0;
    dut.eval();
    for (unsigned i = 0; i < 16; ++i) read(i * 4);

    // Every index and reset/read-enable/write-enable combination.
    for (unsigned i = 0; i < 16; ++i) {
        for (int reset = 0; reset < 2; ++reset) {
            for (int rd_enable = 0; rd_enable < 2; ++rd_enable) {
                for (int wr_enable = 0; wr_enable < 2; ++wr_enable) {
                    fill();
                    step(reset, wr_enable, i * 4, 0x12345678, rd_enable, i * 4);
                    for (unsigned j = 0; j < 16; ++j) {
                        read(j * 4, 0);
                        read(j * 4, 1);
                        read(j * 4 + 64, 1);
                    }
                }
            }
        }
    }

    // Every tag bit participates in matching and replacement.
    fill();
    for (unsigned i = 0; i < 16; ++i) {
        for (unsigned bit = 6; bit < 32; ++bit) {
            uint32_t pc = i * 4;
            uint32_t conflict = pc | (uint32_t(1) << bit);
            read(conflict);
            step(0, 1, conflict, 0x90000000u + i * 4, 1, pc);
            read(conflict);
            read(pc);
            for (unsigned j = 0; j < 16; ++j)
                if (j != i) read(j * 4);
            step(0, 1, pc, 0x80000000u + i * 4, 1, pc);
        }
    }

    // Every read/write index pair, with matching and conflicting tags.
    for (unsigned rd = 0; rd < 16; ++rd) {
        for (unsigned wr = 0; wr < 16; ++wr) {
            for (int conflict = 0; conflict < 2; ++conflict) {
                fill();
                uint32_t pc = wr * 4 + conflict * 64;
                for (int rd_enable = 0; rd_enable < 2; ++rd_enable) {
                    for (int wr_enable = 0; wr_enable < 2; ++wr_enable) {
                        step(0, wr_enable, pc, 0xA5A50000u + rd * 4,
                             rd_enable, rd * 4);
                        read(pc);
                        read(wr * 4);
                    }
                }
            }
        }
    }

    // Full-width target storage, including zero and every individual bit.
    uint32_t patterns[] = {0, 0xFFFFFFFFu, 0xAAAAAAAAu, 0x55555555u};
    for (unsigned i = 0; i < 16; ++i) {
        uint32_t pc = 0xFFFFFFC0u | (i * 4);
        for (uint32_t target : patterns)
            step(0, 1, pc, target, 1, pc);
        for (unsigned bit = 0; bit < 32; ++bit) {
            step(0, 1, pc, uint32_t(1) << bit, 1, pc);
            step(0, 1, pc, ~(uint32_t(1) << bit), 1, pc);
        }
    }

    step(1, 1, 0, 123, 1, 0);
    step(1, 1, 60, 456, 1, 60);
    for (unsigned i = 0; i < 16; ++i) {
        read(i * 4);
        read(0xFFFFFFC0u | (i * 4));
    }

    // No insertion on a high clock level or a falling edge.
    step(0, 0, 0, 123, 1, 0);
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
