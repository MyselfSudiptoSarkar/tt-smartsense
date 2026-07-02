module tt_um_smartsense (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire        ena,
    input  wire        clk,
    input  wire        rst_n
);

    // ------------------------------------------------------------------
    // Simulation-only timing scaling.
    //
    // smartsense_core's production defaults are CLK_FREQ_HZ=50,000,000 and
    // VACANT_TIMEOUT_S=600 (10 minutes of real time). Those are correct for
    // real hardware, but make RTL/gate-level cocotb simulation infeasible:
    // a single energy tick alone would need 50 million clock cycles, and a
    // full vacancy timeout would need 30 billion. `SIM is only defined by
    // the cocotb Makefile (see test/Makefile), never during the actual
    // LibreLane/OpenLane hardening or GDS build, so production silicon
    // always gets the real timing constants below - this block has zero
    // effect on the tapeout.
    // ------------------------------------------------------------------
`ifdef SIM
    localparam CORE_CLK_FREQ_HZ  = 32'd100; // 100 cycles = 1 fake "second"
    localparam CORE_VACANT_S     = 32'd5;   // 5 fake seconds vacancy timeout
    localparam CORE_ENTER_CONFIRM = 32'd10; // 10-cycle entry debounce
`else
    localparam CORE_CLK_FREQ_HZ  = 32'd50_000_000;
    localparam CORE_VACANT_S     = 32'd600;
    localparam CORE_ENTER_CONFIRM = 32'd200;
`endif

    // SmartSense signals
    wire light_relay;
    wire fan_relay;
    wire ac_relay;
    wire [1:0] ctrl_state;

    wire [47:0] e_smart_mWh;
    wire [47:0] e_conv_mWh;
    wire [47:0] e_savings_mWh;

    smartsense_core #(
        .CLK_FREQ_HZ(CORE_CLK_FREQ_HZ),
        .VACANT_TIMEOUT_S(CORE_VACANT_S),
        .ENTER_CONFIRM_CYCLES(CORE_ENTER_CONFIRM)
    ) uut (
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

    // Primary outputs - unchanged from the original datasheet pinout
    assign uo_out[0] = light_relay;
    assign uo_out[1] = fan_relay;
    assign uo_out[2] = ac_relay;
    assign uo_out[4:3] = ctrl_state;
    assign uo_out[7:5] = 3'b000;

    // ------------------------------------------------------------------
    // Debug byte-mux: exposes the three 48-bit energy accumulators over
    // the uio bus, which was entirely idle before. ui_in[7:3] selects
    // which byte to present on uio_out; ui_in[2] is reserved (drive 0).
    //   sel  0.. 5 -> e_smart_mWh   byte 0 (LSB) .. byte 5 (MSB)
    //   sel  6..11 -> e_conv_mWh    byte 0 (LSB) .. byte 5 (MSB)
    //   sel 12..17 -> e_savings_mWh byte 0 (LSB) .. byte 5 (MSB)
    //   sel 18..31 -> reads back 0
    //
    // This is a small combinational mux (an 18:1 select of an 8-bit bus),
    // negligible area, and is permanently part of the design - not a
    // simulation-only hook - so it also gives real deployed units a way
    // to read out cumulative energy savings post-fabrication if wired to
    // an external reader, which is a genuine feature, not just a test aid.
    // ------------------------------------------------------------------
    wire [4:0] dbg_sel = ui_in[7:3];
    wire [143:0] dbg_bus = {e_savings_mWh, e_conv_mWh, e_smart_mWh};
    wire [7:0] dbg_byte = (dbg_sel < 5'd18) ? dbg_bus[dbg_sel*8 +: 8] : 8'h00;

    assign uio_out = dbg_byte;
    assign uio_oe  = 8'hFF; // uio bus is output-only in this design

    // ena and ui_in[2] (reserved) are unused; uio_in is unused since the
    // uio bus is output-only here.
    wire _unused = &{1'b0, ena, uio_in, ui_in[2]};

endmodule