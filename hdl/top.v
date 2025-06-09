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

  reg  [ 5:0] reset_cnt = 0;
  wire        rst_n = &reset_cnt & btn[0];

  wire        cpu_mem_valid;
  wire        cpu_mem_ready;
  wire [31:0] cpu_mem_addr;
  wire [31:0] cpu_mem_wdata;
  wire [ 3:0] cpu_mem_wstrb;
  wire [31:0] cpu_mem_rdata;

  reg         rom_ready;
  wire [31:0] rom_dout;
  reg         work_ram_ready;
  wire [31:0] work_ram_dout;
  reg         char_ram_ready;
  wire [31:0] char_ram_dout;
  reg         uart_tx_active;
  // wire [ 7:0] uart_dout;

  // reset
  always @(posedge clk_25mhz) reset_cnt <= reset_cnt + !rst_n;

  // LED
  always @(posedge clk_25mhz) if (led_cs && cpu_mem_wstrb[0]) led <= cpu_mem_wdata[7:0];

  // chip select
  //
  // 0000-0FFF ROM
  // 1000-1FFF RAM
  // 2000-2100 CHAR RAM
  // 3000      LED
  // 4000      UART
  wire rom_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0000;
  wire work_ram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0001;
  wire char_ram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0010;
  wire led_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0011;
  wire uart_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0100;

  always @(posedge clk_25mhz) begin
    rom_ready      <= rom_cs;
    work_ram_ready <= work_ram_cs;
    char_ram_ready <= char_ram_cs;
  end

  wire uart_ready = uart_cs && !uart_tx_active;

  // decode CPU memory ready signal
  assign cpu_mem_ready = uart_ready || led_cs || char_ram_ready || work_ram_ready || rom_ready;

  // decode CPU read data bus
  assign cpu_mem_rdata =
    led_cs ? {24'h0, led} :
    char_ram_cs ? char_ram_dout :
    work_ram_cs ? work_ram_dout :
    rom_dout;

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
      .mem_valid(cpu_mem_valid),
      .mem_ready(cpu_mem_ready),
      .mem_addr (cpu_mem_addr),
      .mem_wdata(cpu_mem_wdata),
      .mem_wstrb(cpu_mem_wstrb),
      .mem_rdata(cpu_mem_rdata)
  );

  // ROM
  rom #(
      .MEM_INIT_FILE("build/rom.hex"),
      .DEPTH(1024)
  ) prog_rom (
      .clk(clk_25mhz),
      .addr(cpu_mem_addr[10:2]),
      .q(rom_dout)
  );

  // RAM
  ram #(
      .DEPTH(1024)
  ) work_ram (
      .clk(clk_25mhz),
      .we(work_ram_cs ? cpu_mem_wstrb : 0),
      .addr(cpu_mem_addr[10:2]),
      .data(cpu_mem_wdata),
      .q(work_ram_dout)
  );

  // GPU
  gpu gpu (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .char_ram_we(char_ram_cs ? cpu_mem_wstrb : 0),
      .char_ram_addr(cpu_mem_addr[8:2]),
      .char_ram_data(cpu_mem_wdata),
      .char_ram_q(char_ram_dout),
      .oled_cs(gp[0]),
      .oled_rst(gp[1]),
      .oled_dc(gp[3]),
      .oled_e(gp[2]),
      .oled_dout(gn)
  );

  // UART
  // reg uart_e_clk;
  // reg uart_baud_clk;
  // reg [7:0] baud_cnt = 0;
  //
  // always @(posedge clk_25mhz) begin
  //   uart_e_clk <= !uart_e_clk;
  //   uart_baud_clk <= baud_cnt > 81;
  //   baud_cnt <= baud_cnt + 1;
  //   if (baud_cnt > 162) baud_cnt <= 0;
  // end
  //
  // acia uart (
  //     .clk(clk_25mhz),
  //     .reset(!rst_n),
  //     .cs(uart_cs),
  //     .e_clk(uart_e_clk),
  //     .rw_n(!cpu_mem_wstrb[0]),
  //     .rs(cpu_mem_addr[2]),
  //     .data_in(cpu_mem_wdata[7:0]),
  //     .data_out(uart_dout),
  //     .txclk(uart_baud_clk),
  //     .rxclk(uart_baud_clk),
  //     .txdata(ftdi_rxd),
  //     .rxdata(ftdi_txd),
  //     .cts_n(0),
  //     .dcd_n(0)
  // );

  uart_tx #(
      .CLKS_PER_BIT(2604)
  ) uart (
      .i_Clock(clk_25mhz),
      .i_Tx_DV(uart_cs ? cpu_mem_wstrb[0] : 0),
      .i_Tx_Byte(cpu_mem_wdata[7:0]),
      .o_Tx_Active(uart_tx_active),
      .o_Tx_Serial(ftdi_rxd)
  );

endmodule
