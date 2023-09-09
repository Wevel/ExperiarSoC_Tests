`default_nettype none

`timescale 1 ns / 1 ps

`define FLASH_FILE "coreMemory.hex"

`define SPI_MEMORY0_ADDRESS_CORE 32'h1400_0000
`define SPI_MEMORY0_ADDRESS 32'h3400_0000
`define SPI_MEMORY0_CONFIG 32'h3480_0000
`define SPI_MEMORY0_STATUS 32'h3480_0004
`define SPI_MEMORY0_CURRENT_PAGE_ADDRESS 32'h3480_0008
`define SPI_MEMORY0_LOAD_ADDRESS 32'h3480_000C

`define SPI_MEMORY1_ADDRESS_CORE 32'h1500_0000
`define SPI_MEMORY1_ADDRESS 32'h3500_0000
`define SPI_MEMORY1_CONFIG 32'h3580_0000
`define SPI_MEMORY1_STATUS 32'h3580_0004
`define SPI_MEMORY1_CURRENT_PAGE_ADDRESS 32'h3580_0008
`define SPI_MEMORY1_LOAD_ADDRESS 32'h3580_000C

`define SPI_MEMORY_PAGE_SIZE_WORDS 32'd512
`define SPI_MEMORY_PAGE_SIZE_BYTES `SPI_MEMORY_PAGE_SIZE_WORDS * 4
`define SPI_MEMORY_ENABLE 3'b001
`define SPI_MEMORY_AUTOMATIC_MODE 3'b010
`define SPI_MEMORY_WRITE_ENABLE 3'b100

`define CPU_FREQUENCY 40000000 // Hz
`define UART1_BAUD_RATE 9216000

`define MAX_TEST_COUNT 120

module coreMemory_tb;
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

	wire user_ram_csb = user_io_out[12];
	wire user_ram_clk = user_io_out[13];
	wire user_ram_io0 = user_io_out[14];
	wire user_ram_io1;
	assign user_io_in[15] = user_ram_io1;

	wire succesOutput = user_io_out[16];
	wire nextTestOutput = user_io_out[17];
	wire completeTestSection = user_io_out[18];
	reg[(`TEST_NAME_LENGTH*5)-1:0] currentTestName = "";
	wire[31:0] testNumber;

	reg[31:0] wbAddress = 32'b0;
	reg[3:0] wbByteSelect = 4'b0;
	reg wbEnable = 1'b0;
	reg wbWriteEnable = 1'b0;
	reg[31:0] wbDataWrite = 32'b0;
	wire[31:0] wbDataRead;
	wire wbBusy;


	wire [2:0] user_irq_core;

	initial begin
		$dumpfile("coreMemory.vcd");
		$dumpvars(0, coreMemory_tb);
		`TIMEOUT(200)
		$finish;
	end

	initial begin
		@(negedge rst);
		#100

		// Setup output registers
		`WB_WRITE(`GPIO0_OUTPUT_WRITE_ADDR, `SELECT_WORD, 32'h01000)
		`WB_WRITE(`GPIO0_OE_WRITE_ADDR, `SELECT_WORD, 32'h07000)

		// Setup flash and spi ram
		`WB_WRITE(`SPI_MEMORY0_CONFIG, `SELECT_WORD, `SPI_MEMORY_ENABLE)
		`WB_WRITE(`SPI_MEMORY1_CONFIG, `SELECT_WORD, `SPI_MEMORY_ENABLE | `SPI_MEMORY_WRITE_ENABLE)

		// Wait for initialisation to complete
		#1000

		// Write the page address
		`WB_WRITE(`SPI_MEMORY0_CURRENT_PAGE_ADDRESS, `SELECT_WORD, 32'h0)
		`WB_WRITE(`SPI_MEMORY1_CURRENT_PAGE_ADDRESS, `SELECT_WORD, 32'h0)

		// Setup the flash for automatic page selection
		`WB_WRITE(`SPI_MEMORY0_CONFIG, `SELECT_WORD, `SPI_MEMORY_AUTOMATIC_MODE | `SPI_MEMORY_ENABLE)
		`WB_WRITE(`SPI_MEMORY1_CONFIG, `SELECT_WORD, `SPI_MEMORY_AUTOMATIC_MODE | `SPI_MEMORY_ENABLE | `SPI_MEMORY_WRITE_ENABLE)

		// Setup core0
		`WB_WRITE(`CORE0_REG_PC_ADDR, `SELECT_WORD, `SPI_MEMORY0_ADDRESS_CORE)
		`WB_WRITE(`CORE0_INSTRUCTION_BREAKPOINT_ADDR, `SELECT_WORD, `BREAKPOINT)

		// Run core0
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_RUN | `CORE_ENABLE_INSTRUCTION_BREAKPOINT)

		$display("Testing SRAM instructions, SRAM data");
		wait(testNumber == 24);

		$display("Testing SRAM instructions, flash data");
		wait(testNumber == 48);

		@(posedge completeTestSection)

		$display("Testing flash instructions, SRAM data");
		wait(testNumber == 72);

		$display("Testing flash instructions, flash data");
		wait(testNumber == 96);

		@(posedge completeTestSection)

		$display("Comparing flash and SRAM data");
		wait(testNumber == 120);

		@(posedge completeTestSection)

		$display("Testing spi RAM data");
		wait(testNumber == 148);

		@(posedge completeTestSection)

		$display("Testing bulk spi RAM data");
		wait(testNumber == 276);

		@(posedge completeTestSection)

		// Halt core0
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_HALT)

		`TESTS_COMPLETED
		$finish;
	end

	initial begin
		wait(testNumber > `MAX_TEST_COUNT);
		$display("%c[1;31mExceeded expected test count %d (reached %d)%c[0m", 27, `MAX_TEST_COUNT, testNumber, 27);
		`TESTS_FAIL
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

	SPI_Flash #(
		.FILENAME(`FLASH_FILE)
	) spiFlash (
		.csb(user_flash_csb),
		.clk(user_flash_clk),
		.io0(user_flash_io0),
		.io1(user_flash_io1),
		.io2(),			// not used
		.io3());		// not used
	
	SPI_RAM spiRam (
		.csb(user_ram_csb),
		.clk(user_ram_clk),
		.io0(user_ram_io0),
		.io1(user_ram_io1),
		.io2(),			// not used
		.io3());		// not used

endmodule
