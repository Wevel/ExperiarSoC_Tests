`default_nettype none

`timescale 1 ns / 1 ps

`define FLASH_FILE "userSpaceFlash.hex"

`define SPI_MEMORY0_ADDRESS_CORE 32'h1400_0000
`define SPI_MEMORY0_ADDRESS 32'h3400_0000
`define SPI_MEMORY0_CONFIG 32'h3480_0000
`define SPI_MEMORY0_STATUS 32'h3480_0004
`define SPI_MEMORY0_CURRENT_PAGE_ADDRESS 32'h3480_0008
`define SPI_MEMORY0_CACHE_STATUS 32'h3480_000C

`define SPI_MEMORY1_ADDRESS_CORE 32'h1500_0000
`define SPI_MEMORY1_ADDRESS 32'h3500_0000
`define SPI_MEMORY1_CONFIG 32'h3580_0000
`define SPI_MEMORY1_STATUS 32'h3580_0004
`define SPI_MEMORY1_CURRENT_PAGE_ADDRESS 32'h3580_0008
`define SPI_MEMORY1_CACHE_STATUS 32'h3580_000C

`define SPI_MEMORY_PAGE_SIZE_WORDS 32'd512
`define SPI_MEMORY_PAGE_SIZE_BYTES `SPI_MEMORY_PAGE_SIZE_WORDS * 4
`define SPI_MEMORY_CONFIG_DISABLE 		  32'b000
`define SPI_MEMORY_CONFIG_ENABLE 		  32'b001
`define SPI_MEMORY_CONFIG_AUTOMATIC_MODE  32'b010
`define SPI_MEMORY_CONFIG_WRITE_ENABLE 	  32'b100
`define SPI_MEMORY_STATUS_NOT_INITIALISED 32'b000
`define SPI_MEMORY_STATUS_INITIALISED 	  32'b001
`define SPI_MEMORY_STATUS_LOADING 		  32'b010
`define SPI_MEMORY_STATUS_SAVING	 	  32'b100

`define VAR_CURRENT_CHAR_ADDRESS 32'h0000_0000
`define VAR_PRIMARY_TOTAL_ADDRESS 32'h0000_0004
`define VAR_SECONDARY_TOTAL_ADDRESS 32'h0000_0008
`define VAR_STATE_ADDRESS 32'h0000_000C

