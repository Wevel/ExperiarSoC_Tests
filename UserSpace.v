`timescale 1 ns / 1 ps

`define TEST_NAME_LENGTH 128

`define GPIO0_OE_WRITE_ADDR 32'h33031000
`define GPIO0_OE_SET_ADDR 32'h33031004
`define GPIO0_OE_CLEAR_ADDR 32'h33031008
`define GPIO0_OE_TOGGLE_ADDR 32'h3303100C
`define GPIO0_OUTPUT_WRITE_ADDR 32'h33031010
`define GPIO0_OUTPUT_SET_ADDR 32'h33031014
`define GPIO0_OUTPUT_CLEAR_ADDR 32'h33031018
`define GPIO0_OUTPUT_TOGGLE_ADDR 32'h3303101C
`define GPIO0_INPUT_ADDR 32'h33031020
`define GPIO1_OE_WRITE_ADDR 32'h33032000
`define GPIO1_OE_SET_ADDR 32'h33032004
`define GPIO1_OE_CLEAR_ADDR 32'h33032008
`define GPIO1_OE_TOGGLE_ADDR 32'h3303200C
`define GPIO1_OUTPUT_WRITE_ADDR 32'h33032010
`define GPIO1_OUTPUT_SET_ADDR 32'h33032014
`define GPIO1_OUTPUT_CLEAR_ADDR 32'h33032018
`define GPIO1_OUTPUT_TOGGLE_ADDR 32'h3303201C
`define GPIO1_INPUT_ADDR 32'h33032020

`define CORE0_SRAM_ADDR 32'h30000000
`define CORE0_CONFIG_ADDR 32'h30800000
`define CORE0_REG_PC_ADDR 32'h30810000
`define CORE0_REG_JUMP_ADDR 32'h30810004
`define CORE0_REG_STEP_ADDR 32'h30810008
`define CORE0_REG_INSTR_ADDR 32'h30810010
`define CORE0_REG_IREG_ADDR 32'h30814000
`define CORE0_CSR_ADDR 32'h30818000

`define CORE1_SRAM_ADDR 32'h31000000
`define CORE1_CONFIG_ADDR 32'h31800000
`define CORE1_REG_PC_ADDR 32'h31810000
`define CORE1_REG_JUMP_ADDR 32'h31810004
`define CORE1_REG_STEP_ADDR 32'h31810008
`define CORE1_REG_INSTR_ADDR 32'h31810010
`define CORE1_REG_IREG_ADDR 32'h31814000
`define CORE1_CSR_ADDR 32'h31818000

`define CORE_RUN 32'h1
`define CORE_HALT 32'h0

