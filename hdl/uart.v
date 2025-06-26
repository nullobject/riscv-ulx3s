/**
 * Simple UART controller.
 */
module uart #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    // Control signals
    input      we,
    input      re,
    output reg empty,
    output reg full,
    output reg done,

    // Data bus
    input      [7:0] din,
    output reg [7:0] dout,

    // Serial data
    output tx,
    input  rx
);

  uart_tx #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_tx (
      .clk(clk),
      .rst_n(rst_n),
      .we(we),
      .empty(empty),
      .data(din),
      .tx(tx)
  );

  uart_rx #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_rx (
      .clk(clk),
      .rst_n(rst_n),
      .re(re),
      .full(full),
      .done(done),
      .data(dout),
      .rx(rx)
  );

endmodule

module uart_rx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    // Control signals
    input      re,
    output reg full,
    output reg done,

    // Data bus
    output reg [7:0] data,

    // Serial data
    input rx
);

  // States
  localparam IDLE = 0;
  localparam RX_START_BIT = 1;
  localparam RX_DATA_BITS = 2;
  localparam RX_STOP_BIT = 3;

  reg [ 1:0] state = 0;
  reg [15:0] count;
  reg [ 2:0] index;
  reg [ 7:0] shift_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      full  <= 0;
    end else begin
      if (re) full <= 0;

      case (state)
        IDLE: begin
          if (!full && !rx) state <= RX_START_BIT;
          count <= 0;
          index <= 0;
          done  <= 0;
        end

        // Check middle of start bit to make sure it's still low
        RX_START_BIT: begin
          count <= count + 1;

          if (count == (CLKS_PER_BIT - 1) / 2) begin
            if (!rx) begin
              state <= RX_DATA_BITS;
              count <= 0;
            end else state <= IDLE;
          end
        end

        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        RX_DATA_BITS: begin
          count <= count + 1;

          if (count == CLKS_PER_BIT - 1) begin
            if (index == 7) state <= RX_STOP_BIT;
            count <= 0;
            index <= index + 1;
            shift_reg = {rx, shift_reg[7:1]};
          end
        end

        // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
        RX_STOP_BIT: begin
          count <= count + 1;

          if (count == CLKS_PER_BIT - 1) begin
            state <= IDLE;
            count <= 0;
            data  <= shift_reg;
            full  <= 1;
            done  <= 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end
endmodule

module uart_tx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    // Control signals
    input      we,
    output reg empty,
    output reg done,

    // Data buswish
    input [7:0] data,

    // Serial data
    output reg tx
);

  // States
  localparam IDLE = 0;
  localparam START_BIT = 1;
  localparam DATA_BITS = 2;
  localparam STOP_BIT = 3;

  reg [ 1:0] state = 0;
  reg [15:0] count;
  reg [ 2:0] index;
  reg [ 7:0] shift_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      empty <= 1;
    end else begin
      case (state)
        // Wait for start signal to be asserted
        IDLE: begin
          if (we == 1) begin
            state <= START_BIT;
            shift_reg <= data;
            empty <= 0;
          end
          count <= 0;
          index <= 0;
          done <= 0;
          tx <= 1;
        end

        // Send start bit
        START_BIT: begin
          count <= count + 1;
          tx <= 0;

          if (count == CLKS_PER_BIT - 1) begin
            state <= DATA_BITS;
            count <= 0;
          end
        end

        // Send data bits
        DATA_BITS: begin
          count <= count + 1;
          tx <= shift_reg[0];

          if (count == CLKS_PER_BIT - 1) begin
            if (index == 7) state <= STOP_BIT;
            count <= 0;
            index <= index + 1;
            shift_reg <= {0, shift_reg[7:1]};
          end
        end

        // Send stop bit
        STOP_BIT: begin
          if (count == CLKS_PER_BIT - 1) begin
            state <= IDLE;
            empty <= 1;
          end
          count <= count + 1;
          done <= 1;
          tx <= 1;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
