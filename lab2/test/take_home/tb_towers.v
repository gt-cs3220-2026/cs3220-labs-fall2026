// Measure resolved next-PC predictions through the supplied pipeline signals.
module tb_towers (
  input wire clk,
  input wire reset,
  output wire [31:0] gp,
  output wire branch,
  output wire [31:0] branch_pc,
  output wire [31:0] fetch_pc, fetch_id, branch_id,
  output wire stall, redirect,
  output wire [31:0] actual_pc,
  output wire retired,
  output wire finished
);
  pipeline dut (.clk(clk), .reset(reset));

  assign gp = dut.my_WB_stage.last_WB_value[3];
  // Decode the instruction independently: incorrect DUT branch flags or
  // target logic must not make the reported accuracy look better.
  wire [31:0] inst = dut.my_AGEX_stage.inst_AGEX;
  wire [31:0] rs1 = dut.my_AGEX_stage.regval1_AGEX;
  wire [31:0] rs2 = dut.my_AGEX_stage.regval2_AGEX;
  wire conditional = inst[6:0] == 7'h63;
  wire jal = inst[6:0] == 7'h6f;
  wire jalr = inst[6:0] == 7'h67 && inst[14:12] == 3'b000;
  wire [31:0] b_imm = {{19{inst[31]}}, inst[31], inst[7],
                      inst[30:25], inst[11:8], 1'b0};
  wire [31:0] j_imm = {{11{inst[31]}}, inst[31], inst[19:12],
                      inst[20], inst[30:21], 1'b0};
  wire [31:0] i_imm = {{20{inst[31]}}, inst[31:20]};
  reg taken;
  always @(*) begin
    case (inst[14:12])
      3'b000: taken = rs1 == rs2;
      3'b001: taken = rs1 != rs2;
      3'b100: taken = $signed(rs1) < $signed(rs2);
      3'b101: taken = $signed(rs1) >= $signed(rs2);
      3'b110: taken = rs1 < rs2;
      3'b111: taken = rs1 >= rs2;
      default: taken = 1'b0;
    endcase
  end
  assign branch = conditional || jal || jalr;
  assign branch_pc = dut.my_AGEX_stage.PC_AGEX;
  assign fetch_pc = dut.my_FE_stage.PC_FE_latch;
  assign fetch_id = dut.my_FE_stage.inst_count_FE;
  assign branch_id = dut.my_AGEX_stage.inst_count_AGEX;
  assign stall = dut.my_FE_stage.stall_pipe_FE;
  assign redirect = dut.my_FE_stage.br_mispred_AGEX;
  assign actual_pc = jalr ? ((rs1 + i_imm) & 32'hfffffffe) :
                     jal ? branch_pc + j_imm :
                     conditional && taken ? branch_pc + b_imm : branch_pc + 4;
  // The supplied pipeline represents flushed instructions with zero.
  assign retired = dut.my_WB_stage.inst_WB != 0;
  // crt.S emits ECALL after writing the result to gp. Waiting for this
  // instruction also permits programs to use gp before their final result.
  assign finished = dut.my_WB_stage.inst_WB == 32'h00000073;
endmodule
