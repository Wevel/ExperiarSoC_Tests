`default_nettype none

`timescale 1 ns / 1 ps

`include "../RV32I.v"
`include "../UserSpace.v"

module userSpace_tb;
	reg clk;
	reg rst;

	reg [127:0] la_data_in_user = 128'b0;  // From CPU to MPRJ
	wire [127:0] la_data_out_user; // From MPRJ to CPU
	reg [127:0] la_oenb_user = ~128'b0;	 // From CPU to MPRJ

	wire [`MPRJ_IO_PADS-1:0] user_io_oeb;
	reg [`MPRJ_IO_PADS-1:0] user_io_in = 'b0;
	wire [`MPRJ_IO_PADS-1:0] user_io_out;
	wire [`MPRJ_IO_PADS-10:0] mprj_analog_io;

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
		$dumpfile("userSpace.vcd");
		$dumpvars(0, userSpace_tb);
		`TIMEOUT(100)
		$finish;
	end

	reg[6:0] tmp;
	reg[31:0] testValue = 32'b0;
	reg[31:0] initialInstructionCount = 32'b0;
	initial begin
		@(negedge rst);
		#100

		// Run tests
		// Setup test data in sram and make sure the test data has been written correctly
		// If it isn't probably run a specific memory test, rather than this one
		`TEST_WRITE(`CORE0_SRAM_ADDR, `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE0_SRAM_ADDR, 32'h40), `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE0_SRAM_ADDR, 32'h41), `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE0_SRAM_ADDR, 32'h42), `SELECT_WORD, testValue, `RV32I_JAL(`RV32I_X0, -32'h4))
		

		`TEST_WRITE(`CORE1_SRAM_ADDR, `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE1_SRAM_ADDR, 32'h40), `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE1_SRAM_ADDR, 32'h41), `SELECT_WORD, testValue, `RV32I_NOP)
		`TEST_WRITE(`OFFSET_WORD(`CORE1_SRAM_ADDR, 32'h42), `SELECT_WORD, testValue, `RV32I_JAL(`RV32I_X0, -32'h4))

		// Test core 0
		// Read that the config defaulted to 0
		`TEST_READ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)

		// Read that the program counter defaulted to 0x0000_0000
		`TEST_READ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h0)

		// Step PC
		`WB_WRITE(`CORE0_REG_STEP_ADDR, `SELECT_WORD, 32'h0)

		// Read that the PC stepped once
		`TEST_READ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h4)

		// Check that a NOP was read
		`TEST_READ(`CORE0_REG_INSTR_ADDR, `SELECT_WORD, testValue, `RV32I_NOP)

		// Jump PC
		`WB_WRITE(`CORE0_REG_JUMP_ADDR, `SELECT_WORD, 32'h100)

		// Read that the PC jumped correctly
		`TEST_READ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h104)

		// Let the core run
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_RUN)
		#200
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_HALT)

		// Make sure the core halted
		`TEST_READ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)

		// Check that the core has run
		`WB_READ(`OFFSET_WORD(`CORE0_CSR_ADDR, 30'hC02), `SELECT_WORD, initialInstructionCount)
		`TEST_RESULT(initialInstructionCount > 1 && initialInstructionCount != ~32'h0)

		// Let the core run
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_RUN)
		#200
		`WB_WRITE(`CORE0_CONFIG_ADDR, `SELECT_WORD, `CORE_HALT)

		// Make sure the core halted
		`TEST_READ(`CORE0_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)

		// Check that the core has been restarted
		`WB_READ(`OFFSET_WORD(`CORE0_CSR_ADDR, 30'hC02), `SELECT_WORD, testValue)
		`TEST_RESULT(testValue > initialInstructionCount)

		// Check that the PC has increased should be either 0x104 or 0x108
		`WB_READ(`CORE0_REG_PC_ADDR, `SELECT_WORD, testValue)
		`TEST_RESULT(testValue == 32'h104 || testValue == 32'h108)

		// Test core 1
		// Read that the config defaulted to 0
		`TEST_READ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)

		// Read that the program counter defaulted to 0x0000_0000
		`TEST_READ(`CORE1_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h0)

		// Step PC
		`WB_WRITE(`CORE1_REG_STEP_ADDR, `SELECT_WORD, 32'h0)

		// Read that the PC stepped once
		`TEST_READ(`CORE1_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h4)

		// Check that an NOP was read
		`TEST_READ(`CORE1_REG_INSTR_ADDR, `SELECT_WORD, testValue, `RV32I_NOP)

		// Jump PC
		`WB_WRITE(`CORE1_REG_JUMP_ADDR, `SELECT_WORD, 32'h100)

		// Read that the PC jumped correctly
		`TEST_READ(`CORE1_REG_PC_ADDR, `SELECT_WORD, testValue, 32'h104)

		// Let the core run
		`WB_WRITE(`CORE1_CONFIG_ADDR, `SELECT_WORD, `CORE_RUN)
		#200
		`WB_WRITE(`CORE1_CONFIG_ADDR, `SELECT_WORD, `CORE_HALT)

		// Make sure the core halted
		`TEST_READ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)

		// Check that the core is running
		`WB_READ(`OFFSET_WORD(`CORE1_CSR_ADDR, 30'hC02), `SELECT_WORD, initialInstructionCount)
		`TEST_RESULT(initialInstructionCount > 1 && initialInstructionCount != ~32'h0)

		// Let the core run
		`WB_WRITE(`CORE1_CONFIG_ADDR, `SELECT_WORD, `CORE_RUN)
		#200
		`WB_WRITE(`CORE1_CONFIG_ADDR, `SELECT_WORD, `CORE_HALT)

		// Make sure the core halted
		`TEST_READ(`CORE1_CONFIG_ADDR, `SELECT_WORD, testValue, `CORE_HALT)


		// Check that the core has been restarted
		`WB_READ(`OFFSET_WORD(`CORE1_CSR_ADDR, 30'hC02), `SELECT_WORD, testValue)
		`TEST_RESULT(testValue > initialInstructionCount)
		
		// Check that the PC has increased should be either 0x104 or 0x108
		`WB_READ(`CORE1_REG_PC_ADDR, `SELECT_WORD, testValue)
		`TEST_RESULT(testValue == 32'h104 || testValue == 32'h108)

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

endmodule
