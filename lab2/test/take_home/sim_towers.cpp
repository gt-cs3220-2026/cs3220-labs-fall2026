// DESCRIPTION: Towers accuracy measurement, ending at program completion.
//======================================================================
#include <iostream>
#include <iomanip>
#include <unordered_map>
#include <verilated.h>
#include "Vtb_towers.h"

#ifndef RUN_CYCLES
#define RUN_CYCLES 2000000
#endif

uint64_t timestamp = 0;
double sc_time_stamp() { return timestamp; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_towers* dut = new Vtb_towers();
    unsigned branches = 0, correct = 0, kernel_branches = 0, kernel_correct = 0;
    unsigned cycles = 0, instructions = 0;
    bool completed = false;
    std::unordered_map<uint32_t, uint32_t> fetched;

    for (unsigned cycle = 0; cycle < RUN_CYCLES + 3; ++cycle) {
        dut->reset = cycle < 3;
        dut->clk = 0;
        dut->eval();
        ++timestamp;

        if (!dut->reset) {
            ++cycles;
            instructions += dut->retired;
            if (dut->finished) {
                completed = true;
                break;
            }
            if (dut->branch) {
                auto prediction = fetched.find(dut->branch_id);
                if (prediction == fetched.end()) {
                    std::cout << "expected output: fetched branch\nactual output: missing fetch\n";
                    return 1;
                }
                bool hit = prediction->second == dut->actual_pc;
                ++branches;
                correct += hit;
                if (dut->branch_pc >= 0x4000 && dut->branch_pc < 0xa000) {
                    ++kernel_branches;
                    kernel_correct += hit;
                }
            }
            fetched.erase(dut->branch_id);
        }

        bool capture = !dut->reset && !dut->redirect && !dut->stall;
        uint32_t fetch_id = dut->fetch_id;
        if (dut->redirect) fetched.clear();
        dut->clk = 1;
        dut->eval();
        if (capture) fetched[fetch_id] = dut->fetch_pc;
        ++timestamp;
        if (Verilated::gotFinish()) break;
    }

    unsigned gp = dut->gp;
    dut->final();
    delete dut;

    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Branches=" << branches << " Correct=" << correct << '\n';
    std::cout << "KernelBranches=" << kernel_branches
              << " KernelCorrect=" << kernel_correct << '\n';
    std::cout << "Accuracy=" << (branches ? 100.0 * correct / branches : 0) << "%\n";
    std::cout << "KernelAccuracy="
              << (kernel_branches ? 100.0 * kernel_correct / kernel_branches : 0) << "%\n";
    std::cout << "Cycles=" << cycles << " Instructions=" << instructions
              << " CPI=" << (instructions ? double(cycles) / instructions : 0) << '\n';
    bool passed = completed && gp == 1 && kernel_branches > 0;
    if (passed) std::cout << "Passed!\n";
    else std::cout << "Failed. gp=" << gp
                   << (completed ? " (program completed)" : " (no completion marker)")
                   << '\n';
    return passed ? 0 : 1;
}
