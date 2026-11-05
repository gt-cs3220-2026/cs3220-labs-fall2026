 `include "define.vh" 

module FE_STAGE(
  input wire                              clk,
  input wire                              reset,
  input wire  [`from_DE_to_FE_WIDTH-1:0]  from_DE_to_FE,
  input wire  [`from_AGEX_to_FE_WIDTH-1:0] from_AGEX_to_FE,   
  input wire  [`from_MEM_to_FE_WIDTH-1:0] from_MEM_to_FE,   
  input wire  [`from_WB_to_FE_WIDTH-1:0]  from_WB_to_FE, 
  output wire [`FE_latch_WIDTH-1:0]       FE_latch_out
);

  `UNUSED_VAR (from_MEM_to_FE)
  `UNUSED_VAR (from_WB_to_FE)

  // I-MEM
  reg [`DBITS-1:0] imem [`IMEMWORDS-1:0];
 
  /*
  // Display memory contents with verilator 
  always @(posedge clk) begin
    for (integer i=0 ; i<`IMEMWORDS ; i=i+1) begin
        $display("%h", imem[i]);
    end
  end
  */

  /* pipeline latch */ 
  reg [`FE_latch_WIDTH-1:0] FE_latch;  // FE latch 
  wire valid_FE;

  reg [`DBITS-1:0] PC_FE_latch; // PC latch in the FE stage   // you could use a part of FE_latch as a PC latch as well 
  
  wire [`INSTBITS-1:0] inst_FE;  // instruction value in the FE stage 
  wire [`DBITS-1:0] pcplus_FE;  // pc plus value in the FE stage 
  wire stall_pipe_FE; // signal to indicate when a front-end needs to be stall
  
  wire [`FE_latch_WIDTH-1:0] FE_latch_contents;  // the signals that will be FE latch contents 
  
  // reading instruction from imem 
  // TODO: Assign external input to inst_FE
  assign inst_FE = imem[PC_FE_latch[`IMEMADDRBITS-1:`IMEMWORDBITS]];  // this code works. imem is stored 4B together
  
  // This is the value of "incremented PC", computed in the FE stage
  assign pcplus_FE = PC_FE_latch + `INSTSIZE;

  // Branch misprediction setup
  wire br_mispred_AGEX;  
  wire [`DBITS-1:0] br_target_AGEX;  
  
  assign {
    stall_pipe_FE
  } = from_DE_to_FE[0]; 
  
  assign {
    br_mispred_AGEX, 
    br_target_AGEX
  } = from_AGEX_to_FE;

  // Calculate next PC
  always @ (posedge clk) begin  
    if (reset) begin 
      PC_FE_latch <= `STARTPC;
    end else if (br_mispred_AGEX) begin
      PC_FE_latch <= br_target_AGEX;
    end else if (!stall_pipe_FE) begin 
      PC_FE_latch <= pcplus_FE; 
    end
  end
   
  // if you add more bits here, please increase the width of latch in define.vh
  // the order of latch contents should be matched in the decode stage when we extract the contents. 
  assign FE_latch_contents = {
    valid_FE,
    inst_FE, 
    PC_FE_latch, 
    pcplus_FE
  };

  // Update FE latch
  always @ (posedge clk) begin
    if (reset) begin 
      FE_latch <= 0; 
    end else begin 
      if (br_mispred_AGEX)
        FE_latch <= 0;
      else if (stall_pipe_FE)
        FE_latch <= FE_latch; 
      else 
        FE_latch <= FE_latch_contents; 
    end  
  end

  assign valid_FE = (| inst_FE);

  // send FE latch contents to next pipeline stage
  assign FE_latch_out = FE_latch;

endmodule
