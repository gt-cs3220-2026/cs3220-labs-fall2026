#!/bin/bash

set -uo pipefail
cd "$(dirname "$0")" || exit 1
part=${1:-}
selection=${2:-all}
failed=0
total=0

case $part in
    takehome) part=take_home ;;
    all)
        if [ "$selection" != all ]; then
            echo "Usage: $0 all" >&2
            exit 1
        fi
        for suite in inclass_1 inclass_2 take_home; do
            bash ./run_tests.sh "$suite" || failed=1
        done
        exit "$failed"
        ;;
esac

case "$part/$selection" in
    inclass_1/all) tests="bhr pht task3" ;;
    inclass_1/bhr|inclass_1/pht|inclass_1/task3) tests="$selection" ;;
    inclass_2/all) tests="task4 task5 task6" ;;
    inclass_2/task4|inclass_2/task5|inclass_2/task6) tests="$selection" ;;
    take_home/all) tests="task7 task8 task9" ;;
    take_home/task7|take_home/task8|take_home/task9) tests="$selection" ;;
    take_home/counter|take_home/btb) tests="$selection" ;;
    *) echo "Usage: $0 {inclass_1|inclass_2|take_home|all} [task or case]"; exit 1 ;;
esac

mkdir -p obj_dir || exit 1
: > "${part}_tests.log"
: > "${part}_results.log"

run_test() {
    local name=$1 target=$2 memory=${3:-} args=${4:-}
    local log="obj_dir/${part}_${name//\//_}.log" status=0
    echo "TESTING: $name" | tee -a "${part}_tests.log" "${part}_results.log"
    make tests TEST="$target" IDMEMINITFILE="$memory" RUN_ARGS="$args" TRACE=0 \
        > "$log" 2>&1 || status=1
    if [ "$status" -eq 0 ] && [ "$name" = task6/towers ]; then
        awk -f test/inclass_2/check_accuracy.awk "$log" > "${log}.accuracy" || status=1
        cat "${log}.accuracy" >> "$log"
    fi
    if [ "$status" -eq 0 ] && [ "$name" = task7/towers ]; then
        awk -f test/take_home/check_accuracy.awk "$log" > "${log}.accuracy" || status=1
        cat "${log}.accuracy" >> "$log"
    fi
    cat "$log" >> "${part}_tests.log"
    grep -E '^(Accuracy=|KernelAccuracy=|Branches=|KernelBranches=|Cycles=|PredictedBranches=)' \
        "$log" | tee -a "${part}_results.log"
    if [ "$status" -eq 0 ]; then
        echo "Passed!" | tee -a "${part}_results.log"
    else
        if grep -q '^expected output:' "$log"; then
            grep -E '^(expected output:|actual output:)' "$log" | head -2 | tee -a "${part}_results.log"
        else
            printf 'expected output: successful test\nactual output: build or simulation failed\n' | tee -a "${part}_results.log"
        fi
        failed=$((failed + 1))
    fi
    total=$((total + 1))
}

for testcase in $tests; do
    case $part in
        inclass_1)
            if [ "$testcase" = task3 ]; then
                for name in beq bne blt bgeu predict; do
                    run_test "task3/$name" task3 "test/inclass_1/task3/$name.mem"
                done
            else
                run_test "$testcase" "$testcase"
            fi
            ;;
        inclass_2)
            if [ "$testcase" = task4 ]; then
                run_test task4/btb btb
            elif [ "$testcase" = task5 ]; then
                for filename in test/inclass_2/task5/*.mem; do
                    name=$(basename "$filename" .mem)
                    args=
                    if [ "$name" = predict ]; then args=--require-prediction; fi
                    run_test "task5/$name" task5 "$filename" "$args"
                done
            else
                run_test task6/towers pipeline test/inclass_2/task6/towers.mem
            fi
            ;;
        take_home)
            case $testcase in
                task7) run_test task7/towers take_home test/take_home/towers/towers.mem ;;
                task8|task9) run_test "$testcase" "$testcase" ;;
                counter|btb) run_test "$testcase" take_home "test/take_home/${testcase}.mem" ;;
            esac
            ;;
    esac
done

echo "Total number of tests: $total" | tee -a "${part}_results.log"
echo "Number of passed tests: $((total - failed))" | tee -a "${part}_results.log"
echo "Number of failed tests: $failed" | tee -a "${part}_results.log"
test "$failed" -eq 0
