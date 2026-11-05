 `include "define.vh" 

module WB_STAGE(
  input wire                              clk,
  input wire                              reset,  
  input wire [`MEM_latch_WIDTH-1:0]       from_MEM_latch,
  output wire [`from_WB_to_FE_WIDTH-1:0]  from_WB_to_FE,
  output wire [`from_WB_to_DE_WIDTH-1:0]  from_WB_to_DE,  
  output wire [`from_WB_to_AGEX_WIDTH-1:0] from_WB_to_AGEX,
  output wire [`from_WB_to_MEM_WIDTH-1:0] from_WB_to_MEM,
  output reg [31:0] reg10_val
);

  wire valid_WB;
  wire [`INSTBITS-1:0] inst_WB;   
  wire [`DBITS-1:0] PC_WB;
  wire [`IOPBITS-1:0] op_I_WB;
  
  wire wr_reg_WB; // is this instruction writing into a register file? 
  
  wire [`REGNOBITS-1:0] wregno_WB; // destination register ID 
  wire [`DBITS-1:0] regval_WB;  // the contents to be wraitten in the register file (or CSR )
  
  wire [`DBITS-1:0] aluout_WB;
  wire [`DBITS-1:0] rd_val_WB;
  
  assign {
    valid_WB,
    inst_WB,
    PC_WB,
    op_I_WB,
    rd_val_WB, 
    aluout_WB, 
    wr_reg_WB,
    wregno_WB
  } = from_MEM_latch; 
        
  assign regval_WB = (op_I_WB == `LW_I) ? rd_val_WB : aluout_WB;

  // forward signals to DE stage
  assign from_WB_to_DE = {
    wr_reg_WB, 
    wregno_WB, 
    regval_WB
  }; 

  // forward signals to FE stage
  assign from_WB_to_FE = 0;

  // forward signals to AGEX stage
  assign from_WB_to_AGEX = 0;

  // forward signals to MEM stage
  assign from_WB_to_MEM = 0;

  // this code need to be commented out when we synthesize the code later 
  // special workaround to get tests Pass/Fail status
  reg [31:0] last_WB_value [`REGWORDS-1:0] /* verilator public */;
  always @(negedge clk) begin
    if (reset) begin: reset_block_1
      integer i;
      for (i = 0; i < `REGWORDS; i=i+1) begin
        last_WB_value[i] <= 0;
      end
    end else begin
      if (wr_reg_WB) begin
        last_WB_value[wregno_WB] <= regval_WB;
      end
    end
  end

  // this is only for debugging purpose to interact with sim_main.cpp when we use verilator 
  reg [31:0] WB_counters [`WBCOUNTERS-1:0]/* verilator public */;
  always @(posedge clk) begin
    if (reset) begin: reset_block_2
      integer i;
      for (i = 0; i < `REGWORDS; i=i+1) begin
        WB_counters[i] <= 0;
      end
    end else begin
      WB_counters[0] <= valid_WB;
      WB_counters[1] <= PC_WB;   
      WB_counters[2] <= inst_WB;   
      WB_counters[3] <= op_I_WB; 
      WB_counters[4] <= wr_reg_WB;
      WB_counters[5] <= wregno_WB;
      WB_counters[6] <= regval_WB;
      WB_counters[7] <= 0;
    end
  end
  
  always @(posedge clk) begin
    if (reset) begin
        reg10_val <= 0;
    end
    else begin
        if (wr_reg_WB && wregno_WB == 10)
            reg10_val <= regval_WB;
    end
  end

endmodule 
