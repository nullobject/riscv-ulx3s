module uart_tx #(
    parameter CLKS_PER_BIT = 1000,
    parameter INVERT = 0
) (
    input clk,
    input rst_n,

    // Control signals
    input      we,
    output reg empty,
    output reg done,

    // Data bus
    input [7:0] din,

    // Serial data
    output tx
);

  parameter IDLE = 0;
  parameter START_BIT = 1;
  parameter DATA_BITS = 2;
  parameter STOP_BIT = 3;

  reg [1:0] state = 0;
  reg [15:0] count;
  reg [2:0] index;
  reg [7:0] shift_reg;

  reg serial_tx;
  assign tx = INVERT ? !serial_tx : serial_tx;

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
            shift_reg <= din;
            empty <= 0;
          end
          count <= 0;
          index <= 0;
          done <= 0;
          serial_tx <= 1;
        end

        // Send start bit
        START_BIT: begin
          count <= count + 1;
          serial_tx <= 0;

          if (count == CLKS_PER_BIT - 1) begin
            state <= DATA_BITS;
            count <= 0;
          end
        end

        // Send data bits
        DATA_BITS: begin
          count <= count + 1;
          serial_tx <= shift_reg[0];

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
          serial_tx <= 1;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
