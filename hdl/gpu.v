/**
 * Renders tilemap layers to the OLED display.
 */
module gpu (
    input clk,
    input rst_n,

    // Character RAM
    input  [ 3:0] char_ram_we,
    input  [ 8:2] char_ram_addr,
    input  [31:0] char_ram_data,
    output [31:0] char_ram_q,

    // OLED signals
    output       oled_cs,
    output       oled_rst,
    output       oled_dc,
    output       oled_e,
    output [7:0] oled_dout
);

  wire [7:0] char_ram_addr_b;
  wire [15:0] char_ram_q_b;
  wire [7:0] char_data;
  wire pixel_re;
  wire [12:0] pixel_addr;
  wire [7:0] pixel_data = char_data;

  dual_port_ram #(
      .DEPTH(128),
      .ADDR_WIDTH_A(7),
      .ADDR_WIDTH_B(8)
  ) char_ram (
      .clk(clk),

      // Port A
      .we_a(char_ram_we),
      .addr_a(char_ram_addr),
      .data_a(char_ram_data),
      .q_a(char_ram_q),

      // Port B
      .addr_b(char_ram_addr_b),
      .q_b(char_ram_q_b)
  );

  layer_processor char_layer (
      .clk(clk),
      .en(pixel_re),
      .ram_addr(char_ram_addr_b),
      .ram_data(char_ram_q_b),
      .pixel_addr(pixel_addr),
      .pixel_data(char_data)
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
