module rom #(
    parameter MEM_INIT_FILE = "",
    parameter DEPTH = 16384,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter DATA_WIDTH = 32
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] q
);

  reg [DATA_WIDTH-1:0] rom[0:DEPTH-1];

  initial if (MEM_INIT_FILE != "") $readmemh(MEM_INIT_FILE, rom);

  always @(posedge clk) q <= rom[addr];

endmodule
