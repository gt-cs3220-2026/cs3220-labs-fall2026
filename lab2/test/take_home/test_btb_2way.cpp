// DESCRIPTION: simulation of the Task 9 two-way BTB
//======================================================================
#include <iostream>
#include <cstdlib>
#include <cstdint>
#include <verilated.h>
#include "VBTB_2WAY.h"

VBTB_2WAY dut;
unsigned cycles = 0;

void fail(const char* message) {
    std::cout << "Failed: BTB_2WAY cycle=" << cycles
              << " clk=" << int(dut.clk) << " reset=" << int(dut.reset)
              << " rd_ena=" << int(dut.rd_ena) << " wr_ena=" << int(dut.wr_ena)
              << " rd_pc=0x" << std::hex << dut.rd_sel
              << " wr_pc=0x" << dut.wr_sel << std::dec
              << " " << message << std::endl;
    exit(1);
}

bool lookup(uint32_t pc, uint32_t target, int enable = 1) {
    dut.rd_sel = pc;
    dut.rd_ena = enable;
    dut.eval();
    if (dut.outs_valid && dut.out_data != target) fail("wrong target");
    return dut.outs_valid;
}

void read(uint32_t pc, bool hit, uint32_t target = 0, int enable = 1) {
    if (lookup(pc, target, enable) != hit) fail("wrong hit/miss");
}

void step(int reset, int enable, uint32_t pc, uint32_t target) {
    ++cycles;
    dut.eval();
    bool old_valid = dut.outs_valid;
    uint32_t old_target = dut.out_data;
    dut.reset = reset;
    dut.wr_ena = enable;
    dut.wr_sel = pc;
    dut.wr_data = target;
    dut.eval();
    // Reset timing is unspecified; synchronous and asynchronous resets are valid.
    if (!reset && (dut.outs_valid != old_valid || (old_valid && dut.out_data != old_target)))
        fail("state changed before the rising edge");
    dut.clk = 1;
    dut.eval();
    dut.clk = 0;
    dut.eval();
}

void fill() {
    step(1, 0, 0, 0);
    for (unsigned i = 0; i < 8; ++i) {
        step(0, 1, i * 4, 0x80000000u + i * 4);
        step(0, 1, 32 + i * 4, 0x90000000u + i * 4);
    }
}

void stress_replacement() {
    uint32_t pcs[8][2], targets[8][2];
    fill();
    for (unsigned set = 0; set < 8; ++set) {
        pcs[set][0] = set * 4;
        pcs[set][1] = 32 + set * 4;
        targets[set][0] = 0x80000000u + set * 4;
        targets[set][1] = 0x90000000u + set * 4;
    }
    for (unsigned round = 0; round < 32; ++round) {
        for (unsigned set = 0; set < 8; ++set) {
            uint32_t pc = (round + 2) * 32 + set * 4;
            uint32_t target = 0xa5000000u ^ (pc << 3);
            // A disabled insertion must not evict either resident entry.
            step(0, 0, pc, target);
            read(pc, false);
            for (unsigned way = 0; way < 2; ++way)
                read(pcs[set][way], true, targets[set][way]);

            // Disabled reads must not suppress writes.
            dut.rd_ena = round & 1;
            dut.rd_sel = pcs[(set + 1) % 8][0];
            step(0, 1, pc, target);
            read(pc, true, target);
            bool first = lookup(pcs[set][0], targets[set][0]);
            bool second = lookup(pcs[set][1], targets[set][1]);
            if (first == second) fail("replacement must retain exactly one old entry");
            unsigned evicted = first ? 1 : 0;
            pcs[set][evicted] = pc;
            targets[set][evicted] = target;

            // Rewriting either resident tag must preserve the other tag.
            for (unsigned way = 0; way < 2; ++way) {
                targets[set][way] ^= 0x55555555u;
                step(0, 1, pcs[set][way], targets[set][way]);
                for (unsigned other = 0; other < 8; ++other)
                    for (unsigned w = 0; w < 2; ++w)
                        read(pcs[other][w], true, targets[other][w]);
            }
        }
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    dut.clk = 0;
    dut.rd_ena = 0;
    dut.rd_sel = 0;
    step(1, 1, 0, 0xffffffffu);
    for (unsigned i = 0; i < 8; ++i) {
        read(i * 4, false);
        read(32 + i * 4, false);
    }

    // Both ways in all sets coexist. Updating one tag preserves the other.
    fill();
    for (unsigned i = 0; i < 8; ++i) {
        read(i * 4, true, 0x80000000u + i * 4);
        read(32 + i * 4, true, 0x90000000u + i * 4);
        read(i * 4, false, 0, 0);
        step(0, 1, i * 4, 0xa5a50000u + i * 4);
        read(i * 4, true, 0xa5a50000u + i * 4);
        read(32 + i * 4, true, 0x90000000u + i * 4);
        step(0, 0, 32 + i * 4, 0);
        read(32 + i * 4, true, 0x90000000u + i * 4);
    }

    // A third tag evicts exactly one old tag; any replacement policy is valid.
    for (unsigned i = 0; i < 8; ++i) {
        fill();
        step(0, 1, 64 + i * 4, 0x12345678);
        read(64 + i * 4, true, 0x12345678);
        bool first = lookup(i * 4, 0x80000000u + i * 4);
        bool second = lookup(32 + i * 4, 0x90000000u + i * 4);
        if (first == second) fail("a full set must replace exactly one way");
        for (unsigned j = 0; j < 8; ++j) {
            if (j != i) {
                read(j * 4, true, 0x80000000u + j * 4);
                read(32 + j * 4, true, 0x90000000u + j * 4);
            }
        }
    }

    // Every tag bit and every target bit is significant.
    for (unsigned i = 0; i < 8; ++i) {
        for (unsigned bit = 5; bit < 32; ++bit) {
            uint32_t pc = i * 4;
            uint32_t other = pc | (uint32_t(1) << bit);
            step(1, 0, 0, 0);
            step(0, 1, pc, 0);
            read(other, false);
            step(0, 1, other, 0xffffffffu);
            read(pc, true, 0);
            read(other, true, 0xffffffffu);
            for (unsigned target_bit = 0; target_bit < 32; ++target_bit) {
                uint32_t target = uint32_t(1) << target_bit;
                step(0, 1, pc, target);
                read(pc, true, target);
                read(other, true, 0xffffffffu);
                step(0, 1, other, ~target);
                read(other, true, ~target);
                read(pc, true, target);
                step(0, 1, other, 0xffffffffu);
            }
        }
    }

    stress_replacement();

    // Reset takes priority and clears all populated ways.
    fill();
    step(1, 1, 0, 0xffffffffu);
    for (unsigned i = 0; i < 8; ++i) {
        read(i * 4, false);
        read(32 + i * 4, false);
    }
    step(0, 0, 0, 123);
    dut.clk = 1;
    dut.eval();
    dut.wr_ena = 1;
    dut.eval();
    read(0, false);
    dut.clk = 0;
    dut.eval();
    read(0, false);
    dut.final();
    std::cout << "Passed: BTB_2WAY (8 sets, 2 ways, tags, targets and replacement)\n";
    return 0;
}
