module top (
    input clk_25mhz,
    input [6:0] btn,
    input ftdi_txd,
    output ftdi_rxd,
    output wifi_gpio0,
    output reg [7:0] led,
    output [7:0] gp,
    output [7:0] gn
);

  assign wifi_gpio0 = 1'b1;

  wire mem_valid;
  wire mem_ready;
  wire [31:0] mem_addr;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wstrb;
  wire [31:0] mem_rdata;

  reg rom_ready;
  reg ram_ready;
  reg char_ram_ready;
  reg led_ready;
  wire [31:0] rom_dout;
  wire [31:0] ram_dout;
  wire [31:0] char_ram_dout;

  // reset
  reg [5:0] reset_cnt = 0;
  wire rst_n = &reset_cnt & btn[0];
  always @(posedge clk_25mhz) reset_cnt <= reset_cnt + !rst_n;

  // LED
  always @(posedge clk_25mhz) if (led_cs && mem_wstrb[0]) led <= mem_wdata[7:0];

  // chip select
  //
  // 0000-0FFF ROM
  // 1000-1FFF RAM
  // 2000-2100 CHAR RAM
  // 3000      LED
  wire rom_cs = mem_valid && mem_addr[15:12] == 4'b0000;
  wire ram_cs = mem_valid && mem_addr[15:12] == 4'b0001;
  wire char_ram_cs = mem_valid && mem_addr[15:12] == 4'b0010;
  wire led_cs = mem_valid && mem_addr[15:12] == 4'b0011;

  always @(posedge clk_25mhz) begin
    rom_ready <= !mem_ready && rom_cs;
    ram_ready <= !mem_ready && ram_cs;
    char_ram_ready <= !mem_ready && char_ram_cs;
    led_ready <= !mem_ready && led_cs;
  end

  assign mem_ready = rom_ready || ram_ready || char_ram_ready || led_ready;

  // decode CPU input data bus
  assign mem_rdata = led_cs ? {24'h0, led} : char_ram_cs ? char_ram_dout : ram_cs ? ram_dout : rom_dout;

  // CPU
  picorv32 #(
      .STACKADDR(32'h0000_2000),
      .BARREL_SHIFTER(1),
      .COMPRESSED_ISA(1),
      .ENABLE_MUL(1),
      .ENABLE_DIV(1)
  ) cpu (
      .clk      (clk_25mhz),
      .resetn   (rst_n),
      .mem_valid(mem_valid),
      .mem_instr(),
      .mem_ready(mem_ready),
      .mem_addr (mem_addr),
      .mem_wdata(mem_wdata),
      .mem_wstrb(mem_wstrb),
      .mem_rdata(mem_rdata)
  );

  // ROM
  rom #(
      .MEM_INIT_FILE("build/rom.hex"),
      .DEPTH(1024)
  ) prog_rom (
      .clk(clk_25mhz),
      .addr(mem_addr[10:2]),
      .q(rom_dout)
  );

  // RAM
  ram #(
      .DEPTH(1024)
  ) work_ram (
      .clk(clk_25mhz),
      .we(ram_cs ? mem_wstrb : 0),
      .addr(mem_addr[10:2]),
      .data(mem_wdata),
      .q(ram_dout)
  );

  // GPU
  gpu gpu (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .char_ram_we(char_ram_cs ? mem_wstrb : 0),
      .char_ram_addr(mem_addr[8:2]),
      .char_ram_data(mem_wdata),
      .char_ram_q(char_ram_dout),
      .oled_cs(gp[0]),
      .oled_rst(gp[1]),
      .oled_dc(gp[3]),
      .oled_e(gp[2]),
      .oled_dout(gn)
  );

endmodule
