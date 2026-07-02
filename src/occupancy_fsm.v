// Four-state occupancy FSM: EMPTY -> ENTERING -> OCCUPIED -> VACANT_DELAY -> EMPTY
// Mirrors the Stateflow chart described in the SmartSense EMS README.
//
// - occ_detect = pir_out | ir_out  (sensor fusion: either sensor confirms presence)
// - ENTERING requires occ_detect to hold for ENTER_CONFIRM_CYCLES consecutive
//   fast clock cycles before promoting to OCCUPIED (debounce against a single
//   PIR/IR glitch). If occ_detect drops during ENTERING, we fall back to EMPTY.
// - VACANT_DELAY counts real seconds (via tick_1s) rather than raw clk cycles,
//   so VACANT_TIMEOUT_S is a human-meaningful parameter (e.g. 600 = 10 min).
// - Re-entry during VACANT_DELAY cancels the countdown and returns to OCCUPIED.

module occupancy_fsm #(
    parameter ENTER_CONFIRM_CYCLES = 32'd200,  // fast-clk debounce, ENTERING -> OCCUPIED
    parameter VACANT_TIMEOUT_S     = 32'd600   // seconds, VACANT_DELAY -> EMPTY
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick_1s,    // one-cycle-wide pulse, once per second
    input  wire        pir_out,    // synchronized PIR signal
    input  wire        ir_out,     // synchronized IR signal
    output reg  [1:0]  ctrl_state  // 0=EMPTY 1=ENTERING 2=OCCUPIED 3=VACANT_DELAY
);

    localparam EMPTY        = 2'd0;
    localparam ENTERING     = 2'd1;
    localparam OCCUPIED     = 2'd2;
    localparam VACANT_DELAY = 2'd3;

    wire occ_detect = pir_out | ir_out;

    reg [31:0] confirm_cnt; // ENTERING debounce counter (clk cycles)
    reg [31:0] vacant_cnt;  // VACANT_DELAY countdown counter (seconds)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_state  <= EMPTY;
            confirm_cnt <= 32'd0;
            vacant_cnt  <= 32'd0;
        end else begin
            case (ctrl_state)

                EMPTY: begin
                    confirm_cnt <= 32'd0;
                    if (occ_detect)
                        ctrl_state <= ENTERING;
                end

                ENTERING: begin
                    if (occ_detect) begin
                        if (confirm_cnt >= ENTER_CONFIRM_CYCLES) begin
                            ctrl_state  <= OCCUPIED;
                            confirm_cnt <= 32'd0;
                        end else begin
                            confirm_cnt <= confirm_cnt + 32'd1;
                        end
                    end else begin
                        // false trigger - sensors cleared before confirmation
                        ctrl_state  <= EMPTY;
                        confirm_cnt <= 32'd0;
                    end
                end

                OCCUPIED: begin
                    vacant_cnt <= 32'd0;
                    if (!occ_detect)
                        ctrl_state <= VACANT_DELAY;
                end

                VACANT_DELAY: begin
                    if (occ_detect) begin
                        // occupant returned before timeout expired
                        ctrl_state <= OCCUPIED;
                        vacant_cnt <= 32'd0;
                    end else if (tick_1s) begin
                        if (vacant_cnt >= VACANT_TIMEOUT_S - 1) begin
                            ctrl_state <= EMPTY;
                            vacant_cnt <= 32'd0;
                        end else begin
                            vacant_cnt <= vacant_cnt + 32'd1;
                        end
                    end
                end

                default: ctrl_state <= EMPTY;
            endcase
        end
    end

endmodule