`define SELECT_WORD 4'b1111
`define SELECT_HALF 4'b0011
`define SELECT_BYTE 4'b0001

`define OFFSET_WORD(BASE_ADDRESS, OFFSET) (BASE_ADDRESS) + {(OFFSET), 2'b00}

`define WB_WRITE_RAW(ADDRESS, BYTE_SELECT, DATA) \
	@(negedge clk) \ // Wait till before clock rising edge
	#1 \
	wait(!wbBusy); \ // Wait for bus to be free
	wbAddress <= ADDRESS; \ // Setup write
	wbByteSelect <= BYTE_SELECT; \
	wbWriteEnable <= 1'b1; \
	wbDataWrite <= DATA; \
	wbEnable <= 1'b1; \ // Start write
	@(posedge clk) \ // Wait for write to complete
	@(posedge clk) \
	@(posedge clk) \
	wait(!wbBusy);

`define WB_READ_RAW(ADDRESS, BYTE_SELECT, DATA) \
	@(negedge clk) \ // Wait till before clock rising edge
	#1 \
	wait(!wbBusy); \ // Wait for bus to be free
	wbAddress <= ADDRESS; \ // Setup read
	wbByteSelect <= BYTE_SELECT; \
	wbWriteEnable <= 1'b0; \
	wbEnable <= 1'b1; \ // Start read
	@(posedge clk) \ // Wait for read to complete
	@(posedge clk) \
	@(posedge clk) \
	wait(!wbBusy); \
	DATA <= wbDataRead; // Return data

`define WB_WRITE(ADDRESS, BYTE_SELECT, DATA) \
	`WB_WRITE_RAW(32'h30000000, `SELECT_WORD, (ADDRESS) & 32'hFFFF8000) \ // Set top part of address
	`WB_WRITE_RAW(((ADDRESS) & 32'h00007FFF) | 32'h30008000, BYTE_SELECT, DATA) // Perform write

`define WB_READ(ADDRESS, BYTE_SELECT, DATA) \
	`WB_WRITE_RAW(32'h30000000, `SELECT_WORD, (ADDRESS) & 32'hFFFF8000) \ // Set top part of address
	`WB_READ_RAW(((ADDRESS) & 32'h00007FFF) | 32'h30008000, BYTE_SELECT, DATA) // Perform read

`define TEST_RESULT(RESULT, TEST_NAME) \
	currentTestName = TEST_NAME; \
	@(negedge clk) \ // Wait till before clock rising edge
	#1 \
	if (succesOutput) succesOutput <= (RESULT);\
	nextTestOutput <= 1'b1;\
	@(posedge clk); \ // Wait for a clock cycle
	@(negedge clk); \
	nextTestOutput <= 1'b0;

`define TEST_WRITE(ADDRESS, BYTE_SELECT, DATA, WRITE_VALUE, RESULT_COMPARISON, TEST_NAME) \
	`WB_WRITE(ADDRESS, BYTE_SELECT, WRITE_VALUE) \
	`WB_READ(ADDRESS, BYTE_SELECT, DATA) \
	`TEST_RESULT(RESULT_COMPARISON, TEST_NAME)

`define TEST_WRITE_EQ(ADDRESS, BYTE_SELECT, DATA, WRITE_VALUE, TEST_NAME) `TEST_WRITE(ADDRESS, BYTE_SELECT, DATA, WRITE_VALUE, DATA == (WRITE_VALUE), TEST_NAME)

`define TEST_READ(ADDRESS, BYTE_SELECT, DATA, RESULT_COMPARISON, TEST_NAME) \
	`WB_READ(ADDRESS, BYTE_SELECT, DATA) \
	`TEST_RESULT(RESULT_COMPARISON, TEST_NAME)

`define TEST_READ_EQ(ADDRESS, BYTE_SELECT, DATA, EXPECTED_VALUE, TEST_NAME) `TEST_READ(ADDRESS, BYTE_SELECT, DATA, DATA == (EXPECTED_VALUE), TEST_NAME)

`define TEST_READ_TIMEOUT(ADDRESS, BYTE_SELECT, DATA, RESULT_COMPARISON, LOOP_DELAY, MAX_LOOPS, TEST_NAME) \
	begin \		
		counter <= 1; \
		`WB_READ(ADDRESS, BYTE_SELECT, DATA) \
		while (counter < MAX_LOOPS && !(RESULT_COMPARISON)) begin \
			#LOOP_DELAY; \
			`WB_READ(ADDRESS, BYTE_SELECT, DATA) \
			counter <= counter + 1; \
		end \
	end \
	`TEST_RESULT(RESULT_COMPARISON, TEST_NAME)

`define TIMEOUT(TIME) \
	repeat (TIME) begin \ // Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (1000) @(posedge clk); \
	end \
	$display("%c[1;35m",27); \
	`ifdef GL \
		$display ("Monitor: Timeout, Core PC Test (GL) Failed"); \
	`else \
		$display ("Monitor: Timeout, Core PC Test (RTL) Failed"); \
	`endif \
	$display("%c[0m",27);

`define TESTS_COMPLETED \
	#100 \
	if (succesOutput) begin \
		$display("%c[1;92m",27); \
		`ifdef GL \
			$display("Monitor: Core PC Test (GL) Passed"); \
		`else \
			$display("Monitor: Core PC Test (RTL) Passed"); \
		`endif \
		$display("%c[0m",27); \
	end else begin \
		$display("%c[1;31m",27); \
		`ifdef GL \
			$display ("Monitor: Core PC Test (GL) Failed"); \
		`else \
			$display ("Monitor: Core PC Test (RTL) Failed"); \
		`endif \
		$display("%c[0m",27); \
	end

module UserSpace(
		input wire clk,
		input wire rst,

		input wire [127:0] la_data_in_user,
		output wire [127:0] la_data_out_user,
		input wire [127:0] la_oenb_user,

		output wire [`MPRJ_IO_PADS-1:0] user_io_oeb,
		input wire [`MPRJ_IO_PADS-1:0] user_io_in,
		output wire [`MPRJ_IO_PADS-1:0] user_io_out,
		inout wire [`MPRJ_IO_PADS-10:0] mprj_analog_io,

		output wire[2:0] user_irq_core,

		input wire[31:0] wbAddress,
		input wire[3:0] wbByteSelect,
		input wire wbEnable,
		input wire wbWriteEnable,
		input wire[31:0] wbDataWrite,
		output wire[31:0] wbDataRead,
		output wire wbBusy,

		input wire succesOutput,
		input wire nextTestOutput,
		input wire[(`TEST_NAME_LENGTH*5)-1:0] currentTestName 
	);

	// Dispaly message with result of each test, ending the simulation if a test fails
	reg[31:0] testCounter = 0;
	always @(succesOutput, nextTestOutput) begin
		#1
		if (nextTestOutput) begin
			if (succesOutput) begin
				$display("%c[1;92mPassed test: %d %s%c[0m", 27, testCounter, currentTestName, 27);
			end	else begin
				$display("%c[1;31mFailed test: %d %s%c[0m", 27, testCounter, currentTestName, 27);
				#500
				$finish;
			end
			testCounter <= testCounter + 1;
		end
	end

	reg power1, power2;
	reg power3, power4;

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;	
		power4 <= 1'b1;
	end

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;
	
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	 // Exported Wishbone Bus (user area facing)
	wire 	mprj_cyc_o_user;
	wire 	mprj_stb_o_user;
	wire 	mprj_we_o_user;
	wire [3:0]  mprj_sel_o_user;
	wire [31:0] mprj_adr_o_user;
	wire [31:0] mprj_dat_o_user;
	wire [31:0] mprj_dat_i_user;
	wire	mprj_ack_i_user;
	
	Core_WBInterface #(.ADDRESS_WIDTH(32)) mprj_wb_interface (
		// Wishbone master interface
		.wb_clk_i(clk),
		.wb_rst_i(rst),
		.wb_cyc_o(mprj_cyc_o_user),
		.wb_stb_o(mprj_stb_o_user),
		.wb_we_o(mprj_we_o_user),
		.wb_sel_o(mprj_sel_o_user),
		.wb_data_o(mprj_dat_o_user),
		.wb_adr_o(mprj_adr_o_user),
		.wb_ack_i(mprj_ack_i_user),
		.wb_stall_i(1'b0),
		.wb_error_i(1'b0),
		.wb_data_i(mprj_dat_i_user),

		// Memory interface from core
		.wbAddress(wbAddress),
		.wbByteSelect(wbByteSelect),
		.wbEnable(wbEnable),
		.wbWriteEnable(wbWriteEnable),
		.wbDataWrite(wbDataWrite),
		.wbDataRead(wbDataRead),
		.wbBusy(wbBusy)
	);

	user_project_wrapper mprj ( 
		.vdda1(VDD3V3),		// User area 1 3.3V power
		.vdda2(VDD3V3),		// User area 2 3.3V power
		.vssa1(VSS),		// User area 1 analog ground
		.vssa2(VSS),		// User area 2 analog ground
		.vccd1(VDD1V8),		// User area 1 1.8V power
		.vccd2(VDD1V8),		// User area 2 1.8V power
		.vssd1(VSS),		// User area 1 digital ground
		.vssd2(VSS),		// User area 2 digital ground

		.wb_clk_i(clk),
		.wb_rst_i(rst),

		// Management SoC Wishbone bus (exported)
		.wbs_cyc_i(mprj_cyc_o_user),
		.wbs_stb_i(mprj_stb_o_user),
		.wbs_we_i(mprj_we_o_user),
		.wbs_sel_i(mprj_sel_o_user),
		.wbs_adr_i(mprj_adr_o_user),
		.wbs_dat_i(mprj_dat_o_user),
		.wbs_ack_o(mprj_ack_i_user),
		.wbs_dat_o(mprj_dat_i_user),

		// GPIO pad 3-pin interface (plus analog)
		.io_in (user_io_in),
		.io_out(user_io_out),
		.io_oeb(user_io_oeb),
		.analog_io(mprj_analog_io),

		// Logic analyzer
		.la_data_in(la_data_in_user),
		.la_data_out(la_data_out_user),
		.la_oenb(la_oenb_user),

		// Independent clock
		.user_clock2(clk),

		// IRQ
		.user_irq(user_irq_core)
	);

endmodule
