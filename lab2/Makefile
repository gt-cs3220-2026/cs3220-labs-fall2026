# gt-cs3220: Lab 2 build and test driver

.DEFAULT_GOAL := default
TEST ?= pipeline
CASE ?= towers
RTL_DIR ?= .
BUILD_DIR ?= obj_dir/$(TEST)
TRACE ?= 1

TOP_bhr = BHR
TOP_pht = PHT
TOP_btb = BTB
TOP_task3 = tb_direction
TOP_task5 = tb_branch_predictor
TOP_pipeline = tb_branch_predictor
TOP_take_home = tb_towers
TOP_task8 = PHT_1BIT
TOP_task9 = BTB_2WAY
TOP = $(TOP_$(TEST))
ifeq ($(strip $(TOP)),)
$(error Unknown TEST '$(TEST)')
endif

SIM_bhr = test/inclass_1/test_bhr.cpp
SIM_pht = test/inclass_1/test_pht.cpp
SIM_btb = test/inclass_2/task4/test_btb.cpp
SIM_task3 = test/inclass_1/task3/sim_direction.cpp
SIM_task5 = test/inclass_2/sim_task5.cpp
SIM_pipeline = sim_main.cpp
SIM_take_home = test/take_home/sim_towers.cpp
SIM_task8 = test/take_home/test_pht_1bit.cpp
SIM_task9 = test/take_home/test_btb_2way.cpp
EXTRA_task5 = test/inclass_2/tb_branch_predictor.v
EXTRA_task3 = test/inclass_1/task3/tb_direction.v
EXTRA_pipeline = test/inclass_2/tb_branch_predictor.v
EXTRA_take_home = test/take_home/tb_towers.v
SOURCES = pipeline.v fe_stage.v de_stage.v agex_stage.v mem_stage.v wb_stage.v
ifneq ($(filter $(TEST),bhr pht btb task8 task9),)
SOURCES = fe_stage.v
endif

ifeq ($(VERILATOR_ROOT),)
VERILATOR ?= verilator
else
VERILATOR ?= $(VERILATOR_ROOT)/bin/verilator
endif

VL_FLAGS = --exe -cc --assert -Wno-fatal --unroll-count 1024 --trace --trace-structs
ifeq ($(TEST),task3)
IDMEMINITFILE ?= test/inclass_1/task3/predict.mem
endif
CXXFLAGS += -DDPRINTF
ifeq ($(TRACE),1)
CXXFLAGS += -DVCD_OUTPUT
endif

ifeq ($(TEST),take_home)
ifeq ($(CASE),towers)
IDMEMINITFILE ?= test/take_home/towers/towers.mem
else
IDMEMINITFILE ?= test/take_home/$(CASE).mem
endif
endif
ifdef IDMEMINITFILE
MEM_FLAGS = '+define+IDMEMINITFILE="$(abspath $(BUILD_DIR))/program.mem"'
endif

.PHONY: default tests programs submit clean
default: tests

tests:
	mkdir -p "$(BUILD_DIR)"
ifdef IDMEMINITFILE
	cp "$(IDMEMINITFILE)" "$(BUILD_DIR)/program.mem"
endif
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VL_FLAGS) --top-module $(TOP) $(MEM_FLAGS) \
		-I$(abspath $(RTL_DIR)) $(addprefix $(abspath $(RTL_DIR))/,$(SOURCES)) \
		$(EXTRA_$(TEST)) $(abspath $(SIM_$(TEST))) \
		--Mdir $(BUILD_DIR) -CFLAGS '$(CXXFLAGS)'
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 4 -C $(BUILD_DIR) -f V$(TOP).mk
	@echo "-- RUN ---------------------"
	$(BUILD_DIR)/V$(TOP) $(RUN_ARGS)

# Rebuild the take-home memory images when changing their source programs.
RISCV ?= /opt/riscv-gnu-toolchain
RISCV_PREFIX ?= $(RISCV)/bin/riscv32-unknown-elf-
RISCV_GCC_OPTS ?= -march=rv32im -mabi=ilp32 -mcmodel=medany -mno-relax \
	-msmall-data-limit=0 -O2 -ffreestanding -fno-builtin -nostdlib -nostartfiles
PROGRAM_DIR = test/take_home
PROGRAMS = $(addprefix $(PROGRAM_DIR)/,counter btb towers/towers)
programs: $(addsuffix .mem,$(PROGRAMS)) $(addsuffix .dump,$(PROGRAMS))

$(PROGRAM_DIR)/%.elf: $(PROGRAM_DIR)/%.S $(PROGRAM_DIR)/towers.c $(PROGRAM_DIR)/crt.S $(PROGRAM_DIR)/link.ld
	$(RISCV_PREFIX)gcc $(RISCV_GCC_OPTS) -T $(PROGRAM_DIR)/link.ld \
		$(PROGRAM_DIR)/crt.S $(PROGRAM_DIR)/towers.c $< -o $@

$(PROGRAM_DIR)/%.mem: $(PROGRAM_DIR)/%.elf $(PROGRAM_DIR)/bin_to_mem.py
	$(RISCV_PREFIX)objcopy -O binary $< $(@:.mem=.bin)
	python3 $(PROGRAM_DIR)/bin_to_mem.py $(@:.mem=.bin) $@

$(PROGRAM_DIR)/%.dump: $(PROGRAM_DIR)/%.elf
	$(RISCV_PREFIX)objdump -d $< > $@

submit:
	rm -f submission.zip
	zip -r submission.zip *.v *.vh sim_main.cpp Makefile run_tests.sh \
		test/inclass_1 test/inclass_2 test/take_home test/include \
		-x '*/obj_dir/*' '*.log' '*.elf' '*.bin' '*.dump'

clean:
	rm -rf obj_dir *.log trace.vcd
	rm -f $(PROGRAM_DIR)/*.elf $(PROGRAM_DIR)/*.bin $(PROGRAM_DIR)/*.dump
	rm -f $(PROGRAM_DIR)/towers/*.elf $(PROGRAM_DIR)/towers/*.bin $(PROGRAM_DIR)/towers/*.dump
