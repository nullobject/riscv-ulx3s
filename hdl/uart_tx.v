module uart_tx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    input        we,
    input  [7:0] din,
    output       busy,

    output reg tx
);

  parameter IDLE = 0;
  parameter START_BIT = 1;
  parameter DATA_BITS = 2;
  parameter STOP_BIT = 3;

  reg [ 1:0] state = 0;
  reg [15:0] count;
  reg [ 2:0] index;
  reg [ 7:0] data;

  assign busy = state != IDLE;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      case (state)
        // Wait for start signal to be asserted
        IDLE: begin
          if (we == 1) state <= START_BIT;
          count <= 0;
          index <= 0;
          tx <= 1;
          data <= din;
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
          tx <= data[0];

          if (count == CLKS_PER_BIT - 1) begin
            if (index == 7) state <= STOP_BIT;
            count <= 0;
            index <= index + 1;
            data  <= {0, data[7:1]};
          end
        end

        // Send stop bit
        STOP_BIT: begin
          if (count == CLKS_PER_BIT - 1) state <= IDLE;
          count <= count + 1;
          tx <= 1;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
