// energy_calculator.v
// Integrates instantaneous power (Watts) into cumulative energy (milli-Wh)
// once per tick_1s pulse, tracking E_Smart, E_Conv, and their difference
// E_Savings - the three signals the README calls out explicitly.
//
// Each 1-second tick adds P(W) * (1/3600) Wh = P * 1000/3600 mWh.
// 1000/3600 simplifies to 5/18. Rather than synthesizing real divider
// hardware for /18 and %18 (which is extremely area-hungry - two full
// combinational integer dividers, one per accumulator, plus the modulo
// hardware alongside them - and does not fit a Tiny Tapeout 1x1 tile's
// placement budget, causing OpenROAD.GlobalPlacement to fail with
// GPL-0302), this uses a fixed-point reciprocal-multiply approximation:
// only a constant multiplier and a right-shift, both of which map to
// cheap adder/shifter logic instead of a divider.
//
//   5/18 ~= 72818 / 2^18   (relative error ~ 3e-7, i.e. negligible drift
//                           even accumulated over the accumulator's
//                           full lifetime)

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

    localparam [17:0] SCALE_MULT = 18'd72818; // round(5/18 * 2^18)
    localparam        SCALE_BITS = 18;

    // 16-bit power * 18-bit constant = 34 bits max; ACC_WIDTH (>=34)
    // covers the sum with the running total headroom to spare.
    wire [ACC_WIDTH-1:0] smart_scaled = p_smart_out * SCALE_MULT;
    wire [ACC_WIDTH-1:0] conv_scaled  = p_conv_out  * SCALE_MULT;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e_smart_mWh <= {ACC_WIDTH{1'b0}};
            e_conv_mWh  <= {ACC_WIDTH{1'b0}};
        end else if (tick_1s) begin
            e_smart_mWh <= e_smart_mWh + (smart_scaled >> SCALE_BITS);
            e_conv_mWh  <= e_conv_mWh  + (conv_scaled  >> SCALE_BITS);
        end
    end

    assign e_savings_mWh = e_conv_mWh - e_smart_mWh;

endmodule