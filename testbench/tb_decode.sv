`timescale 1ns / 1ps

module tb_decode;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter REG_FILE_ADDRESS_WIDTH = 5;
    parameter CLK_PERIOD = 10; // 10ns clock period

    // Testbench signals
    logic                   clk;
    logic [DATA_WIDTH-1:0]  instrD;
    logic [DATA_WIDTH-1:0]  ResultW;
    logic [4:0]             RdW;
    logic                   RegWriteW;
    logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress;
	
    // Outputs
    logic [DATA_WIDTH-1:0] testRegData;
    logic                  RegWriteD;
    logic [1:0]            ResultSrcD;
    logic                  MemWriteD;
    logic                  JumpD;
    logic                  BranchD;
    logic [3:0]            ALUControlD;
    logic                  ALUSrcD;
    logic [DATA_WIDTH-1:0] RD1D;
    logic [DATA_WIDTH-1:0] RD2D;
    logic [4:0]            Rs1D;
    logic [4:0]            Rs2D;
    logic [4:0]            RdD;
    logic [DATA_WIDTH-1:0] ExtImmD;
    logic                  JALRInstrD;
    logic [2:0]            AddressingControlD;

    // Instantiate the DUT (Device Under Test)
    decode #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_FILE_ADDRESS_WIDTH(REG_FILE_ADDRESS_WIDTH)
    ) dut (
        .clk(clk),
        .instrD(instrD),
        .ResultW(ResultW),
        .RdW(RdW),
        .RegWriteW(RegWriteW),
        .testRegAddress(testRegAddress),
        .testRegData(testRegData),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ALUControlD(ALUControlD),
        .ALUSrcD(ALUSrcD),
        .RD1D(RD1D),
        .RD2D(RD2D),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdD(RdD),
        .ExtImmD(ExtImmD),
        .JALRInstrD(JALRInstrD),
        .AddressingControlD(AddressingControlD)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        instrD = 0;
        ResultW = 0;
        RdW = 0;
        RegWriteW = 0;
        testRegAddress = 0; // Keep for connection but don't test

        // Wait for a few clock cycles
        repeat(3) @(posedge clk);

        $display("=== Starting Decode Module Testbench ===");

        // Test 1: R-type instruction (ADD)
        // ADD x1, x2, x3 -> opcode: 0110011, funct3: 000, funct7: 0000000
        // rs1: x2 (00010), rs2: x3 (00011), rd: x1 (00001)
        test_instruction("R-type ADD", 32'b0000000_00011_00010_000_00001_0110011);

        // Test 2: I-type instruction (ADDI)
        // ADDI x1, x2, 100 -> opcode: 0010011, funct3: 000
        // rs1: x2 (00010), rd: x1 (00001), imm: 100 (000001100100)
        test_instruction("I-type ADDI", 32'b000001100100_00010_000_00001_0010011);

        // Test 3: Load instruction (LW)
        // LW x1, 8(x2) -> opcode: 0000011, funct3: 010
        // rs1: x2 (00010), rd: x1 (00001), imm: 8 (000000001000)
        test_instruction("Load LW", 32'b000000001000_00010_010_00001_0000011);

        // Test 4: Store instruction (SW)
        // SW x3, 12(x2) -> opcode: 0100011, funct3: 010
        // rs1: x2 (00010), rs2: x3 (00011), imm: 12
        test_instruction("Store SW", 32'b0000000_00011_00010_010_01100_0100011);

        // Test 5: Branch instruction (BEQ)
        // BEQ x1, x2, 16 -> opcode: 1100011, funct3: 000
        test_instruction("Branch BEQ", 32'b0000000_00010_00001_000_10000_1100011);

        // Test 6: Jump instruction (JAL)
        // JAL x1, 20 -> opcode: 1101111
        test_instruction("Jump JAL", 32'b00000000000100010100_00001_1101111);

        // Test 7: JALR instruction
        // JALR x1, x2, 4 -> opcode: 1100111, funct3: 000
        test_instruction("JALR", 32'b000000000100_00010_000_00001_1100111);

        // Test register file write-back (focus on control signals only)
        test_register_writeback();

        $display("=== Testbench Completed ===");
        $finish;
    end

    // Task to test different instruction types
    task test_instruction(string instr_name, logic [31:0] instruction);
        begin
            @(posedge clk);
            instrD = instruction;
            @(posedge clk);
            
            $display("\n--- Testing %s ---", instr_name);
            $display("Instruction: 0x%08h", instruction);
            $display("Rs1D: %d, Rs2D: %d, RdD: %d", Rs1D, Rs2D, RdD);
            $display("RegWriteD: %b, MemWriteD: %b, JumpD: %b, BranchD: %b", 
                     RegWriteD, MemWriteD, JumpD, BranchD);
            $display("ALUControlD: %b, ALUSrcD: %b, ResultSrcD: %b", 
                     ALUControlD, ALUSrcD, ResultSrcD);
            $display("ExtImmD: 0x%08h", ExtImmD);
            $display("JALRInstrD: %b, AddressingControlD: %b", 
                     JALRInstrD, AddressingControlD);
            $display("RD1D: 0x%08h, RD2D: 0x%08h", RD1D, RD2D);
            
            // Wait a bit before next test
            repeat(2) @(posedge clk);
        end
    endtask

    // Task to test register file write-back functionality (control signals only)
    task test_register_writeback();
        begin
            $display("\n--- Testing Register Write-back Control ---");
            
            // Write to register x5
            @(posedge clk);
            RdW = 5;
            ResultW = 32'hDEADBEEF;
            RegWriteW = 1;
            
            @(posedge clk);
            RegWriteW = 0;
            
            $display("Write-back test completed");
            $display("RdW: %d, ResultW: 0x%08h, RegWriteW: %b", RdW, ResultW, RegWriteW);
            
            repeat(2) @(posedge clk);
        end
    endtask

    // Monitor for debugging (excluding testRegData)
    initial begin
        $monitor("Time: %0t | clk: %b | instrD: 0x%08h | Rs1D: %d | Rs2D: %d | RdD: %d | RD1D: 0x%08h | RD2D: 0x%08h", 
                 $time, clk, instrD, Rs1D, Rs2D, RdD, RD1D, RD2D);
    end

    // Waveform dump (for simulation tools that support it)
    initial begin
        $dumpfile("decode_tb.vcd");
        $dumpvars(0, tb_decode);
    end

endmodule
