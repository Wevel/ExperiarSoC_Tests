`default_nettype none

`timescale 1 ns / 1 ps

`include "../RV32I.v"
`include "../UserSpace.v"

`define FLASH_FILE "userSpaceFlash.hex"

`define FLASH_ADDRESS 32'h3400_0000
`define FLASH_CONFIG 32'h3480_0000
`define FLASH_STATUS 32'h3480_0004
`define FLASH_CURRENT_PAGE_ADDRESS 32'h3480_0008
`define FLASH_LOAD_ADDRESS 32'h3480_000C
`define FLASH_PAGE_SIZE_WORDS 32'd512
`define FLASH_PAGE_SIZE_BYTES `FLASH_PAGE_SIZE_WORDS * 4

`define FLASH_WORD(ADDRESS) { flashMemory[{ADDRESS, 2'b00} + 3], flashMemory[{ADDRESS, 2'b00} + 2], flashMemory[{ADDRESS, 2'b00} + 1], flashMemory[{ADDRESS, 2'b00}] }

`define TEST_FLASH(ADDRESS, TEST_NAME) `TEST_READ(`OFFSET_WORD(`FLASH_ADDRESS, ADDRESS), `SELECT_WORD, testValue, `FLASH_WORD((ADDRESS) & 32'h000_ffff), TEST_NAME)
`define TEST_MANUAL_FLASH(PAGE, ADDRESS, TEST_NAME) `TEST_READ(`OFFSET_WORD(`FLASH_ADDRESS, ADDRESS), `SELECT_WORD, testValue, `FLASH_WORD(((PAGE * `FLASH_PAGE_SIZE_WORDS) + ADDRESS) & 32'h000_ffff), TEST_NAME)

module userSpaceFlash_tb;
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

	reg succesOutput = 1'b1;
	reg nextTestOutput = 1'b0;
	reg[(`TEST_NAME_LENGTH*5)-1:0] currentTestName = "";

	wire [2:0]   user_irq_core;

	initial begin
		$dumpfile("userSpaceFlash.vcd");
		$dumpvars(0, userSpaceFlash_tb);
		`TIMEOUT(120)
		$finish;
	end

	reg [7:0] flashMemory [0:8*1024*1024-1];

	initial begin
		$readmemh(`FLASH_FILE, flashMemory);
	end

	reg[31:0] testValue = 32'b0;
	reg[31:0] testCompareValue = 32'b0;
	initial begin
		@(negedge rst);
		#100

		// Read the initial flash status
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b0, "Read initial flash status")
		`TEST_READ(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b0, "Read initial flash config")

		// Setup the flash for manual page selection
		`TEST_WRITE(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b01, "Set flash config to manual page selection")
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b00, "Read flash status after manual page selection")

		// Wait for initialisation to complete
		#200
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b01, "Read flash status to check for initialisation complete")

		// Write the page address
		`TEST_WRITE(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h0, "Write page address to 0")

		// Check that page loading has started
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b11, "Read flash status to check for page loading started")


		// Read data from the page to test that it is loaded correctly
		`TEST_MANUAL_FLASH(32'h0, 32'h00, "Read word 0x00 from page 0")

		`WB_READ(`FLASH_LOAD_ADDRESS, `SELECT_WORD, testCompareValue)
		`TEST_RESULT(testCompareValue > 32'b0, "Check flash load address is greater than 0")

		`TEST_MANUAL_FLASH(32'h0, 32'h01, "Read word 0x01 from page 0")

		`WB_READ(`FLASH_LOAD_ADDRESS, `SELECT_WORD, testValue)
		`TEST_RESULT(testValue > testCompareValue, "Check flash load address is increasing")

		`TEST_MANUAL_FLASH(32'h0, 32'h02, "Read word 0x02 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h03, "Read word 0x03 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h10, "Read word 0x10 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h11, "Read word 0x11 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h12, "Read word 0x12 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h13, "Read word 0x13 from page 0")

		// Make sure to wait for the final byte to load
		`TEST_MANUAL_FLASH(32'h0, 32'h1FF, "Read word 0x1FF from page 0")

		// Check that page loading is complete
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b01, "Read flash status to check for page loading complete")

		// Change to a new page
		`WB_WRITE(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, 32'h2)
		`WB_READ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue)
		`TEST_RESULT(testValue == (32'h2 * `FLASH_PAGE_SIZE_BYTES), "Write page address to 2")

		// Check that page loading has started
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b11, "Read flash status to check for page loading started")

		// Read data from the page to test that it is loaded correctly
		`TEST_MANUAL_FLASH(32'h2, 32'h00, "Read word 0x00 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h01, "Read word 0x01 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h02, "Read word 0x02 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h03, "Read word 0x03 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h10, "Read word 0x10 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h11, "Read word 0x11 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h12, "Read word 0x12 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h13, "Read word 0x13 from page 2")
		
		// Setup the flash for automatic page selection
		`TEST_WRITE(`FLASH_CONFIG, `SELECT_WORD, testValue, 32'b11, "Set flash config to automatic page selection")
		`TEST_READ(`FLASH_STATUS, `SELECT_WORD, testValue, 32'b01, "Read flash status after automatic page selection")
		
		// Read current page address
		`TEST_READ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h00001000, "Read current page address after automatic page selection setup")

		// Read from the first page
		`TEST_FLASH(32'h000, "Read word 0x000 with automatic page selection")
		`TEST_FLASH(32'h001, "Read word 0x001 with automatic page selection")
		`TEST_FLASH(32'h002, "Read word 0x002 with automatic page selection")
		`TEST_FLASH(32'h003, "Read word 0x003 with automatic page selection")
		`TEST_FLASH(32'h0F0, "Read word 0x0F0 with automatic page selection")
		`TEST_FLASH(32'h0F1, "Read word 0x0F1 with automatic page selection")
		`TEST_FLASH(32'h0F2, "Read word 0x0F2 with automatic page selection")
		`TEST_FLASH(32'h0F3, "Read word 0x0F3 with automatic page selection")

		`TEST_READ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h00000000, "Read current page address after automatic page selection page 0")

		// Read from another page
		`TEST_FLASH(32'h400, "Read word 0x400 with automatic page selection")
		`TEST_FLASH(32'h401, "Read word 0x401 with automatic page selection")
		`TEST_FLASH(32'h402, "Read word 0x402 with automatic page selection")
		`TEST_FLASH(32'h403, "Read word 0x403 with automatic page selection")
		`TEST_FLASH(32'h4F0, "Read word 0x4F0 with automatic page selection")
		`TEST_FLASH(32'h4F1, "Read word 0x4F1 with automatic page selection")
		`TEST_FLASH(32'h4F2, "Read word 0x4F2 with automatic page selection")
		`TEST_FLASH(32'h4F3, "Read word 0x4F3 with automatic page selection")

		`TEST_READ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h00001000, "Read current page address after automatic page selection page 1")

		// Random read between pages
		`TEST_FLASH(32'h000, "Read word 0x000 with automatic page selection switching pages")
		`TEST_FLASH(32'h401, "Read word 0x401 with automatic page selection switching pages")
		`TEST_FLASH(32'h002, "Read word 0x002 with automatic page selection switching pages")
		`TEST_FLASH(32'h403, "Read word 0x403 with automatic page selection switching pages")
		`TEST_FLASH(32'h4F0, "Read word 0x4F0 with automatic page selection switching pages")
		`TEST_FLASH(32'h0F1, "Read word 0x0F1 with automatic page selection switching pages")
		`TEST_FLASH(32'h0F2, "Read word 0x0F2 with automatic page selection switching pages")
		`TEST_FLASH(32'h4F3, "Read word 0x4F3 with automatic page selection switching pages")

		`TEST_READ(`FLASH_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h00001000, "Read current page address after automatic page selection switching pages")

		// Initialise core0

		// Run core0

		// Check that core0 is running

		// Initialise core1

		// Run core1

		// Check that core1 is running

		// Stop core1

		// Check that core1 has stopped at the correct instruction

		// Switch core0 to require a new page
		
		// Check that core0 is running

		// Run core1

		// Check that core1 is running

		// Stop core0

		// Check core0 has stopped at the correct instruction

		// Stop core1

		// Check core1 has stopped at the correct instruction

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
		.currentTestName(currentTestName));

	spiflash #(
		.FILENAME(`FLASH_FILE)
	) testflash (
		.csb(user_flash_csb),
		.clk(user_flash_clk),
		.io0(user_flash_io0),
		.io1(user_flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
