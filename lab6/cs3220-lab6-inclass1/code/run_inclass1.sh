#!/bin/bash
# In-class 1: 2x2 array
rm -f results_*.log
rm -rf obj_dir
make systolic_array ROWS=2 COLS=2 K=2 NUM_TESTS=100 SEED=1 MULT_LAT=3
mv results.log results_2_2_2_100_1_3.log
rm -rf obj_dir
make systolic_array ROWS=2 COLS=2 K=2 NUM_TESTS=100 SEED=2 MULT_LAT=3
mv results.log results_2_2_2_100_2_3.log
rm -rf obj_dir
make systolic_array ROWS=2 COLS=2 K=2 NUM_TESTS=100 SEED=3 MULT_LAT=3
mv results.log results_2_2_2_100_3_3.log
rm -rf obj_dir
make systolic_array ROWS=2 COLS=2 K=2 NUM_TESTS=100 SEED=4 MULT_LAT=3
mv results.log results_2_2_2_100_4_3.log
rm -rf obj_dir
make systolic_array ROWS=2 COLS=2 K=2 NUM_TESTS=100 SEED=5 MULT_LAT=3
mv results.log results_2_2_2_100_5_3.log
echo "In-class 1: 2x2 array: expect 5 passes"
for f in results_*.log; do printf '%-32s ' $f; grep -q PASSED $f && echo PASSED || echo FAILED; done
echo "Total: $(grep -l PASSED results_*.log | wc -l) / 5"
