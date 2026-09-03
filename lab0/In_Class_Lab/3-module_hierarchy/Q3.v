`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

// dummy implementation, please replace with your own

module module_hierarchy ( 
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);//

    assign sum = 32'd0;

endmodule

module add1 ( input a, input b, input cin,   output sum, output cout );

    assign sum = 1'b0;
    assign cout = 1'b0;

endmodule