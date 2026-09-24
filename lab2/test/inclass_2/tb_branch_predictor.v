// Keep observation ports outside the submitted RTL and Verilator internals.
module tb_branch_predictor (
  input wire clk,
  input wire reset,
  output wire [31:0] pc, fetch_inst, fetch_id,
  output wire redirect, stall,
  output wire [31:0] gp,
  output wire [31:0] inst, branch_pc, branch_id, operand1, operand2,
  output wire branch_flag,
  output wire [31:0] actual_pc,
  output wire [31:0] branches, correct,
  output wire [31:0] retired_inst, retired_pc
);
  pipeline dut (.clk(clk), .reset(reset));
  assign pc = dut.my_FE_stage.PC_FE_latch;
  assign fetch_inst = dut.my_FE_stage.inst_FE;
  assign fetch_id = dut.my_FE_stage.inst_count_FE;
  assign redirect = dut.my_FE_stage.br_mispred_AGEX;
  assign stall = dut.my_FE_stage.stall_pipe_FE;
  assign gp = dut.my_WB_stage.last_WB_value[3];
  assign inst = dut.my_AGEX_stage.inst_AGEX;
  assign branch_pc = dut.my_AGEX_stage.PC_AGEX;
  assign branch_id = dut.my_AGEX_stage.inst_count_AGEX;
  assign operand1 = dut.my_AGEX_stage.regval1_AGEX;
  assign operand2 = dut.my_AGEX_stage.regval2_AGEX;
  assign branch_flag = dut.my_AGEX_stage.is_br_AGEX || dut.my_AGEX_stage.is_jmp_AGEX;
  assign actual_pc = dut.my_AGEX_stage.br_target_AGEX;
  assign branches = dut.my_AGEX_stage.branch_count;
  assign correct = dut.my_AGEX_stage.correct_branch_count;
  assign retired_inst = dut.my_WB_stage.inst_WB;
  assign retired_pc = dut.my_WB_stage.PC_WB;
endmodule
