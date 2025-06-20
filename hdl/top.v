module top (
    input clk_25mhz,
    input [6:0] btn,
    input ftdi_txd,
    output ftdi_rxd,
    output wifi_gpio0,
    output reg [7:0] led,
    output [7:0] gp,
    output [7:0] gn,
    output serial_tx,
    input serial_rx
);

  assign wifi_gpio0 = 1;

  reg [5:0] reset_cnt = 0;
  wire rst_n = &reset_cnt & btn[0];

  wire cpu_mem_valid;
  wire cpu_mem_ready;
  wire [31:0] cpu_mem_addr;
  wire [31:0] cpu_mem_wdata;
  wire [3:0] cpu_mem_wstrb;
  wire [31:0] cpu_mem_rdata;

  // chip select
  //
  // 0000-0FFF ROM
  // 1000-1FFF RAM
  // 2000-21FF CHAR RAM
  // 2800-28FF PARAM RAM
  // 3000      LED
  // 4000      UART
  wire rom_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0000;
  wire work_ram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0001;
  wire char_ram_cs = cpu_mem_valid && cpu_mem_addr[15:11] == 5'b0010_0;
  wire param_ram_cs = cpu_mem_valid && cpu_mem_addr[15:11] == 5'b0010_1;
  wire led_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0011;
  wire uart_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'b0100;

  reg rom_ready;
  wire [31:0] rom_dout;
  reg work_ram_ready;
  wire [31:0] work_ram_dout;
  reg char_ram_ready;
  wire [31:0] char_ram_dout;
  reg param_ram_ready;
  wire [31:0] param_ram_dout;

  wire [7:0] uart_rx_dout;
  wire uart_rx_full;
  wire uart_rx_done;
  wire uart_tx_empty;
  wire uart_ready = uart_cs &&
    ((!cpu_mem_wstrb && uart_rx_full) || (cpu_mem_wstrb[0] && uart_tx_empty));

  // IRQ bitmask
  wire [31:0] cpu_irq = {28'b0, uart_rx_done, 3'b0};

  // Update reset count register
  always @(posedge clk_25mhz) reset_cnt <= reset_cnt + !rst_n;

  // Update LED register
  always @(posedge clk_25mhz) if (led_cs && cpu_mem_wstrb[0]) led <= cpu_mem_wdata[7:0];

  // Update memory ready registers
  always @(posedge clk_25mhz) begin
    rom_ready       <= rom_cs;
    work_ram_ready  <= work_ram_cs;
    char_ram_ready  <= char_ram_cs;
    param_ram_ready <= param_ram_cs;
  end

  // Set CPU memory ready signal
  assign cpu_mem_ready =
    rom_ready ||
    work_ram_ready ||
    char_ram_ready ||
    param_ram_ready ||
    uart_ready ||
    led_cs;

  // Set CPU memory read data bus
  assign cpu_mem_rdata =
    uart_cs ? {24'b0, uart_rx_dout} :
    led_cs ? {24'b0, led} :
    param_ram_cs ? param_ram_dout :
    char_ram_cs ? char_ram_dout :
    work_ram_cs ? work_ram_dout :
    rom_dout;

  // CPU
  picorv32 #(
      .STACKADDR(32'h0000_2000),
      .BARREL_SHIFTER(1),
      .COMPRESSED_ISA(1),
      .ENABLE_MUL(1),
      .ENABLE_DIV(1),
      .ENABLE_IRQ(1),
      .ENABLE_IRQ_QREGS(0)
  ) cpu (
      .clk      (clk_25mhz),
      .resetn   (rst_n),
      .mem_valid(cpu_mem_valid),
      .mem_ready(cpu_mem_ready),
      .mem_addr (cpu_mem_addr),
      .mem_wdata(cpu_mem_wdata),
      .mem_wstrb(cpu_mem_wstrb),
      .mem_rdata(cpu_mem_rdata),
      .irq      (cpu_irq)
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

  // MIDI
  midi midi (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .param_ram_we(param_ram_cs ? cpu_mem_wstrb : 0),
      .param_ram_addr(cpu_mem_addr[7:2]),
      .param_ram_data(cpu_mem_wdata),
      .param_ram_q(param_ram_dout)
  );

  // UART
  uart_rx #(
      .CLKS_PER_BIT(2604),
      .INVERT(1)
  ) uart_rx (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .re(uart_cs && !cpu_mem_wstrb),
      .dout(uart_rx_dout),
      .full(uart_rx_full),
      .done(uart_rx_done),
      .rx(serial_rx)
  );

  uart_tx #(
      .CLKS_PER_BIT(2604),
      .INVERT(1)
  ) uart_tx (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .we(uart_cs && cpu_mem_wstrb[0]),
      .din(cpu_mem_wdata[7:0]),
      .empty(uart_tx_empty),
      .tx(serial_tx)
  );

endmodule
