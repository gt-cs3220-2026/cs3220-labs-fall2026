 `include "define.vh" 

module MEM_STAGE(
  input wire                              clk,
  input wire                              reset,
  input wire  [`from_WB_to_MEM_WIDTH-1:0] from_WB_to_MEM,  
  input wire  [`AGEX_latch_WIDTH-1:0]     from_AGEX_latch, 
  output wire [`MEM_latch_WIDTH-1:0]      MEM_latch_out,
  output wire [`from_MEM_to_FE_WIDTH-1:0] from_MEM_to_FE,
  output wire [`from_MEM_to_DE_WIDTH-1:0] from_MEM_to_DE,
  output wire [`from_WB_to_AGEX_WIDTH-1:0] from_MEM_to_AGEX
);

  `UNUSED_VAR (from_WB_to_MEM)

  // D-MEM
  reg [`DBITS-1:0] dmem[`DMEMWORDS-1:0];
 
  
  reg [`MEM_latch_WIDTH-1:0] MEM_latch; 
  wire valid_MEM;

  wire[`MEM_latch_WIDTH-1:0] MEM_latch_contents;
  wire [`IOPBITS-1:0] op_I_MEM;
  wire [`INSTBITS-1:0] inst_MEM; 
  wire [`DBITS-1:0] PC_MEM;

  wire [`DBITS-1:0] memaddr_MEM; // memory address. need to be computed in AGEX stage and pass through a latch 
  wire [`DBITS-1:0] rd_val_MEM;  // memory read value 
  wire [`DBITS-1:0] aluout_MEM;  // memory write value 
  wire wr_mem_MEM;  // is this instruction writing a value into memory? 

  // Read from D-MEM  (read code is completed if there is a correct memaddr_MEM ) 
  assign rd_val_MEM = dmem[memaddr_MEM[`DMEMADDRBITS-1:`DMEMWORDBITS]];
  
  // Write to D-MEM
  always @ (posedge clk) begin
    if (wr_mem_MEM) begin
      dmem[memaddr_MEM[`DMEMADDRBITS-1:`DMEMWORDBITS]] <= aluout_MEM; 
    end
  end
  `UNUSED_VAR (memaddr_MEM)

  wire rd_mem_MEM;
  wire [`REGNOBITS-1:0] wregno_MEM;
  wire wr_reg_MEM;

  `UNUSED_VAR (rd_mem_MEM)

  assign {
    valid_MEM,
    inst_MEM,
    PC_MEM,
    op_I_MEM,
    memaddr_MEM, 
    aluout_MEM,
    rd_mem_MEM,
    wr_mem_MEM,
    wr_reg_MEM,
    wregno_MEM
  } = from_AGEX_latch;
   
  assign MEM_latch_contents = {
    valid_MEM,
    inst_MEM,
    PC_MEM,
    op_I_MEM,
    rd_val_MEM, 
    aluout_MEM,
    wr_reg_MEM,
    wregno_MEM
  }; 

  // Update MEM latch
  always @ (posedge clk) begin
    if (reset) begin
        MEM_latch <= {`MEM_latch_WIDTH{1'b0}}; 
    end else begin 
        MEM_latch <= MEM_latch_contents;
    end    
  end

  // forward signals to AGEX stage
  assign from_MEM_to_AGEX = 0;

  // forward signals to DE stage
  assign from_MEM_to_DE = 0;

  // forward signals to FE stage
  assign from_MEM_to_FE = 0;

  // send MEM latch contents to next pipeline stage
  assign MEM_latch_out = MEM_latch;

endmodule
