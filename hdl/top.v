module top (
    input clk_25mhz,
    input [6:0] btn,
    input ftdi_txd,
    output ftdi_rxd,
    output wifi_gpio0,
    output reg [7:0] led,
    output [7:0] gp,
    output [7:0] gn,
    output ser_tx,
    input ser_rx,
    input enc_a,
    input enc_b
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

  // Chip select
  //
  // 0000-0FFF ROM
  // 1000-1FFF WORK RAM
  // 2000-21FF VIDEO RAM
  // 3000      LED
  // 4000      UART
  // 5000      ENCODERS
  // 6000      PRNG
  wire rom_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 0;
  wire work_ram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 1;
  wire vram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 2;
  wire led_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 3;
  wire uart_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4;
  wire encoder_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 5;
  wire prng_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 6;

  reg rom_valid;
  wire [31:0] rom_dout;
  reg work_ram_valid;
  wire [31:0] work_ram_dout;
  reg vram_valid;
  wire [31:0] vram_dout;

  wire [7:0] uart_rx_dout;
  wire uart_empty, uart_full, uart_irq;
  wire uart_valid = uart_cs && ((!cpu_mem_wstrb && uart_full) || (cpu_mem_wstrb[0] && uart_empty));

  wire [31:0] encoder_dout;

  wire [31:0] prng_dout;
  wire prng_valid;
  wire prng_ready = prng_cs && prng_valid;

  // IRQ bitmask
  wire [31:0] cpu_irq = {28'b0, uart_irq, 3'b0};

  // Update reset count register
  always @(posedge clk_25mhz) reset_cnt <= reset_cnt + !rst_n;

  // Update LED register
  always @(posedge clk_25mhz) if (led_cs && cpu_mem_wstrb[0]) led <= cpu_mem_wdata[7:0];

  // Update memory valid registers
  always @(posedge clk_25mhz) begin
    rom_valid      <= rom_cs;
    work_ram_valid <= work_ram_cs;
    vram_valid     <= vram_cs;
  end

  // Set CPU memory ready signal
  assign cpu_mem_ready =
    rom_valid ||
    work_ram_valid ||
    vram_valid ||
    led_cs ||
    uart_valid ||
    encoder_cs ||
    prng_ready;

  // Multiplex read data bus
  assign cpu_mem_rdata =
    rom_cs ? rom_dout :
    work_ram_cs ? work_ram_dout :
    vram_cs ? vram_dout :
    led_cs ? {24'b0, led} :
    uart_cs ? {24'b0, uart_rx_dout} :
    encoder_cs ? encoder_dout :
    prng_cs ? prng_dout :
    0;

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
      .vram_we(vram_cs ? cpu_mem_wstrb : 0),
      .vram_addr(cpu_mem_addr[8:2]),
      .vram_data(cpu_mem_wdata),
      .vram_q(vram_dout),
      .oled_cs(gp[0]),
      .oled_rst(gp[1]),
      .oled_dc(gp[3]),
      .oled_e(gp[2]),
      .oled_dout(gn)
  );

  // UART
  uart #(
      .CLKS_PER_BIT(2604)
  ) uart (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .we(uart_cs && cpu_mem_wstrb[0]),
      .re(uart_cs && !cpu_mem_wstrb),
      .empty(uart_empty),
      .full(uart_full),
      .irq(uart_irq),
      .din(cpu_mem_wdata[7:0]),
      .dout(uart_rx_dout),
      .tx(ser_tx),
      .rx(ser_rx)
  );

  // Encoders
  encoders encoders (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .reg_we(encoder_cs ? cpu_mem_wstrb : 0),
      .reg_addr(cpu_mem_addr[3:2]),
      .reg_data(cpu_mem_wdata),
      .reg_q(encoder_dout),
      .a(enc_a),
      .b(enc_b)
  );

  // PRNG
  axis_mt19937 prng (
      .clk(clk_25mhz),
      .rst(!rst_n),
      .output_axis_tdata(prng_dout),
      .output_axis_tvalid(prng_valid),
      .output_axis_tready(prng_cs),
      .seed_val(0),
      .seed_start(0)
  );

endmodule
