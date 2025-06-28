/**
 * Decodes movement for the 8 hardware rotary encoders and provides CPU access
 * to the 16-bit registers that store their current positions.
 */
module encoders (
    input clk,
    input rst_n,

    // Registers
    input         reg_we,
    input  [ 2:0] reg_addr,
    input  [15:0] reg_data,
    output [15:0] reg_q,

    // Encoder signals
    input a,
    input b
);

  wire [15:0] q[8];

  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      encoder encoder (
          .clk(clk),
          .rst_n(rst_n),
          .we(reg_addr == i && reg_we),
          .din(reg_data),
          .q(q[i]),
          .a(a),
          .b(b)
      );
    end
  endgenerate

  assign reg_q =
    reg_addr == 0 ? q[0] :
    reg_addr == 1 ? q[1] :
    reg_addr == 2 ? q[2] :
    reg_addr == 3 ? q[3] :
    reg_addr == 4 ? q[4] :
    reg_addr == 5 ? q[5] :
    reg_addr == 6 ? q[6] :
    q[7];

endmodule

