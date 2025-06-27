module encoders (
    input clk,
    input rst_n,

    // CPU port
    input         we,
    input  [ 2:0] addr,
    input  [15:0] din,
    output [15:0] dout,

    // Encoder signals
    input a,
    input b
);

  wire [15:0] q[8];

  assign dout =
    addr == 7 ? q[7] :
    addr == 6 ? q[6] :
    addr == 5 ? q[5] :
    addr == 4 ? q[4] :
    addr == 3 ? q[3] :
    addr == 2 ? q[2] :
    addr == 1 ? q[1] :
    q[0];

  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      encoder encoder (
          .clk(clk),
          .rst_n(rst_n),
          .we(addr == i && we),
          .a(a),
          .b(b),
          .din(din),
          .q(q[i])
      );
    end
  endgenerate

endmodule

