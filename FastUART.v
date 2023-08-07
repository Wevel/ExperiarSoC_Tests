`default_nettype none
`timescale 1 ns / 1 ps

`define UART_TX(DATA) \
	@(negedge clk) \ // Wait till before clock rising edge
	#1 \
	wait(!uart_txBusy); \ // Wait for tx to be free
	uart_txData <= DATA; \
	uart_txEnable <= 1'b1; \ // Start tx
	@(posedge clk) \ // Wait for tx to complete
	uart_txEnable <= 1'b0;

`define UART_RX(DATA) \
	@(negedge clk) \ // Wait till before clock rising edge
	#1 \
	@(posedge uart_rxDataAvailable) \ // Wait for data to be ready
	DATA <= uart_rxData; // Return data

`define TEST_RX(DATA, RESULT_COMPARISON, TEST_NAME) \
	`UART_RX(DATA) \
	`TEST_RESULT(RESULT_COMPARISON, TEST_NAME)

`define TEST_TX(DATA, TEST_NAME) \
	`UART_TX(DATA) \
	`TEST_RESULT(1'b1, TEST_NAME)

module FastUART #(
		parameter CLOCK_SCALE_BITS = 16,
		parameter CLK_FREQ = 100000000,
		parameter BAUD = 115200
	)(
		input wire clk,
		input wire rst,

		// Control Interface
		input wire txEnable,
		input wire [7:0] txData,
		output wire txBusy,

		output wire rxDataAvailable,
		output wire [7:0] rxData,

		// UART Interface
		input wire rx,
		output wire tx
	);

	wire[CLOCK_SCALE_BITS-1:0] cyclesPerBit = ((CLK_FREQ + BAUD) / BAUD) - 1;

	UART_rx rxPort(
		.clk(clk),
		.rst(rst),
		.cyclesPerBit(cyclesPerBit),
		.rx(rx),
		.dataOut(rxData),
    	.dataAvailable(rxDataAvailable));

	always @(negedge clk) begin
		if (!rst) begin
			if (rxDataAvailable) begin
				$write("%c", rxData);
				$fflush();
			end
		end
	end

	UART_tx txPort(
		.clk(clk),
		.rst(rst),
		.cyclesPerBit(cyclesPerBit),
		.tx(tx),
		.blockTransmition(1'b0),
    	.busy(txBusy),
    	.dataIn(txData),
    	.dataAvailable(txEnable));
endmodule