#include <array>
#include <cstdint>
#include <iostream>
#include <unordered_map>
#include <verilated.h>
#include "Vtb_direction.h"
#ifdef VCD_OUTPUT
#include <verilated_vcd_c.h>
#endif

static uint64_t timestamp = 0;
double sc_time_stamp() { return timestamp; }

static int32_t sign_extend(uint32_t value, unsigned bits) {
    return int32_t(value << (32 - bits)) >> (32 - bits);
}

// Decode the actual outcome independently of the predictor and redirect signal.
static bool resolve(uint32_t inst, uint32_t pc, uint32_t a, uint32_t b,
                    bool& taken, uint32_t& next) {
    taken = false;
    next = pc + 4;
    switch (inst & 0x7f) {
    case 0x63: {
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
        taken = true;
        next = pc + sign_extend(imm, 21);
        return true;
    }
    case 0x67:
        if (((inst >> 12) & 7) != 0) return false;
        taken = true;
        next = (a + sign_extend(inst >> 20, 12)) & ~uint32_t(1);
        return true;
    default: return false;
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_direction dut;
#ifdef VCD_OUTPUT
    Verilated::traceEverOn(true);
    VerilatedVcdC trace;
    dut.trace(&trace, 99);
    trace.open("trace.vcd");
#endif
    std::array<unsigned, 256> counters;
    counters.fill(1);
    unsigned history = 0;
    struct Fetch { uint32_t pc, inst, next_pc; unsigned index; };
    std::unordered_map<uint32_t, Fetch> fetched;
    bool healthy = true, finished = false;
    auto check = [&](const char* signal, uint32_t expected, uint32_t actual) {
        if (healthy && expected != actual) {
            std::cout << "expected output: " << signal << '=' << expected << '\n'
                      << "actual output: " << signal << '=' << actual << '\n';
            healthy = false;
        }
    };
    auto evaluate = [&]() {
        dut.eval();
#ifdef VCD_OUTPUT
        trace.dump(timestamp);
#endif
        ++timestamp;
    };
    auto check_fetch = [&]() {
        unsigned index = ((dut.pc >> 2) ^ history) & 255;
        unsigned prediction = counters[index] >> 1;
        check("BHR", history, dut.history);
        check("PHT read index", index, dut.fetch_index);
        check("prediction", prediction, dut.prediction);
    };

    dut.clk = 0;
    dut.reset = 1;
    for (unsigned cycle = 0; cycle < 100003 && healthy; ++cycle) {
        dut.reset = cycle < 3;
        dut.clk = 0;
        evaluate();
        if (dut.reset) {
            dut.clk = 1;
            evaluate();
            check_fetch();
            continue;
        }
        check_fetch();
        if (dut.retired_inst == 0x00000073) {
            finished = true;
            check("gp", 1, dut.gp);
            break;
        }

        bool taken;
        uint32_t next;
        bool branch = resolve(dut.inst, dut.branch_pc, dut.operand1,
                              dut.operand2, taken, next);
        check("branch", branch, dut.branch_flag);
        check("BHR write enable", branch, dut.bhr_write);
        check("PHT write enable", branch, dut.pht_write);
        bool redirect = false;
        unsigned update_index = 0;
        if (branch) {
            auto found = fetched.find(dut.branch_id);
            check("fetched branch", 1, found != fetched.end());
            if (found != fetched.end()) {
                const Fetch& fetch = found->second;
                check("branch PC", fetch.pc, dut.branch_pc);
                check("branch instruction", fetch.inst, dut.inst);
                check("PHT write index", fetch.index, dut.write_index);
                update_index = fetch.index;
                redirect = fetch.next_pc != next;
                fetched.erase(found);
            }
            check("actual PC", next, dut.actual_pc);
            check("BHR write data", taken, dut.bhr_data & 1);
            check("PHT write data", taken, dut.pht_data);
        }
        check("redirect", redirect, dut.redirect);

        uint32_t old_pc = dut.pc;
        uint32_t fetch_id = dut.fetch_id;
        Fetch fetch = {old_pc, dut.fetch_inst, 0, dut.fetch_index};
        bool stall = dut.stall;
        if (redirect)
            fetched.clear();
        if (branch) {
            history = ((history << 1) | taken) & 255;
            unsigned& counter = counters[update_index];
            if (taken && counter < 3) ++counter;
            if (!taken && counter > 0) --counter;
        }
        dut.clk = 1;
        evaluate();
        if (redirect)
            check("fetch PC", next, dut.pc);
        else if (stall)
            check("fetch PC", old_pc, dut.pc);
        else {
            fetch.next_pc = dut.pc;
            fetched[fetch_id] = fetch;
        }
        check_fetch();
        if (Verilated::gotFinish()) break;
    }
    check("retired ECALL", 1, finished);
    dut.final();
#ifdef VCD_OUTPUT
    trace.close();
#endif
    if (healthy) std::cout << "Passed!\n";
    return healthy ? 0 : 1;
}
