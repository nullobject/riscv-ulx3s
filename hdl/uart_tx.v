module uart_tx #(
    parameter CLKS_PER_BIT = 100
) (
    input clk,
    input rst_n,

    output       busy,
    input        we,
    input  [7:0] din,

    output reg tx
);

  parameter IDLE = 0;
  parameter TX_START_BIT = 1;
  parameter TX_DATA_BITS = 2;
  parameter TX_STOP_BIT = 3;

  reg [ 2:0] state = 0;
  reg [15:0] count;
  reg [ 2:0] index;
  reg [ 7:0] data;

  assign busy = state != IDLE;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          tx    <= 1;
          count <= 0;
          index <= 0;

          if (we == 1'b1) begin
            data  <= din;
            state <= TX_START_BIT;
          end else state <= IDLE;
        end

        TX_START_BIT: begin
          tx <= 0;

          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
            state <= TX_START_BIT;
          end else begin
            count <= 0;
            state <= TX_DATA_BITS;
          end
        end

        TX_DATA_BITS: begin
          tx <= data[index];

          // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish
          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
            state <= TX_DATA_BITS;
          end else begin
            count <= 0;

            // Check if we have sent out all bits
            if (index < 7) begin
              index <= index + 1;
              state <= TX_DATA_BITS;
            end else begin
              index <= 0;
              state <= TX_STOP_BIT;
            end
          end
        end

        TX_STOP_BIT: begin
          tx <= 1;

          // Wait CLKS_PER_BIT-1 clock cycles for stop bit to finish
          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
            state <= TX_STOP_BIT;
          end else begin
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
