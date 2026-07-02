// energy_calculator.v
// Integrates instantaneous power (Watts) into cumulative energy (milli-Wh)
// once per tick_1s pulse, tracking E_Smart, E_Conv, and their difference
// E_Savings - the three signals the README calls out explicitly.
//
// Each 1-second tick adds P(W) * (1/3600) Wh = P * 1000/3600 mWh.
// 1000/3600 simplifies to 5/18, kept as integer math with a remainder
// register so the running total does not drift from truncation over time.

module energy_calculator #(
    parameter ACC_WIDTH = 48
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    tick_1s,
    input  wire [15:0]             p_smart_out, // Watts
    input  wire [15:0]             p_conv_out,  // Watts
    output reg  [ACC_WIDTH-1:0]    e_smart_mWh,
    output reg  [ACC_WIDTH-1:0]    e_conv_mWh,
    output wire [ACC_WIDTH-1:0]    e_savings_mWh
);

    reg [15:0] smart_rem, conv_rem; // carried remainders, range 0..17

    wire [31:0] smart_num = p_smart_out * 32'd5 + smart_rem;
    wire [31:0] conv_num  = p_conv_out  * 32'd5 + conv_rem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e_smart_mWh <= {ACC_WIDTH{1'b0}};
            e_conv_mWh  <= {ACC_WIDTH{1'b0}};
            smart_rem   <= 16'd0;
            conv_rem    <= 16'd0;
        end else if (tick_1s) begin
            e_smart_mWh <= e_smart_mWh + (smart_num / 32'd18);
            e_conv_mWh  <= e_conv_mWh  + (conv_num  / 32'd18);
            smart_rem   <= smart_num % 32'd18;
            conv_rem    <= conv_num  % 32'd18;
        end
    end

    assign e_savings_mWh = e_conv_mWh - e_smart_mWh;

endmodule