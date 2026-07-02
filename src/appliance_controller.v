// appliance_controller.v
// Combinational decode: FSM state -> relay outputs + instantaneous power.
// Load table taken directly from the README:
//   Light 40 W, Fan 70 W, AC 1200 W (all smart, FSM-controlled)
//   Conventional baseline 1310 W, always ON
//
// Smart loads are ON in OCCUPIED and VACANT_DELAY (README: "loads remain ON
// for timeout period before switching OFF"), and OFF in EMPTY/ENTERING.

module appliance_controller #(
    parameter [15:0] LIGHT_W = 16'd40,
    parameter [15:0] FAN_W   = 16'd70,
    parameter [15:0] AC_W    = 16'd1200,
    parameter [15:0] CONV_W  = 16'd1310
)(
    input  wire [1:0]  ctrl_state,
    output wire         light_relay,
    output wire         fan_relay,
    output wire         ac_relay,
    output wire [15:0]  p_smart_out, // Watts, instantaneous
    output wire [15:0]  p_conv_out   // Watts, instantaneous (always CONV_W)
);

    localparam OCCUPIED     = 2'd2;
    localparam VACANT_DELAY = 2'd3;

    wire loads_on = (ctrl_state == OCCUPIED) || (ctrl_state == VACANT_DELAY);

    assign light_relay = loads_on;
    assign fan_relay   = loads_on;
    assign ac_relay    = loads_on;

    assign p_smart_out = loads_on ? (LIGHT_W + FAN_W + AC_W) : 16'd0;
    assign p_conv_out  = CONV_W; // conventional baseline is unaffected by occupancy

endmodule