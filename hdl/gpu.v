/**
 * Renders tilemap layers to the OLED display.
 */
module gpu (
    input clk,
    input rst_n,

    // VRAM
    input  [ 3:0] vram_we,
    input  [ 8:2] vram_addr,
    input  [31:0] vram_data,
    output [31:0] vram_q,

    // OLED signals
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [7:0] layer_vram_addr;
  wire [15:0] layer_vram_q;
  wire pixel_re;
  wire [12:0] pixel_addr;
  wire [7:0] pixel_data;

  dual_port_ram #(
      .DEPTH(128),
      .ADDR_WIDTH_A(7),
      .ADDR_WIDTH_B(8)
  ) vram (
      .clk(clk),

      // Port A
      .we_a(vram_we),
      .addr_a(vram_addr),
      .data_a(vram_data),
      .q_a(vram_q),

      // Port B
      .addr_b(layer_vram_addr),
      .q_b(layer_vram_q)
  );

  layer_processor layer (
      .clk(clk),
      .en(pixel_re),
      .vram_addr(layer_vram_addr),
      .vram_data(layer_vram_q),
      .pixel_addr(pixel_addr),
      .pixel_data(pixel_data)
  );

  oled oled (
      .clk(clk),
      .rst_n(rst_n),
      .pixel_re(pixel_re),
      .pixel_addr(pixel_addr),
      .pixel_data(pixel_data),
      .oled_cs(oled_cs),
      .oled_rst(oled_rst),
      .oled_dc(oled_dc),
      .oled_e(oled_e),
      .oled_dout(oled_dout)
  );

endmodule
