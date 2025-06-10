module uart_rx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    input            re,
    output reg       valid,
    output reg [7:0] dout,

    input rx
);

  parameter IDLE = 0;
  parameter RX_START_BIT = 1;
  parameter RX_DATA_BITS = 2;
  parameter RX_STOP_BIT = 3;
  parameter CLEANUP = 4;

  reg [2:0] state = 0;
  reg [15:0] count;
  reg [2:0] index;
  reg r_Rx_Data_R;
  reg r_Rx_Data;

  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_Rx_Data_R <= 1;
      r_Rx_Data   <= 1;
    end else begin
      r_Rx_Data_R <= rx;
      r_Rx_Data   <= r_Rx_Data_R;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          valid <= 0;
          count <= 0;
          index <= 0;

          if (r_Rx_Data == 0) state <= RX_START_BIT;
        end

        // Check middle of start bit to make sure it's still low
        RX_START_BIT: begin
          if (count == (CLKS_PER_BIT - 1) / 2) begin
            if (r_Rx_Data == 0) begin
              state <= RX_DATA_BITS;
              count <= 0;
            end else state <= IDLE;
          end else begin
            count <= count + 1;
          end
        end

        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        RX_DATA_BITS: begin
          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
          end else begin
            count       <= 0;
            dout[index] <= r_Rx_Data;

            if (index < 7) begin
              index <= index + 1;
            end else begin
              state <= RX_STOP_BIT;
              index <= 0;
            end
          end
        end

        // Receive Stop bit.  Stop bit = 1
        RX_STOP_BIT: begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (count < CLKS_PER_BIT - 1) begin
            count <= count + 1;
          end else begin
            state <= CLEANUP;
            valid <= 1;
            count <= 0;
          end
        end

        // Stay here 1 clock
        CLEANUP: begin
          state <= IDLE;
          valid <= 0;
        end

        default: state <= IDLE;
      endcase
    end
  end
endmodule
