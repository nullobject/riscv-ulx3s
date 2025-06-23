/**
 * Renders the character layer.
 */
module layer_processor #(
    parameter TILE_COUNT = 256
) (
    input clk,
    input en,

    // VRAM
    output [ 7:0] ram_addr,
    input  [15:0] ram_data,

    // Pixel data
    input  [12:0] pixel_addr,
    output [ 7:0] pixel_data
);

  localparam TILE_CODE_WIDTH = $clog2(TILE_COUNT);
  localparam TILE_SIZE_BYTES = 32;
  localparam TILE_ROM_DEPTH = TILE_COUNT * TILE_SIZE_BYTES / 4;
  localparam TILE_ROM_ADDR_WIDTH = $clog2(TILE_ROM_DEPTH);

  wire [2:0] row = pixel_addr[12:10];
  wire [4:0] col = pixel_addr[6:2];
  wire [2:0] offset_y = pixel_addr[9:7];
  wire [1:0] offset_x = pixel_addr[1:0];

  reg [15:0] tile;
  reg latch_tile;
  wire tile_invert = tile[15];
  wire [TILE_CODE_WIDTH-1:0] tile_code = tile[TILE_CODE_WIDTH-1:0];
  wire [TILE_ROM_ADDR_WIDTH-1:0] tile_rom_addr = {tile_code, offset_y};
  wire [31:0] tile_rom_dout;

  // One byte of tile ROM data contains two pixels
  wire [7:0] tile_rom_byte =
      offset_x == 0 ? tile_rom_dout[31:24] :
      offset_x == 1 ? tile_rom_dout[23:16] :
      offset_x == 2 ? tile_rom_dout[15:8] :
      tile_rom_dout[7:0];

  assign ram_addr =
      // Load first tile
      en == 0 ? 0 :
      // Load first tile in next row
      col == 31 && offset_y == 7 ? {row + 1'h1, 5'h0} :
      // Load next tile in current row
      {row, col + 1'h1};

  always @(posedge clk) begin
    latch_tile <= offset_x == 3;
    if (latch_tile) tile <= ram_data;
  end

  assign pixel_data = tile_invert ? ~tile_rom_byte : tile_rom_byte;

  rom #(
      .MEM_INIT_FILE("rom/tiles.hex"),
      .DEPTH(TILE_ROM_DEPTH),
      .DATA_WIDTH(32)
  ) tile_rom (
      .clk(clk),
      .addr(tile_rom_addr),
      .q(tile_rom_dout)
  );

endmodule
