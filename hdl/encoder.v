/**
 * Decodes movement of a rotary encoder.
 */
module encoder (
    input clk,
    input rst_n,
    input we,
    input [15:0] din,
    output [15:0] q,
    input a,
    input b
);

  localparam VELOCITY_SHIFT = 3;

  wire debounced_a, debounced_b;
  wire cnt;
  wire dir;
  wire [15:0] prev_value, next_value;
  wire underflow, overflow;

  reg [19:0] timer_cnt;
  reg [15:0] pulse_cnt;
  reg [15:0] velocity;
  reg [15:0] value;

  assign {underflow, prev_value} = value - velocity;
  assign {overflow, next_value}  = value + velocity;

  // Velocity
  always @(posedge clk) begin
    if (!rst_n) begin
      timer_cnt <= 0;
      pulse_cnt <= 0;
      velocity  <= 0;
    end else begin
      timer_cnt <= timer_cnt + 1;

      if (cnt && !&pulse_cnt) pulse_cnt <= pulse_cnt + 1;

      if (&timer_cnt) begin
        pulse_cnt <= 0;
        velocity  <= (pulse_cnt << VELOCITY_SHIFT) + 1;
      end
    end
  end

  // Value
  always @(posedge clk) begin
    if (!rst_n) begin
      value <= 0;
    end else begin
      value <=
        we ? din :
        cnt && dir ? (overflow ? 16'hFFFF : next_value) :
        cnt && !dir ? (underflow ? 16'h0000 : prev_value) :
        value;
    end
  end

  debouncer #(
      .COUNTER_WIDTH(11)
  ) debouncer_a (
      .clk(clk),
      .in (a),
      .out(debounced_a)
  );

  debouncer #(
      .COUNTER_WIDTH(11)
  ) debouncer_b (
      .clk(clk),
      .in (b),
      .out(debounced_b)
  );

  quadrature_decoder decoder (
      .clk(clk),
      .a  (debounced_a),
      .b  (debounced_b),
      .cnt(cnt),
      .dir(dir)
  );

  assign q = value;

endmodule

/**
 * Decodes the quadrature signals from a rotary encoder to provide the
 * movement and direction of rotation.
 *
 * https://www.fpga4fun.com/QuadratureDecoder.html
 */
module quadrature_decoder (
    input  clk,
    input  a,
    input  b,
    output cnt,
    output dir
);

  reg q, r;

  // Delay inputs
  always @(posedge clk) begin
    q <= a;
    r <= b;
  end

  assign cnt = a ^ q ^ b ^ r;
  assign dir = a ^ r;

endmodule
