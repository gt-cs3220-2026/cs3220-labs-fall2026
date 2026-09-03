`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

// dummy implementation, please replace with your own
module fsm ( 
    input clk,    // Clocks are used in sequential circuits
    input reset,
    input seq,
    output detected );// seq detector 1101, once detected, output 1 for 1 clock cycle

    assign detected = 0;
    
endmodule