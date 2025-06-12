module uart_rx #(
    parameter CLKS_PER_BIT = 1000
) (
    input clk,
    input rst_n,

    input            re,
    output reg [7:0] dout,
    output reg       full,

    input rx
);

  parameter IDLE = 0;
  parameter RX_START_BIT = 1;
  parameter RX_DATA_BITS = 2;
  parameter RX_STOP_BIT = 3;

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
            dout  <= shift_reg;
            full  <= 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end
endmodule
