`include "define.vh"

module tb_direction (
  input wire clk, reset,
  output wire [31:0] pc, fetch_inst, fetch_id, gp,
  output wire redirect, stall,
  output wire [31:0] inst, branch_pc, branch_id, operand1, operand2,
  output wire branch_flag,
  output wire [31:0] actual_pc, retired_inst,
  output wire [`BHR_WIDTH-1:0] history,
  output wire [`PHT_BITS-1:0] fetch_index, write_index,
  output wire prediction, bhr_write, pht_write, pht_data,
  output wire [31:0] bhr_data
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
  assign retired_inst = dut.my_WB_stage.inst_WB;
endmodule

// Observe module ports through any student-chosen instance names.
bind BHR task3_bhr_probe bhr_probe (.out(out), .wr_ena(wr_ena), .wr_data(wr_data));
bind PHT task3_pht_probe pht_probe (.rd_sel(rd_sel), .out(out),
    .wr_sel(wr_sel), .wr_ena(wr_ena), .wr_data(wr_data));

module task3_bhr_probe (
  input wire [`BHR_WIDTH-1:0] out,
  input wire wr_ena,
  input wire [31:0] wr_data
);
  assign tb_direction.history = out;
  assign tb_direction.bhr_write = wr_ena;
  assign tb_direction.bhr_data = wr_data;
endmodule

module task3_pht_probe (
  input wire [`PHT_BITS-1:0] rd_sel, wr_sel,
  input wire out, wr_ena, wr_data
);
  assign tb_direction.fetch_index = rd_sel;
  assign tb_direction.prediction = out;
  assign tb_direction.write_index = wr_sel;
  assign tb_direction.pht_write = wr_ena;
  assign tb_direction.pht_data = wr_data;
endmodule
