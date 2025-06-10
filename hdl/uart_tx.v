module uart_tx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    input        we,
    output       busy,
    input  [7:0] din,

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
          tx    <= 1;
          count <= 0;
          index <= 0;
          data  <= din;

          if (we == 1) state <= START_BIT;
        end

        // Send start bit
        START_BIT: begin
          tx <= 0;

          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
          end else begin
            state <= DATA_BITS;
            count <= 0;
          end
        end

        // Send data bits
        DATA_BITS: begin
          tx <= data[index];

          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
          end else begin
            count <= 0;

            if (index < 7) begin
              index <= index + 1;
            end else begin
              state <= STOP_BIT;
              index <= 0;
            end
          end
        end

        // Send stop bit
        STOP_BIT: begin
          tx <= 1;

          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
          end else begin
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
