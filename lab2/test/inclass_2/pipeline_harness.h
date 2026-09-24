#ifndef LAB2_PIPELINE_HARNESS_H
#define LAB2_PIPELINE_HARNESS_H
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <unordered_map>
#include <verilated.h>
#include "Vtb_branch_predictor.h"
#ifdef VCD_OUTPUT
#include <verilated_vcd_c.h>
#endif

static uint64_t timestamp = 0;
double sc_time_stamp() { return timestamp; }

static int32_t sign_extend(uint32_t value, unsigned bits) {
    return int32_t(value << (32 - bits)) >> (32 - bits);
}

// RV32I oracle: do not trust the DUT's decoded branch flag/target/mispredict.
static bool resolved_next_pc(uint32_t inst, uint32_t pc, uint32_t a,
                             uint32_t b, uint32_t& next) {
    next = pc + 4;
    switch (inst & 0x7f) {
    case 0x63: {
        bool taken = false;
        switch ((inst >> 12) & 7) {
        case 0: taken = a == b; break;
        case 1: taken = a != b; break;
        case 4: taken = int32_t(a) < int32_t(b); break;
        case 5: taken = int32_t(a) >= int32_t(b); break;
        case 6: taken = a < b; break;
        case 7: taken = a >= b; break;
        default: return false;
        }
        uint32_t imm = ((inst >> 31) << 12) | (((inst >> 7) & 1) << 11)
                     | (((inst >> 25) & 63) << 5) | (((inst >> 8) & 15) << 1);
        if (taken) next = pc + sign_extend(imm, 13);
        return true;
    }
    case 0x6f: {
        uint32_t imm = ((inst >> 31) << 20) | (((inst >> 12) & 255) << 12)
                     | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 1023) << 1);
        next = pc + sign_extend(imm, 21);
        return true;
    }
    case 0x67:
        if (((inst >> 12) & 7) != 0) return false;
        next = (a + sign_extend(inst >> 20, 12)) & ~uint32_t(1);
        return true;
    default: return false;
    }
}

