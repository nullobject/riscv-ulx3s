/**
 * Handles 8 hardware rotary encoders.
 *
 * The 16-bit encoder position registers are grouped into four 32-bit words.
 * Reading/writing the encoder positions is provided by the register port.
 */
module encoders (
    input clk,
    input rst_n,

    // Encoder position register port
    input  [ 3:0] reg_we,
    input  [ 1:0] reg_addr,
    input  [31:0] reg_data,
    output [31:0] reg_q,

    // Encoder signals
    input a,
    input b
);

  wire [15:0] q_hi[4], q_lo[4];

  genvar i;
  generate
    for (i = 0; i < 4; i++) begin
      encoder encoder_hi (
          .clk(clk),
          .rst_n(rst_n),
          .reg_we(reg_addr == i && &reg_we[3:2]),
          .reg_data(reg_data[31:16]),
          .reg_q(q_hi[i]),
          .a(a),
          .b(b)
      );

      encoder encoder_lo (
          .clk(clk),
          .rst_n(rst_n),
          .reg_we(reg_addr == i && &reg_we[1:0]),
          .reg_data(reg_data[15:0]),
          .reg_q(q_lo[i]),
          .a(a),
          .b(b)
      );
    end
  endgenerate

  assign reg_q =
    reg_addr == 0 ? {q_hi[0], q_lo[0]} :
    reg_addr == 1 ? {q_hi[1], q_lo[1]} :
    reg_addr == 2 ? {q_hi[2], q_lo[2]} :
    {q_hi[3], q_lo[3]};

endmodule
