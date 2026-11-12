
#
# DESCRIPTION: Verilator Example: Small Makefile
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# Copyright 2003-2018 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
######################################################################
# Check for sanity to avoid later confusion

.PHONY: default tests submit clean

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

######################################################################

# This is intended to be a minimal example.  Before copying this to start a
# real project, it is better to start with a more complete example,
# e.g. examples/tracing_c.

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package inatall, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif


PYTHON = python
VL_FLAGS_TEST_MAC += --exe -cc MAC.v --top-module mac --trace --trace-structs
VL_FLAGS_TEST_CTRL += --exe -cc ctrl.v --top-module ctrl --trace --trace-structs --timing 
VL_FLAGS_TEST_SYSTOLIC_ARRAY+= --exe -cc systolic_array.v --top-module systolic_array --trace --trace-structs #--timing
#VL_FLAGS += --assert -Wall -Wpedantic -Wno-DECLFILENAME -Wno-UNUSED --x-initial unique --x-assign unique
VL_FLAGS += --assert -Wpedantic -Wno-DECLFILENAME -Wno-UNUSED --x-initial unique --x-assign unique
CXXFLAGS += -DVCD_OUTPUT -DDPRINTF
#CXXFLAGS += -DVCD_OUTPUT 
LDFLAGS += 

# default test parameters
ROWS = 4
COLS = 5
K = 20
NUM_TESTS = 1
SEED = 1
MULT_LAT = 3 

CXXFLAGS_RxC = $(CXXFLAGS) -DROWS=$(ROWS) -DCOLS=$(COLS) -DK=$(K) -DMULT_LAT=$(MULT_LAT)

default:
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS_TEST_SYSTOLIC_ARRAY) $(VL_FLAGS) test_systolic_array.cpp systolic_array_4_4.v MAC.v ctrl.v -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vsystolic_array.mk 
	@echo "-- RUN ---------------------"
	obj_dir/Vsystolic_array
	@echo "-- DONE --------------------"
	
mac:
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS_TEST_MAC) $(VL_FLAGS) test_mac.cpp -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vmac.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vmac > mac.log
	@echo "-- DONE --------------------"

ctrl:
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS_TEST_CTRL) $(VL_FLAGS) test_ctrl.cpp -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vctrl.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vctrl
	@echo "-- DONE --------------------"

mac_fixed_input:
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS_TEST_MAC) $(VL_FLAGS) test_mac_fixed_input.cpp -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vmac.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vmac
	@echo "-- DONE --------------------"

ctrl_fixed_input:
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS_TEST_CTRL) $(VL_FLAGS) test_ctrl_fixed_input.cpp -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vctrl.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vctrl
	@echo "-- DONE --------------------"

systolic_array:
	@rm -rf obj_dir results.log
	@echo "-- VERILATE ----------------"
	$(PYTHON) data_gen.py \
		--mode gen_data \
		--a-size $(ROWS)x$(K) \
		--b-size $(K)x$(COLS) \
		--c-size $(ROWS)x$(COLS) \
		--num-tests $(NUM_TESTS) \
		--seed $(SEED)
	$(VERILATOR) $(VL_FLAGS_TEST_SYSTOLIC_ARRAY) $(VL_FLAGS) \
		-GROWS=$(ROWS) \
		-GCOLS=$(COLS) \
		-GMULT_LAT=$(MULT_LAT) \
		-GK=$(K) \
		test_systolic_array.cpp MAC.v ctrl.v adder.v multiplier.v synchronus_fifo.v -CFLAGS '$(CXXFLAGS_RxC)' 
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 32 -C obj_dir -f Vsystolic_array.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vsystolic_array
	$(PYTHON) data_gen.py \
		--mode verify \
		--a-size $(ROWS)x$(K) \
		--b-size $(K)x$(COLS) \
		--c-size $(ROWS)x$(COLS) \
		--num-tests $(NUM_TESTS) \
		> results.log
	@echo "-- DONE --------------------"

submit: 
	@echo "-- ZIPPING ALL THE FILE ---------"
	zip submission.zip ./*.v ./*.vh

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir *.log *.dmp *.vpd *.bin core trace.vcd *.log
