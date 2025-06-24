/**
 * Debounces a signal by waiting for the input to stop changing, before
 * latching the output.
 */
module debouncer #(
    parameter COUNTER_WIDTH = 8
) (
    input clk,
    input in,
    output reg out
);

  reg q, r;
  reg [COUNTER_WIDTH-1:0] debounce_cnt;

  // Synchronizer
  always @(posedge clk) {r, q} <= {q, in};

  // Debouncer
  always @(posedge clk) begin
    if (r == out) debounce_cnt <= 0;
    else begin
      debounce_cnt <= debounce_cnt + 1;
      if (&debounce_cnt) out <= r;
    end
  end

endmodule
