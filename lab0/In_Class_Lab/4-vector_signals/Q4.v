`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

// dummy implementation, please replace with your own
module vector_signals ( 
    input [2:0] a,
    input [2:0] b,
    output [2:0] out_or_bitwise,
    output out_or_logical,
    output [5:0] out_not
);


    assign out_or_bitwise = 3'd0;
    assign out_or_logical = 1'b0;
    assign out_not[5:0] = 6'd0;

endmodule