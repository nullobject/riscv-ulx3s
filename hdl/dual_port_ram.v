module dual_port_ram #(
    parameter DEPTH = 16384,
    parameter ADDR_WIDTH_A = $clog2(DEPTH),
    parameter ADDR_WIDTH_B = $clog2(DEPTH)
) (
    input clk,

    // Port A
    input [3:0] we_a,
    input [ADDR_WIDTH_A-1:0] addr_a,
    input [31:0] data_a,
    output reg [31:0] q_a,

    // Port B
    input [ADDR_WIDTH_B-1:0] addr_b,
    output reg [15:0] q_b
);

  reg [31:0] mem[0:DEPTH-1];

  always @(posedge clk) begin
    q_a <= mem[addr_a];
    q_b <= addr_b[0] ? mem[addr_b[ADDR_WIDTH_B-1:1]][31:16] : mem[addr_b[ADDR_WIDTH_B-1:1]][15:0];
    if (we_a[0]) mem[addr_a][7:0] <= data_a[7:0];
    if (we_a[1]) mem[addr_a][15:8] <= data_a[15:8];
    if (we_a[2]) mem[addr_a][23:16] <= data_a[23:16];
    if (we_a[3]) mem[addr_a][31:24] <= data_a[31:24];
  end

endmodule
