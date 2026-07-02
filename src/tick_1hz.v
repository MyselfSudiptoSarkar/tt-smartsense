// tick_1hz.v
// Divides the system clock down to a single-cycle-wide 1 Hz enable pulse.
// Used by the FSM's vacancy countdown and by the energy integrator so both
// operate in real seconds regardless of the chosen system clock frequency.

module tick_1hz #(
    parameter CLK_FREQ_HZ = 32'd50_000_000
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1s
);

    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 32'd0;
            tick_1s <= 1'b0;
        end else if (cnt == CLK_FREQ_HZ - 32'd1) begin
            cnt     <= 32'd0;
            tick_1s <= 1'b1;
        end else begin
            cnt     <= cnt + 32'd1;
            tick_1s <= 1'b0;
        end
    end

endmodule