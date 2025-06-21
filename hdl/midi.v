/**
 * Handles MIDI parameters.
 */
module midi (
    input clk,
    input rst_n,

    // Parameter RAM
    input  [ 3:0] param_ram_we,
    input  [ 7:2] param_ram_addr,
    input  [31:0] param_ram_data,
    output [31:0] param_ram_q
);

  wire [ 6:0] param_ram_addr_b;
  wire [15:0] param_ram_q_b;

  dual_port_ram #(
      .DEPTH(64),
      .ADDR_WIDTH_A(6),
      .ADDR_WIDTH_B(7)
  ) param_ram (
      .clk(clk),

      // port A
      .we_a(param_ram_we),
      .addr_a(param_ram_addr[7:2]),
      .data_a(param_ram_data),
      .q_a(param_ram_q),

      // port B
      .addr_b(param_ram_addr_b),
      .q_b(param_ram_q_b)
  );

endmodule