`define SPI_MEMORY_WORD(ADDRESS) { flashMemory[{ADDRESS, 2'b00} + 3], flashMemory[{ADDRESS, 2'b00} + 2], flashMemory[{ADDRESS, 2'b00} + 1], flashMemory[{ADDRESS, 2'b00}] }

`define TEST_FLASH(ADDRESS, TEST_NAME) `TEST_READ(`OFFSET_WORD(`SPI_MEMORY0_ADDRESS, ADDRESS), `SELECT_WORD, testValue, testValue == (`SPI_MEMORY_WORD((ADDRESS) & 32'h000_ffff)), TEST_NAME)
`define TEST_MANUAL_FLASH(PAGE, ADDRESS, TEST_NAME) `TEST_READ(`OFFSET_WORD(`SPI_MEMORY0_ADDRESS, ADDRESS), `SELECT_WORD, testValue, testValue == (`SPI_MEMORY_WORD(((PAGE * `SPI_MEMORY_PAGE_SIZE_WORDS) + ADDRESS) & 32'h000_ffff)), TEST_NAME)

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
	wire[31:0] testNumber;

	wire [2:0]   user_irq_core;

	initial begin
		$dumpfile("userSpaceFlash.vcd");
		$dumpvars(0, userSpaceFlash_tb);
		`TIMEOUT(250)
		$finish;
	end

	reg [7:0] flashMemory [0:8*1024*1024-1];

	initial begin
		$readmemh(`FLASH_FILE, flashMemory);
	end

	integer counter = 0;
	reg[31:0] testValue = 32'b0;
	reg[31:0] testCompareValue = 32'b0;
	initial begin
		@(negedge rst);
		#100

		// Read the initial flash status
		`TEST_READ_EQ(`SPI_MEMORY0_CONFIG, `SELECT_WORD, testValue, `SPI_MEMORY_CONFIG_DISABLE, "Read initial flash config")
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_NOT_INITIALISED, "Read initial flash status")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0000_0000, "Read initial flash cache status")

		// Setup the flash for manual page selection
		`TEST_WRITE_EQ(`SPI_MEMORY0_CONFIG, `SELECT_WORD, testValue, `SPI_MEMORY_CONFIG_ENABLE, "Set flash config to manual page selection")
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_NOT_INITIALISED, "Read flash status after manual page selection")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0000_0000, "Read flash cache status after manual page selection")

		// Wait for initialisation to complete
		`TEST_READ_TIMEOUT(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, testValue == `SPI_MEMORY_STATUS_INITIALISED, 100, 10, "Read flash status to check for initialisation complete")

		// Write the page address
		`TEST_WRITE_EQ(`SPI_MEMORY0_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h0, "Write page address to 0")

		// Check that page loading has started
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status to check for page 1 loading started")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'hFFFF_FFFF, "Read flash cache status to check for page 1 loading started")


		// Read data from the page to test that it is loaded correctly
		`TEST_MANUAL_FLASH(32'h0, 32'h00, "Read word 0x00 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h01, "Read word 0x01 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h02, "Read word 0x02 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h03, "Read word 0x03 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h40, "Read word 0x40 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h41, "Read word 0x41 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h42, "Read word 0x42 from page 0")
		`TEST_MANUAL_FLASH(32'h0, 32'h43, "Read word 0x43 from page 0")

		`TEST_MANUAL_FLASH(32'h0, 32'h00, "Read word 0x00 from page 0 after reading other words")
		`TEST_MANUAL_FLASH(32'h0, 32'h01, "Read word 0x01 from page 0 after reading other words")
		`TEST_MANUAL_FLASH(32'h0, 32'h02, "Read word 0x02 from page 0 after reading other words")
		`TEST_MANUAL_FLASH(32'h0, 32'h03, "Read word 0x03 from page 0 after reading other words")

		// Make sure to wait for the final byte to load
		// As each sub page loads independently, we have to read the final word for each page to ensure that the entire page has finished loading
		`TEST_MANUAL_FLASH(32'h0, 32'h01F, "Read word 0x01F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h03F, "Read word 0x03F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h05F, "Read word 0x05F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h07F, "Read word 0x07F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h09F, "Read word 0x09F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h0BF, "Read word 0x0BF from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h0DF, "Read word 0x0DF from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h0FF, "Read word 0x0FF from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h11F, "Read word 0x11F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h13F, "Read word 0x13F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h15F, "Read word 0x15F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h17F, "Read word 0x17F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h19F, "Read word 0x19F from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h1BF, "Read word 0x1BF from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h1DF, "Read word 0x1DF from page 0 to fully load page")
		`TEST_MANUAL_FLASH(32'h0, 32'h1FF, "Read word 0x1FF from page 0 to fully load page")

		`TEST_READ_EQ(`OFFSET_WORD(`SPI_MEMORY0_ADDRESS, 32'h200), `SELECT_WORD, testValue, ~32'b0, "Read invalid word 0x200 from page 0")

		// Check that page loading is complete
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_INITIALISED, "Read flash status to check for page loading complete")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0000_FFFF, "Read flash cache status to check for page loading complete")

		// Change to a new page
		`TEST_WRITE(`SPI_MEMORY0_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h2, testValue == (32'h2 * `SPI_MEMORY_PAGE_SIZE_BYTES), "Write page address to 2")

		// Check that page loading has started
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status to check for page 2 loading started")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'hFFFF_FFFF, "Read flash cache status to check for page 2 loading started")

		// Read data from the page to test that it is loaded correctly
		`TEST_MANUAL_FLASH(32'h2, 32'h00, "Read word 0x00 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h01, "Read word 0x01 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h02, "Read word 0x02 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h03, "Read word 0x03 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h40, "Read word 0x40 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h41, "Read word 0x41 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h42, "Read word 0x42 from page 2")
		`TEST_MANUAL_FLASH(32'h2, 32'h43, "Read word 0x43 from page 2")

		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status before automatic page selection")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'hFFFE_FFFF, "Read flash cache status before automatic page selection")

		// Setup the flash for automatic page selection
		`TEST_WRITE_EQ(`SPI_MEMORY0_CONFIG, `SELECT_WORD, testValue, `SPI_MEMORY_CONFIG_AUTOMATIC_MODE | `SPI_MEMORY_CONFIG_ENABLE, "Set flash config to automatic page selection")
		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_INITIALISED, "Read flash status after automatic page selection")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0000_0000, "Read flash cache status after automatic page selection")
		
		// Read current page address
		`TEST_READ_EQ(`SPI_MEMORY0_CURRENT_PAGE_ADDRESS, `SELECT_WORD, testValue, 32'h00FF_FFFF, "Read current page address after automatic page selection setup")

		// Read from the first page
		`TEST_FLASH(32'h000, "Read word 0x000 with automatic page selection")
		`TEST_FLASH(32'h001, "Read word 0x001 with automatic page selection")
		`TEST_FLASH(32'h002, "Read word 0x002 with automatic page selection")
		`TEST_FLASH(32'h003, "Read word 0x003 with automatic page selection")

		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status after first automatic page use")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0100_0100, "Read flash cache status after first automatic page use")

		`TEST_FLASH(32'h01C, "Read word 0x01C with automatic page selection")
		`TEST_FLASH(32'h01D, "Read word 0x01D with automatic page selection")
		`TEST_FLASH(32'h01E, "Read word 0x01E with automatic page selection")
		`TEST_FLASH(32'h01F, "Read word 0x01F with automatic page selection")

		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_INITIALISED, "Read flash status after first automatic page use to end of page")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0000_0100, "Read flash cache status after first automatic page use to end of page")

		// Read from another page
		`TEST_FLASH(32'h400, "Read word 0x400 with automatic page selection")
		`TEST_FLASH(32'h401, "Read word 0x401 with automatic page selection")
		`TEST_FLASH(32'h402, "Read word 0x402 with automatic page selection")
		`TEST_FLASH(32'h403, "Read word 0x403 with automatic page selection")
		`TEST_FLASH(32'h440, "Read word 0x440 with automatic page selection")
		`TEST_FLASH(32'h441, "Read word 0x441 with automatic page selection")
		`TEST_FLASH(32'h442, "Read word 0x442 with automatic page selection")
		`TEST_FLASH(32'h443, "Read word 0x443 with automatic page selection")

		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status after second automatic page use")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h1000_1110, "Read flash cache status after second automatic page use")

		// Random read between pages
		`TEST_FLASH(32'h000, "Read word 0x000 with automatic page selection switching pages")
		`TEST_FLASH(32'h401, "Read word 0x401 with automatic page selection switching pages")
		`TEST_FLASH(32'h002, "Read word 0x002 with automatic page selection switching pages")
		`TEST_FLASH(32'h403, "Read word 0x403 with automatic page selection switching pages")
		`TEST_FLASH(32'h4F0, "Read word 0x4F0 with automatic page selection switching pages")
		`TEST_FLASH(32'h0F1, "Read word 0x0F1 with automatic page selection switching pages")
		`TEST_FLASH(32'h0F2, "Read word 0x0F2 with automatic page selection switching pages")
		`TEST_FLASH(32'h4F3, "Read word 0x4F3 with automatic page selection switching pages")

		`TEST_READ_EQ(`SPI_MEMORY0_STATUS, `SELECT_WORD, testValue, `SPI_MEMORY_STATUS_LOADING | `SPI_MEMORY_STATUS_INITIALISED, "Read flash status after alternating automatic page use")
		`TEST_READ_EQ(`SPI_MEMORY0_CACHE_STATUS, `SELECT_WORD, testValue, 32'h0002_5112, "Read flash cache status after alternating automatic page use")

		// Initialise core0
		`TEST_READ_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Read core0 config before initialisation")
		`TEST_WRITE_EQ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue, `SPI_MEMORY0_ADDRESS_CORE, "Write core0 PC start of flash address")
		`TEST_WRITE_EQ(`CORE0_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Clear core0 calculation value for primary loop")
		`TEST_WRITE_EQ(`CORE0_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Clear core0 calculation value for secondary loop")
		`TEST_WRITE_EQ(`CORE0_SRAM_ADDR + `VAR_STATE_ADDRESS, `SELECT_WORD, testValue, 32'h0, "Clear core0 state")

		// Initialise core1
		`TEST_READ_EQ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Read core1 config before initialisation")
		`TEST_WRITE_EQ(`CORE1_REG_PC_ADDR, `SELECT_WORD, testValue, `SPI_MEMORY0_ADDRESS_CORE, "Write core1 PC start of flash address")
		`TEST_WRITE_EQ(`CORE1_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Clear core1 calculation value for primary loop")
		`TEST_WRITE_EQ(`CORE1_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Clear core1 calculation value for secondary loop")
		`TEST_WRITE_EQ(`CORE1_SRAM_ADDR + `VAR_STATE_ADDRESS, `SELECT_WORD, testValue, 32'h0, "Clear core1 state")

		// Run core0
		`TEST_WRITE_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_RUN, "Write core0 config to run")
		
		// Test that core0 is running from only the first page
		`TEST_READ_TIMEOUT(`CORE0_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testCompareValue, testCompareValue >= 32'd45, 10000, 100, "Read core0 calculation value from primary loop")
		`TEST_READ_EQ(`CORE0_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Read core0 calculation value from secondary loop")

		// Switch core0 to run from the second page
		`TEST_WRITE_EQ(`CORE0_SRAM_ADDR + `VAR_STATE_ADDRESS, `SELECT_WORD, testValue, 32'h1, "Write core0 to switch to second state")
		#1000

		// Test that core0 is running from only the second page
		`TEST_READ(`CORE0_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, testCompareValue == testValue, "Check core0 calculation value from primary loop hasn't changed")
		`TEST_READ_TIMEOUT(`CORE0_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, testValue >= 32'd285, 100000, 100, "Read core0 calculation value from secondary loop")

		// Switch core0 back to the first page
		`TEST_WRITE_EQ(`CORE0_SRAM_ADDR + `VAR_STATE_ADDRESS, `SELECT_WORD, testValue, 32'h1, "Write core0 to switch to first state")
		#1000

		// Test that core0 is running from only the first page
		`TEST_READ_TIMEOUT(`CORE0_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, testValue > testCompareValue, 10000, 200, "Check core0 calculation value from primary loop has increased")

		// Run core1
		`TEST_WRITE_EQ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_RUN, "Write core1 config to run")
		#1000

		// Test that core1 is running from only the first page
		`TEST_READ_TIMEOUT(`CORE1_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testCompareValue, testCompareValue >= 32'd45, 10000, 100, "Read core1 calculation value from primary loop")
		`TEST_READ_EQ(`CORE1_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, 32'b0, "Read core1 calculation value from secondary loop")

		// Switch core1 to run from the second page
		`TEST_WRITE_EQ(`CORE1_SRAM_ADDR + `VAR_STATE_ADDRESS, `SELECT_WORD, testValue, 32'h1, "Write core1 to switch to second state")
		#1000

		// Test that core1 is running from only the second page
		`TEST_READ(`CORE1_SRAM_ADDR + `VAR_PRIMARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, testCompareValue == testValue, "Check core1 calculation value from primary loop hasn't changed")
		`TEST_READ_TIMEOUT(`CORE1_SRAM_ADDR + `VAR_SECONDARY_TOTAL_ADDRESS, `SELECT_WORD, testValue, testValue >= 32'd285, 100000, 100, "Read core1 calculation value from secondary loop")

		// Stop core0
		`TEST_WRITE_EQ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Write core0 config to halt")

		// Check core0 has stopped at the correct instruction

		// Stop core1
		`TEST_WRITE_EQ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT, "Write core1 config to halt")

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
		.io3()			// not used
	);

endmodule
