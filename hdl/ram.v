module ram #(
    parameter DEPTH = 16384,
    parameter ADDRESS_WIDTH = $clog2(DEPTH)
) (
    input clk,
    input [3:0] we,
    input [ADDRESS_WIDTH-1:2] addr,
    input [31:0] data,
    output reg [31:0] q
);

  reg [31:0] mem[0:DEPTH-1];

  always @(posedge clk) begin
    q <= mem[addr];
    if (we[0]) mem[addr][7:0] <= data[7:0];
    if (we[1]) mem[addr][15:8] <= data[15:8];
    if (we[2]) mem[addr][23:16] <= data[23:16];
    if (we[3]) mem[addr][31:24] <= data[31:24];
  end

endmodule
