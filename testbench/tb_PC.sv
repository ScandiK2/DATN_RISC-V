`timescale 1ns / 1ps

module tb_PC;
    // Parameters
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 100MHz clock
    
    // Testbench signals
    logic clk;
    logic reset;
    logic enable;
    logic [DATA_WIDTH-1:0] PCTargetE;
    logic PCSrcE;
    logic JALRinstr;
    logic [DATA_WIDTH-1:0] ALUResultE;
    logic [DATA_WIDTH-1:0] PCPlus4F;
    logic [DATA_WIDTH-1:0] PCF;
    
    // Instantiate the DUT (Device Under Test)
    PC #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .PCTargetE(PCTargetE),
        .PCSrcE(PCSrcE),
        .JALRinstr(JALRinstr),
        .ALUResultE(ALUResultE),
        .PCPlus4F(PCPlus4F),
        .PCF(PCF)
    );
    
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // ✅ Khai báo TẤT CẢ biến local ở đầu khối initial
        logic [DATA_WIDTH-1:0] prev_pc;
        logic [DATA_WIDTH-1:0] expected_pc;
        
        // Initialize signals
        reset = 1'b1;
        enable = 1'b0;
        PCTargetE = 32'h0;
        PCSrcE = 1'b0;
        JALRinstr = 1'b0;
        ALUResultE = 32'h0;
        
        // Wait for a few clock cycles
        repeat(3) @(posedge clk);
        
        // Test 1: Reset functionality
        $display("=== Test 1: Reset Functionality ===");
        reset = 1'b0;
        @(posedge clk);
        $display("After reset release: PCF = 0x%h (Expected: 0xbfc00000)", PCF);
        assert(PCF == 32'hbfc00000) else $error("Reset test failed!");
        
        // Test 2: Enable functionality - PC increment (normal operation)
        $display("\n=== Test 2: Normal PC Increment ===");
        enable = 1'b1;
        PCSrcE = 1'b0;
        JALRinstr = 1'b0;
        @(posedge clk);
        $display("PC increment: PCF = 0x%h, PCPlus4F = 0x%h", PCF, PCPlus4F);
        assert(PCF == 32'hbfc00004) else $error("PC increment test failed!");
        assert(PCPlus4F == PCF + 4) else $error("PCPlus4F calculation failed!");
        
        // Test 3: Branch target (PCSrcE = 1, JALRinstr = 0)
        $display("\n=== Test 3: Branch Target ===");
        PCTargetE = 32'hbfc00100;
        PCSrcE = 1'b1;
        JALRinstr = 1'b0;
        @(posedge clk);
        $display("Branch target: PCF = 0x%h (Expected: 0x%h)", PCF, PCTargetE);
        assert(PCF == PCTargetE) else $error("Branch target test failed!");
        
        // Test 4: JALR instruction with PCSrcE = 0
        $display("\n=== Test 4: JALR with PCSrcE = 0 ===");
        ALUResultE = 32'hbfc00203; // Unaligned address
        PCSrcE = 1'b0;
        JALRinstr = 1'b1;
        @(posedge clk);
        $display("JALR (PCSrcE=0): PCF = 0x%h (Expected: 0x%h)", PCF, {ALUResultE[31:2], 2'b00});
        assert(PCF == {ALUResultE[31:2], 2'b00}) else $error("JALR with PCSrcE=0 test failed!");
        
        // Test 5: JALR instruction with PCSrcE = 1
        $display("\n=== Test 5: JALR with PCSrcE = 1 ===");
        ALUResultE = 32'hbfc00307; // Unaligned address
        PCSrcE = 1'b1;
        JALRinstr = 1'b1;
        @(posedge clk);
        $display("JALR (PCSrcE=1): PCF = 0x%h (Expected: 0x%h)", PCF, {ALUResultE[31:2], 2'b00});
        assert(PCF == {ALUResultE[31:2], 2'b00}) else $error("JALR with PCSrcE=1 test failed!");
        
        // Test 6: Enable = 0 (PC should not change)
        $display("\n=== Test 6: Enable = 0 (PC Hold) ===");
        prev_pc = PCF;  // ✅ Chỉ gán giá trị, không khai báo
        enable = 1'b0;
        PCTargetE = 32'hbfc00500;
        PCSrcE = 1'b1;
        @(posedge clk);
        $display("PC hold: PCF = 0x%h (Should remain: 0x%h)", PCF, prev_pc);
        assert(PCF == prev_pc) else $error("PC hold test failed!");
        
        // Test 7: Reset during operation
        $display("\n=== Test 7: Reset During Operation ===");
        enable = 1'b1;
        reset = 1'b1;
        @(posedge clk);
        reset = 1'b0;
        $display("Reset during operation: PCF = 0x%h (Expected: 0xbfc00000)", PCF);
        assert(PCF == 32'hbfc00000) else $error("Reset during operation test failed!");
        
        // Test 8: Sequential PC increments
        $display("\n=== Test 8: Sequential PC Increments ===");
        enable = 1'b1;
        PCSrcE = 1'b0;
        JALRinstr = 1'b0;
        repeat(5) begin
            expected_pc = PCF + 4;  // ✅ Chỉ gán giá trị, không khai báo
            @(posedge clk);
            $display("Sequential increment: PCF = 0x%h", PCF);
            assert(PCF == expected_pc) else $error("Sequential increment failed!");
        end
        
        // Test 9: Edge case - Maximum address
        $display("\n=== Test 9: Edge Case - Maximum Address ===");
        PCTargetE = 32'hfffffffc;
        PCSrcE = 1'b1;
        JALRinstr = 1'b0;
        @(posedge clk);
        $display("Max address: PCF = 0x%h", PCF);
        @(posedge clk); // Next increment should wrap
        $display("After max address increment: PCF = 0x%h", PCF);
        
        // Test 10: JALR alignment test
        $display("\n=== Test 10: JALR Alignment Test ===");
        ALUResultE = 32'hbfc00001; // LSB = 01
        JALRinstr = 1'b1;
        PCSrcE = 1'b0;
        @(posedge clk);
        $display("JALR alignment (LSB=01): PCF = 0x%h (Expected: 0xbfc00000)", PCF);
        assert(PCF[1:0] == 2'b00) else $error("JALR alignment test failed!");
        
        ALUResultE = 32'hbfc00002; // LSB = 10
        @(posedge clk);
        $display("JALR alignment (LSB=10): PCF = 0x%h (Expected: 0xbfc00000)", PCF);
        assert(PCF[1:0] == 2'b00) else $error("JALR alignment test failed!");
        
        ALUResultE = 32'hbfc00003; // LSB = 11
        @(posedge clk);
        $display("JALR alignment (LSB=11): PCF = 0x%h (Expected: 0xbfc00000)", PCF);
        assert(PCF[1:0] == 2'b00) else $error("JALR alignment test failed!");
        
        $display("\n=== All Tests Completed Successfully! ===");
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        $monitor("Time: %0t | clk: %b | reset: %b | enable: %b | PCSrcE: %b | JALRinstr: %b | PCF: 0x%h | PCPlus4F: 0x%h", 
                 $time, clk, reset, enable, PCSrcE, JALRinstr, PCF, PCPlus4F);
    end
    
    // Waveform dump
    initial begin
        $dumpfile("tb_PC.vcd");
        $dumpvars(0, tb_PC);
    end
    
endmodule
