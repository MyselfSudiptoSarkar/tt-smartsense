module tt_um_smartsense (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Your SmartSense signals
    wire light_relay;
    wire fan_relay;
    wire ac_relay;
    wire [1:0] ctrl_state;

    wire [47:0] e_smart_mWh;
    wire [47:0] e_conv_mWh;
    wire [47:0] e_savings_mWh;

    smartsense_core uut (
        .clk(clk),
        .rst_n(rst_n),

        .pir_raw(ui_in[0]),
        .ir_raw(ui_in[1]),

        .light_relay(light_relay),
        .fan_relay(fan_relay),
        .ac_relay(ac_relay),

        .ctrl_state(ctrl_state),

        .e_smart_mWh(e_smart_mWh),
        .e_conv_mWh(e_conv_mWh),
        .e_savings_mWh(e_savings_mWh)
    );

    // Outputs
    assign uo_out[0] = light_relay;
    assign uo_out[1] = fan_relay;
    assign uo_out[2] = ac_relay;
    assign uo_out[4:3] = ctrl_state;
    assign uo_out[7:5] = 3'b000;

    // Bidirectional pins unused
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // ena is unused
    // Prevent unused-input warnings
    wire _unused = &{1'b0, ena, uio_in};

endmodule