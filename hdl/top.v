module top (
    input clk_25mhz,
    input [6:0] btn,
    input ftdi_txd,
    output ftdi_rxd,
    output wifi_gpio0,
    output reg [7:0] led,
    output [7:0] gp,
    output [7:0] gn,
    input uart0_rx,
    output uart0_tx,
    input uart1_rx,
    output uart1_tx,
    input enc_a,
    input enc_b
);

  localparam CLOCK_FREQ = 25_000_000;

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
  // 0000-3FFF ROM
  // 4000-7FFF WORK RAM
  // 8000-81FF VIDEO RAM
  // 9000      LED
  // A000-A004 UART
  // B000-B00C ENCODERS
  // C000      PRNG
  wire rom_cs = cpu_mem_valid && cpu_mem_addr[15:12] >= 4'h0 && cpu_mem_addr[15:12] <= 4'h3;
  wire work_ram_cs = cpu_mem_valid && cpu_mem_addr[15:12] >= 4'h4 && cpu_mem_addr[15:12] <= 4'h7;
  wire vram_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'h8;
  wire led_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'h9;
  wire uart_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'hA;
  wire encoder_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'hB;
  wire prng_cs = cpu_mem_valid && cpu_mem_addr[15:12] == 4'hC;

  reg rom_valid;
  wire [31:0] rom_dout;
  reg work_ram_valid;
  wire [31:0] work_ram_dout;
  reg vram_valid;
  wire [31:0] vram_dout;

  wire [7:0] uart0_rx_dout, uart1_rx_dout;
  wire uart0_empty, uart1_empty;
  wire uart0_full, uart1_full;
  wire uart0_irq, uart1_irq;
  wire uart0_cs = uart_cs && cpu_mem_addr[2] == 0;
  wire uart1_cs = uart_cs && cpu_mem_addr[2] == 1;
  wire uart0_valid = uart0_cs && ((!cpu_mem_wstrb && uart0_full) || (cpu_mem_wstrb[0] && uart0_empty));
  wire uart1_valid = uart1_cs && ((!cpu_mem_wstrb && uart1_full) || (cpu_mem_wstrb[0] && uart1_empty));

  wire [31:0] encoder_dout;

  wire [31:0] prng_dout;
  wire prng_valid;
  wire prng_ready = prng_cs && prng_valid;

  // IRQ bitmask
  wire [31:0] cpu_irq = {27'b0, uart1_irq, uart0_irq, 3'b0};

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
    uart0_valid ||
    uart1_valid ||
    encoder_cs ||
    prng_ready;

  // Multiplex read data bus
  assign cpu_mem_rdata =
    rom_cs ? rom_dout :
    work_ram_cs ? work_ram_dout :
    vram_cs ? vram_dout :
    led_cs ? {24'b0, led} :
    uart0_cs ? {24'b0, uart0_rx_dout} :
    uart1_cs ? {24'b0, uart1_rx_dout} :
    encoder_cs ? encoder_dout :
    prng_cs ? prng_dout :
    0;

  // CPU
  picorv32 #(
      .STACKADDR(32'h0000_8000),
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
      .DEPTH(4096)
  ) prog_rom (
      .clk(clk_25mhz),
      .addr(cpu_mem_addr[13:2]),
      .q(rom_dout)
  );

  // RAM
  ram #(
      .DEPTH(4096)
  ) work_ram (
      .clk(clk_25mhz),
      .we(work_ram_cs ? cpu_mem_wstrb : 0),
      .addr(cpu_mem_addr[13:2]),
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

  // UART0 (SERIAL)
  uart #(
      .CLKS_PER_BIT(CLOCK_FREQ / 9600)
  ) uart0 (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .we(uart0_cs && cpu_mem_wstrb[0]),
      .re(uart0_cs && !cpu_mem_wstrb),
      .empty(uart0_empty),
      .full(uart0_full),
      .irq(uart0_irq),
      .din(cpu_mem_wdata[7:0]),
      .dout(uart0_rx_dout),
      .rx(uart0_rx),
      .tx(uart0_tx)
  );

  // UART1 (MIDI)
  uart #(
      .CLKS_PER_BIT(CLOCK_FREQ / 31250)
  ) uart1 (
      .clk(clk_25mhz),
      .rst_n(rst_n),
      .we(uart1_cs && cpu_mem_wstrb[0]),
      .re(uart1_cs && !cpu_mem_wstrb),
      .empty(uart1_empty),
      .full(uart1_full),
      .irq(uart1_irq),
      .din(cpu_mem_wdata[7:0]),
      .dout(uart1_rx_dout),
      .rx(uart1_rx),
      .tx(uart1_tx)
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
