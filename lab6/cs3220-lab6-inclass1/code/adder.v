module adder#(
    parameter INPUT_A_WIDTH = 16,
    parameter INPUT_A_FRAC  = 10,
    parameter INPUT_B_WIDTH = 16,
    parameter INPUT_B_FRAC  = 10,
    parameter OUTPUT_WIDTH  = 16,
    parameter OUTPUT_FRAC   = 10,
    parameter DELAY         = 3
)(
    input                              clk,
    input                              reset,
    input                              en, 
    input                              stall,
    input   signed [INPUT_A_WIDTH-1:0] a_in,
    input   signed [INPUT_B_WIDTH-1:0] b_in,
    output   signed [OUTPUT_WIDTH-1:0] out,
    output                             done
);

    reg signed [OUTPUT_WIDTH-1:0] add;
    reg en_reg;
    
    //assume that the integer part of the output has larger or equal size to the integer part of the input
    localparam A_WIDTH_EXTENDED = INPUT_A_WIDTH + (OUTPUT_WIDTH-OUTPUT_FRAC) - (INPUT_A_WIDTH-INPUT_A_FRAC);
    localparam B_WIDTH_EXTENDED = INPUT_B_WIDTH + (OUTPUT_WIDTH-OUTPUT_FRAC) - (INPUT_B_WIDTH-INPUT_B_FRAC);

    //add
    generate
        if (INPUT_A_FRAC == INPUT_B_FRAC && INPUT_A_FRAC == OUTPUT_FRAC) begin
            always @(posedge clk ) begin
                if (reset) begin
                    add <= '0;
                end else begin
                    add <= (stall) ? add : a_in + b_in;
                end
            end
        end
        else if (INPUT_A_FRAC == INPUT_B_FRAC && INPUT_A_FRAC > OUTPUT_FRAC) begin
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : A_WIDTH_EXTENDED'(a_in) + B_WIDTH_EXTENDED'(b_in) >>> (INPUT_A_FRAC - OUTPUT_FRAC);
                end
            end
        end
        else if (INPUT_A_FRAC == INPUT_B_FRAC && INPUT_A_FRAC < OUTPUT_FRAC) begin
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : $signed({A_WIDTH_EXTENDED'(a_in) + B_WIDTH_EXTENDED'(b_in), {(OUTPUT_FRAC-INPUT_A_FRAC){1'b0}}});
                end
            end
        end else if (INPUT_A_FRAC > INPUT_B_FRAC && INPUT_A_FRAC == OUTPUT_FRAC) begin
            localparam ADDITIONAL_B_WIDTH = INPUT_A_FRAC - INPUT_B_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : A_WIDTH_EXTENDED'(a_in) +  (B_WIDTH_EXTENDED+ADDITIONAL_B_WIDTH)'($signed({b_in, {(INPUT_A_FRAC-INPUT_B_FRAC){1'b0}}}));
                end
            end
        end else if (INPUT_A_FRAC > INPUT_B_FRAC && INPUT_A_FRAC > OUTPUT_FRAC) begin
            localparam ADDITIONAL_B_WIDTH = INPUT_A_FRAC - INPUT_B_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : OUTPUT_WIDTH'(A_WIDTH_EXTENDED'(a_in) + (B_WIDTH_EXTENDED+ADDITIONAL_B_WIDTH)'($signed({b_in,{(INPUT_A_FRAC-INPUT_B_FRAC){1'b0}}}))) >>> (INPUT_A_FRAC - OUTPUT_FRAC);
                end
            end
        end else if (INPUT_A_FRAC > INPUT_B_FRAC && INPUT_A_FRAC < OUTPUT_FRAC) begin
            localparam ADDITIONAL_B_WIDTH = INPUT_A_FRAC - INPUT_B_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     = '0;
                end else begin
                    add    <= (stall) ? add : $signed({(OUTPUT_WIDTH-OUTPUT_FRAC+INPUT_A_FRAC)'(A_WIDTH_EXTENDED'(a_in) + (B_WIDTH_EXTENDED+ADDITIONAL_B_WIDTH)'($signed({b_in,{(INPUT_A_FRAC-INPUT_B_FRAC){1'b0}}}))), {(OUTPUT_FRAC-INPUT_A_FRAC){1'b0}}});
                end
            end
        end else if (INPUT_A_FRAC < INPUT_B_FRAC && INPUT_B_FRAC == OUTPUT_FRAC) begin
            localparam ADDITIONAL_A_WIDTH = INPUT_B_FRAC - INPUT_A_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : B_WIDTH_EXTENDED'(b_in) + (A_WIDTH_EXTENDED+ADDITIONAL_A_WIDTH)'($signed({a_in,{(INPUT_B_FRAC-INPUT_A_FRAC){1'b0}}}));
                end
            end
        end else if (INPUT_A_FRAC < INPUT_B_FRAC && INPUT_B_FRAC > OUTPUT_FRAC) begin
            localparam ADDITIONAL_A_WIDTH = INPUT_B_FRAC - INPUT_A_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add  <= (stall) ? add : OUTPUT_WIDTH'(B_WIDTH_EXTENDED'(b_in) + (A_WIDTH_EXTENDED+ADDITIONAL_A_WIDTH)'($signed({a_in,{(INPUT_B_FRAC-INPUT_A_FRAC){1'b0}}}))) >>> (INPUT_B_FRAC - OUTPUT_FRAC);
                end
            end
        end else if (INPUT_A_FRAC < INPUT_B_FRAC && INPUT_B_FRAC < OUTPUT_FRAC) begin
            localparam ADDITIONAL_A_WIDTH = INPUT_B_FRAC - INPUT_A_FRAC;
            always @(posedge clk ) begin
                if (reset) begin
                    add     <= '0;
                end else begin
                    add    <= (stall) ? add : $signed({(OUTPUT_WIDTH-OUTPUT_FRAC+INPUT_B_FRAC)'(B_WIDTH_EXTENDED'(b_in) + (A_WIDTH_EXTENDED+ADDITIONAL_A_WIDTH)'($signed({a_in,{(INPUT_B_FRAC-INPUT_A_FRAC){1'b0}}}))), {(OUTPUT_FRAC-INPUT_B_FRAC){1'b0}}});
                end
            end
        end
    endgenerate

    //output buffer
    genvar i;
    generate
        if (DELAY <= 1) begin
            assign out = add;
            //sync with add
            always @(posedge clk ) begin
                if (reset) begin
                    en_reg <= '0;
                end else begin
                    en_reg <= (stall) ? en_reg : en;
                end
            end
            assign done = en_reg && ~reset;
        end
        else begin
            reg [OUTPUT_WIDTH-1:0] add_delayed[0:DELAY-2];
            reg en_delayed[0:DELAY-2];
            //sync with add
            always @(posedge clk ) begin
                if (reset) begin
                    en_reg <= '0;
                end else begin
                    en_reg <= (stall) ? en_reg : en;
                end
            end
            for (i = 0; i < DELAY-1; i = i + 1) begin
                if (i == 0) begin
                    always @(posedge clk ) begin
                        if (reset) begin
                            add_delayed[i] <= '0;
                            en_delayed[i] <= '0;
                        end else begin
                            add_delayed[i] <= (stall) ? add_delayed[i] : add;
                            en_delayed[i] <= (stall) ? en_delayed[i] : en_reg;
                        end
                    end
                end
                else begin
                    always @(posedge clk ) begin
                        if (reset) begin
                            add_delayed[i] <= '0;
                            en_delayed[i] <= '0;
                        end else begin
                            add_delayed[i] <= (stall) ? add_delayed[i] : add_delayed[i-1];
                            en_delayed[i] <= (stall) ? en_delayed[i] : en_delayed[i-1];
                        end
                    end
                end
            end
            assign out = add_delayed[DELAY-2];
            assign done = en_delayed[DELAY-2] && ~reset;
        end
    endgenerate

endmodule