static int run_pipeline(int argc, char** argv, bool check_counters) {
    Verilated::commandArgs(argc, argv);
    bool require_prediction = false;
    bool require_nottaken_target = false;
    bool require_cold_pht = false;
    for (int i = 1; i < argc; ++i) {
        if (!std::strcmp(argv[i], "--require-prediction")) require_prediction = true;
        else if (!std::strcmp(argv[i], "--require-nottaken-target")) require_nottaken_target = true;
        else if (!std::strcmp(argv[i], "--require-cold-pht")) require_cold_pht = true;
        else {
            std::cerr << "Unknown argument: " << argv[i] << '\n';
            return 1;
        }
    }
    Vtb_branch_predictor dut;
#ifdef VCD_OUTPUT
    Verilated::traceEverOn(true);
    VerilatedVcdC trace;
    dut.trace(&trace, 99);
    trace.open("trace.vcd");
#endif
    struct Fetch { uint32_t pc, inst, predicted; };
    std::unordered_map<uint32_t, Fetch> fetched;
    uint32_t branches = 0, correct = 0, predicted_branches = 0;
    uint32_t probe_visits = 0;
    uint32_t loop_visits = 0;
    uint32_t cycles = 0;
    bool finished = false, healthy = true;
    auto fail = [&](const char* reason) {
        if (healthy)
            std::cerr << "Failed: " << reason << " at cycle " << cycles
                      << " AGEX_PC=0x" << std::hex << dut.branch_pc << std::dec << '\n';
        healthy = false;
    };
    auto evaluate = [&]() {
        dut.eval();
#ifdef VCD_OUTPUT
        trace.dump(timestamp);
#endif
        ++timestamp;
    };
    dut.clk = 0;
    dut.reset = 1;
    const uint32_t limit = check_counters ? 2000000 : 100000;
    for (uint32_t cycle = 0; cycle < limit + 3 && healthy; ++cycle) {
        dut.reset = cycle < 3;
        dut.clk = 0;
        evaluate();
        if (dut.reset) {
            dut.clk = 1;
            evaluate();
            if (check_counters && (dut.branches != 0 || dut.correct != 0))
                fail("accuracy counters must reset to zero");
            continue;
        }
        // Programs end with an ECALL marker. gp is a test number during the
        // instruction tests, so an early gp == 1 is NOT program completion.
        if (dut.retired_inst == 0x00000073) {
            finished = true;
            break;
        }
        ++cycles;
        uint32_t actual = 0;
        bool branch = resolved_next_pc(dut.inst, dut.branch_pc,
                                       dut.operand1, dut.operand2, actual);
        if (branch != bool(dut.branch_flag)) fail("incorrect branch/jump classification");
        if (!branch && dut.redirect) fail("redirect on a non-branch instruction");
        if (branch) {
            auto seen = fetched.find(dut.branch_id);
            if (seen == fetched.end() || seen->second.pc != dut.branch_pc ||
                seen->second.inst != dut.inst) {
                fail("resolved branch has no matching fetched instruction");
            } else {
                uint32_t predicted = seen->second.predicted;
                if (dut.actual_pc != actual) fail("incorrect resolved next PC");
                if (bool(dut.redirect) != (predicted != actual)) fail("incorrect misprediction recovery signal");
                ++branches;
                correct += predicted == actual;
                if (dut.branch_pc == 0x214 && actual == 0x20c && predicted == actual)
                    ++predicted_branches;
                if (require_cold_pht && dut.branch_pc == 0x214) {
                    ++loop_visits;
                    // Baseline Gshare only: after the first taken loop branch,
                    // BHR=1 selects a cold weak-NT counter on the second visit.
                    // The BTB now hits, so this distinguishes PHT gating from
                    // blindly predicting every BTB hit as taken.
                    if (loop_visits == 2 && predicted != 0x218)
                        fail("cold weak-not-taken PHT entry did not gate the BTB prediction");
                }
                if (require_nottaken_target && dut.branch_pc == 0x210) {
                    ++probe_visits;
                    if (probe_visits == 1 && actual != 0x214)
                        fail("BTB probe must first resolve not taken");
                    if (probe_visits == 2 && (actual != 0x680 || predicted != actual))
                        fail("target was not recorded when the branch was not taken");
                }
            }
        }
        uint32_t old_pc = dut.pc, old_inst = dut.fetch_inst, old_id = dut.fetch_id;
        bool redirect = dut.redirect, stall = dut.stall;
        dut.clk = 1;
        evaluate();
        if (redirect && dut.pc != actual) fail("FE did not apply the recovery next PC");
        if (!redirect && stall && dut.pc != old_pc) fail("FE advanced while stalled");
        if (!redirect && !stall) fetched[old_id] = {old_pc, old_inst, dut.pc};
        if (check_counters && (dut.branches != branches || dut.correct != correct)) {
            std::cerr << "Expected Branches=" << branches << " Correct=" << correct
                      << "; got Branches=" << dut.branches << " Correct=" << dut.correct << '\n';
            fail("accuracy counters disagree with independently observed next-PC predictions");
        }
        if (Verilated::gotFinish()) break;
    }
    if (!finished && healthy) fail("program did not retire its completion marker before timeout");
    if (finished && dut.gp != 1) fail("program result is not a pass");
    if (require_prediction && predicted_branches == 0) fail("no correct taken FE prediction for the loop");
    if (require_nottaken_target && probe_visits != 2) fail("BTB not-taken probe did not execute twice");
    if (require_cold_pht && loop_visits < 2) fail("cold PHT probe did not execute twice");
    if (check_counters) {
        std::cout << "Branches=" << branches << " Correct=" << correct << '\n';
        std::cout << std::fixed << std::setprecision(6)
                  << "Accuracy=" << (branches ? 100.0 * correct / branches : 0) << "%\n";
        std::cout << "CountersValidated=" << (healthy && finished ? 1 : 0) << '\n';
    }
    if (require_prediction) std::cout << "PredictedBranches=" << predicted_branches << '\n';
    std::cout << "Cycles=" << cycles << '\n';
    dut.final();
#ifdef VCD_OUTPUT
    trace.close();
#endif
    bool passed = healthy && finished;
    if (passed) std::cout << "Passed!\n";
    else std::cout << "Failed. gp=" << dut.gp << '\n';
    return passed ? 0 : 1;
}
#endif
