`default_nettype none

`timescale 1 ns / 1 ps

`include "../RV32I.v"
`include "../UserSpace.v"
`include "../FastUART.v"

`define FLASH_FILE "snakeUART.hex"

`define FLASH_ADDRESS_CORE 32'h1400_0000
`define FLASH_ADDRESS 32'h3400_0000
`define FLASH_CONFIG 32'h3480_0000
`define FLASH_STATUS 32'h3480_0004
`define FLASH_CURRENT_PAGE_ADDRESS 32'h3480_0008
`define FLASH_LOAD_ADDRESS 32'h3480_000C
`define FLASH_PAGE_SIZE_WORDS 32'd512
`define FLASH_PAGE_SIZE_BYTES `FLASH_PAGE_SIZE_WORDS * 4

`define CPU_FREQUENCY 40000000 // Hz
`define UART1_BAUD_RATE 9216000

module snakeUART_tb;
	reg clk;
	reg rst;

	reg [127:0] la_data_in_user = 128'b0;  // From CPU to MPRJ
	wire [127:0] la_data_out_user; // From MPRJ to CPU
	reg [127:0] la_oenb_user = ~128'b0;	 // From CPU to MPRJ

	wire [`MPRJ_IO_PADS-1:0] user_io_oeb;
	wire [`MPRJ_IO_PADS-1:0] user_io_in;
	wire [`MPRJ_IO_PADS-1:0] user_io_out;
	wire [`MPRJ_IO_PADS-10:0] mprj_analog_io;

	wire user_flash_csb = user_io_out[8];
	wire user_flash_clk = user_io_out[9];
	wire user_flash_io0 = user_io_out[10];
	wire user_flash_io1;
	assign user_io_in[11] = user_flash_io1;

	reg[31:0] wbAddress = 32'b0;
	reg[3:0] wbByteSelect = 4'b0;
	reg wbEnable = 1'b0;
	reg wbWriteEnable = 1'b0;
	reg[31:0] wbDataWrite = 32'b0;
	wire[31:0] wbDataRead;
	wire wbBusy;

	reg uart_txEnable = 1'b0;
	reg[7:0] uart_txData = 8'b0;
	wire uart_txBusy;
	wire uart_rx = user_io_out[6];
	wire uart_tx;
	assign user_io_in[5] = uart_tx;
	wire uart_rxDataAvailable;
	wire[7:0] uart_rxData;

	pullup(uart_rx);

	reg succesOutput = 1'b1;
	reg nextTestOutput = 1'b0;
	reg[(`TEST_NAME_LENGTH*5)-1:0] currentTestName = "";
	wire[31:0] testNumber;

	wire [2:0]   user_irq_core;

	initial begin
		$dumpfile("snakeUART.vcd");
		$dumpvars(0, snakeUART_tb);
		//`TIMEOUT(2000)
		`TIMEOUT(200)
		$finish;
	end

	integer counter = 0;
	reg[31:0] testValue = 32'b0;
	reg[7:0] testChar = 8'b0;
	initial begin
		@(negedge rst);
		#100

		// Read the initial flash status
		`TEST_READ_EQ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b0, "Read initial flash status")
		`TEST_READ_EQ(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b0, "Read initial flash config")

		`TEST_WRITE_EQ(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b01, "Set flash config to manual page selection")

		// Wait for initialisation to complete
		#1000
		`TEST_READ_EQ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b01, "Read flash status to check for initialisation complete")

		// Write the page address
		`TEST_WRITE_EQ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h0, "Write page address to 0")

		// Setup the flash for automatic page selection
		`TEST_WRITE_EQ(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b11, "Set flash config to automatic page selection")
		`TEST_READ_EQ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b11, "Read flash status after automatic page selection")

		// Initialise core0
		`TEST_READ_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Read core0 config before initialisation")
		`TEST_WRITE_EQ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue, `FLASH_ADDRESS_CORE, "Write core0 PC start of flash address")
		
		// Setup core0 instruction breakpoint
		`TEST_WRITE_EQ(`CORE0_INSTRUCTION_BREAKPOINT_ADDR, `SELECT_WORD, testValue, `BREAKPOINT, "Write core0 instruction breakpoint address")

		// Run core0
		`TEST_WRITE_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_RUN | `CORE_ENABLE_INSTRUCTION_BREAKPOINT, "Write core0 config to run")

		// @(posedge uart_rx);

		// Wait for core0 to finish initialisation and print the welcome message
		`TEST_RX(testChar, testChar == "H", "Check for 'H' from UART")
		`TEST_RX(testChar, testChar == "e", "Check for 'e' from UART")
		`TEST_RX(testChar, testChar == "l", "Check for 'l' from UART")
		`TEST_RX(testChar, testChar == "l", "Check for 'l' from UART")
		`TEST_RX(testChar, testChar == "o", "Check for 'o' from UART")

		// Play the game for a bit
		// Get first food
		`TEST_TX("s", "Send 's' to UART")
		`TEST_TX("s", "Send 's' to UART")
		`TEST_TX("a", "Send 'a' to UART")

		// Wait for score to increase

		// Get Second food
		`TEST_TX("w", "Send 'w' to UART")
		`TEST_TX("w", "Send 'w' to UART")
		`TEST_TX("w", "Send 'w' to UART")
		`TEST_TX("w", "Send 'w' to UART")
		`TEST_TX("w", "Send 'w' to UART")
		// `TEST_TX("d", "Send 'd' to UART")

		// Wait for score to increase

		// Get Third food
		`TEST_TX("d", "Send 'd' to UART")
		`TEST_TX("s", "Send 's' to UART")
		`TEST_TX("s", "Send 's' to UART")
		`TEST_TX("s", "Send 's' to UART")
		`TEST_TX("s", "Send 's' to UART")

		// Wait for score to increase

		// Run back into self
		`TEST_TX("a", "Send 'a' to UART")
		`TEST_TX("w", "Send 'w' to UART")
		`TEST_TX("d", "Send 'd' to UART")

		// Make sure the game ended

		// Wait for core to halt at breakpoint
		`TEST_READ_TIMEOUT(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, testValue == `CORE_ENABLE_INSTRUCTION_BREAKPOINT, 10000, 10000, "Core0 halts at end of program")

		// Make sure the core has halted
		`TEST_READ_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Read core0 config after halt")

		// TODO: Check game variables

		#100

		`TESTS_COMPLETED
		$finish;
	end

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.
	always #12.5 clk <= (clk === 1'b0);

	initial begin
		rst <= 1'b1;
		#2000;
		rst <= 1'b0; // Release reset
	end

	UserSpace userSpace(
		.clk(clk),
		.rst(rst),
		.la_data_in_user(la_data_in_user),
		.la_data_out_user(la_data_out_user),
		.la_oenb_user(la_oenb_user),
		.user_io_oeb(user_io_oeb),
		.user_io_in(user_io_in),
		.user_io_out(user_io_out),
		.mprj_analog_io(mprj_analog_io),
		.user_irq_core(user_irq_core),
		.wbAddress(wbAddress),
		.wbByteSelect(wbByteSelect),
		.wbEnable(wbEnable),
		.wbWriteEnable(wbWriteEnable),
		.wbDataWrite(wbDataWrite),
		.wbDataRead(wbDataRead),
		.wbBusy(wbBusy),
		.succesOutput(succesOutput),
		.nextTestOutput(nextTestOutput),
		.currentTestName(currentTestName),
		.testNumber(testNumber));

	spiflash #(
		.FILENAME(`FLASH_FILE)
	) testflash (
		.csb(user_flash_csb),
		.clk(user_flash_clk),
		.io0(user_flash_io0),
		.io1(user_flash_io1),
		.io2(),			// not used
		.io3());		// not used
	
	FastUART #(
		.CLK_FREQ(`CPU_FREQUENCY),
		.BAUD(`UART1_BAUD_RATE)) 
	uart (
		.clk(clk),
		.rst(rst),
		.txEnable(uart_txEnable),
		.txData(uart_txData),
		.txBusy(uart_txBusy),
		.rxDataAvailable(uart_rxDataAvailable),
		.rxData(uart_rxData),
		.rx(uart_rx),
		.tx(uart_tx));

endmodule
