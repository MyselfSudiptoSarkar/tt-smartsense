// smartsense_core.v
// Top-level digital core for the SmartSense EMS occupancy/energy pipeline.
// This is the block that would replace the ESP32 for the FSM + control +
// energy-accounting portion of the design. Sensor decoding (DHT22 one-wire,
// I2C LCD) and analog front-ends are separate peripheral blocks, not shown
// here - this module covers the FSM core, appliance control, and energy
// accounting path from the README's system architecture diagram.

module smartsense_core #(
    parameter CLK_FREQ_HZ      = 32'd50_000_000,
    parameter VACANT_TIMEOUT_S = 32'd600,  // 10 minutes, matches a typical hostel-room policy
    parameter ENTER_CONFIRM_CYCLES = 32'd200
)(
    input  wire         clk,
    input  wire         rst_n,

    input  wire         pir_raw,   // asynchronous PIR sensor input
    input  wire         ir_raw,    // asynchronous IR sensor input

    output wire         light_relay,
    output wire         fan_relay,
    output wire         ac_relay,
    output wire [1:0]   ctrl_state,

    output wire [47:0]  e_smart_mWh,
    output wire [47:0]  e_conv_mWh,
    output wire [47:0]  e_savings_mWh
);

    // ---- 2-flop synchronizers for asynchronous sensor inputs ----
    reg pir_sync0, pir_sync1;
    reg ir_sync0,  ir_sync1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pir_sync0 <= 1'b0; pir_sync1 <= 1'b0;
            ir_sync0  <= 1'b0; ir_sync1  <= 1'b0;
        end else begin
            pir_sync0 <= pir_raw;  pir_sync1 <= pir_sync0;
            ir_sync0  <= ir_raw;   ir_sync1  <= ir_sync0;
        end
    end

    // ---- real-time seconds tick ----
    wire tick_1s;
    tick_1hz #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_tick (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s)
    );

    // ---- occupancy FSM ----
    occupancy_fsm #(
        .ENTER_CONFIRM_CYCLES(ENTER_CONFIRM_CYCLES),
        .VACANT_TIMEOUT_S(VACANT_TIMEOUT_S)
    ) u_fsm (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .pir_out(pir_sync1), .ir_out(ir_sync1),
        .ctrl_state(ctrl_state)
    );

    // ---- appliance control ----
    wire [15:0] p_smart, p_conv;
    appliance_controller u_appl (
        .ctrl_state(ctrl_state),
        .light_relay(light_relay), .fan_relay(fan_relay), .ac_relay(ac_relay),
        .p_smart_out(p_smart), .p_conv_out(p_conv)
    );

    // ---- energy accounting ----
    energy_calculator #(
        .ACC_WIDTH(48)
    ) u_energy (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .p_smart_out(p_smart), .p_conv_out(p_conv),
        .e_smart_mWh(e_smart_mWh), .e_conv_mWh(e_conv_mWh), .e_savings_mWh(e_savings_mWh)
    );

endmodule