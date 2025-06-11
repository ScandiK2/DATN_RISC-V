`timescale 1ns / 1ps

module tb_pipelined_cpu;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter REG_FILE_ADDRESS_WIDTH = 5;
    parameter CLK_PERIOD = 10;

    // Testbench signals
    logic clk;
    logic rst;
    logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress;
    logic [DATA_WIDTH-1:0] testRegData;
    logic [DATA_WIDTH-1:0] ResultW;

    // Debug signals for waveform
    logic [31:0] PCF_debug;
    logic [31:0] PCD_debug;
    logic [31:0] instrF_debug;
    logic [31:0] instrD_debug;
    logic [31:0] RD1D_debug;
    logic [31:0] RD2D_debug;
    logic [3:0] ALUControlD_debug;
    logic [3:0] ALUControlE_debug;
    logic [2:0] AddressingControlD_debug;
    logic [31:0] ALUResultE_debug;

    // DUT instantiation
    pipelined_cpu #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_FILE_ADDRESS_WIDTH(REG_FILE_ADDRESS_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .testRegAddress(testRegAddress),
        .testRegData(testRegData),
        .ResultW(ResultW)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Assign debug signals safely
    always_comb begin
        PCF_debug = dut.PCF;
        PCD_debug = dut.PCD;
        instrF_debug = dut.instrF;
        instrD_debug = dut.instrD;
        RD1D_debug = dut.RD1D;
        RD2D_debug = dut.RD2D;
        ALUControlD_debug = dut.ALUControlD;
        ALUControlE_debug = dut.ALUControlE;
        AddressingControlD_debug = dut.AddressingControlD;
        ALUResultE_debug = dut.ALUResultE;
    end

    // Waveform dump
    initial begin
        $dumpfile("pipelined_cpu_debug.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        
        // Dump specific signals for better visibility
        $dumpvars(1, dut.PCF);
        $dumpvars(1, dut.instrF);
        $dumpvars(1, dut.PCD);
        $dumpvars(1, dut.instrD);
        $dumpvars(1, dut.RD1D);
        $dumpvars(1, dut.RD2D);
        $dumpvars(1, dut.ALUControlD);
        $dumpvars(1, dut.ALUControlE);
        $dumpvars(1, dut.ALUResultE);
        $dumpvars(1, dut.ResultW);
    end

    // Safe hierarchy checking - không truy cập deep hierarchy
    initial begin
        #1;
        $display("=== SAFE HIERARCHY CHECK ===");
        $display("Top-level signals accessible:");
        $display("  PCF exists: %b", !$isunknown(dut.PCF));
        $display("  instrF exists: %b", !$isunknown(dut.instrF));
        $display("  instrD exists: %b", !$isunknown(dut.instrD));
        $display("  RD1D exists: %b", !$isunknown(dut.RD1D));
        $display("  RD2D exists: %b", !$isunknown(dut.RD2D));
        $display("=================================");
    end

    // Detailed monitoring với tín hiệu an toàn
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n=== CYCLE %0d at time %0t ===", ($time - 30)/CLK_PERIOD, $time);
            
            // Fetch Stage
            $display("FETCH STAGE:");
            $display("  PCF = 0x%08X", dut.PCF);
            $display("  instrF = 0x%08X %s", dut.instrF, 
                     (dut.instrF === 32'hxxxxxxxx) ? "(UNDEFINED)" : 
                     (dut.instrF === 32'h00000000) ? "(NOP/ZERO)" : "(VALID)");
            
            // Decode Stage
            $display("DECODE STAGE:");
            $display("  PCD = 0x%08X", dut.PCD);
            $display("  instrD = 0x%08X %s", dut.instrD,
                     (dut.instrD === 32'hxxxxxxxx) ? "(UNDEFINED)" : 
                     (dut.instrD === 32'h00000000) ? "(NOP/ZERO)" : "(VALID)");
            $display("  RD1D = 0x%08X %s", dut.RD1D,
                     (dut.RD1D === 32'hxxxxxxxx) ? "(UNDEFINED)" : "(VALID)");
            $display("  RD2D = 0x%08X %s", dut.RD2D,
                     (dut.RD2D === 32'hxxxxxxxx) ? "(UNDEFINED)" : "(VALID)");
            $display("  ALUControlD = %04b %s", dut.ALUControlD,
                     (dut.ALUControlD === 4'bxxxx) ? "(UNDEFINED)" : 
                     (dut.ALUControlD === 4'b0000) ? "(ADD/NOP)" : "(OTHER OP)");
            $display("  AddressingControlD = %03b", dut.AddressingControlD);
            
            // Execute Stage
            $display("EXECUTE STAGE:");
            $display("  ALUControlE = %04b", dut.ALUControlE);
            $display("  ALUResultE = 0x%08X", dut.ALUResultE);
            $display("  PCSrcE = %b", dut.PCSrcE);
            if (dut.PCSrcE) begin
                $display("  *** BRANCH TAKEN: PCTarget = 0x%08X ***", dut.PCTargetE);
            end
            
            // Memory Stage
            $display("MEMORY STAGE:");
            $display("  ALUResultM = 0x%08X", dut.ALUResultM);
            $display("  MemWriteM = %b", dut.MemWriteM);
            if (dut.MemWriteM) begin
                $display("  *** MEMORY WRITE: Data = 0x%08X ***", dut.WriteDataM);
            end
            
            // Writeback Stage
            $display("WRITEBACK:");
            $display("  ResultW = 0x%08X %s", ResultW,
                     (ResultW === 32'hxxxxxxxx) ? "(UNDEFINED)" : "(VALID)");
            $display("  RegWriteW = %b", dut.RegWriteW);
            $display("  RdW = %0d", dut.RdW);
            
            // Hazard Detection
            if (dut.StallFetch || dut.StallDecode || dut.FlushExecute || dut.FlushDecode) begin
                $display("HAZARD DETECTED:");
                $display("  StallF=%b, StallD=%b, FlushE=%b, FlushD=%b",
                         dut.StallFetch, dut.StallDecode, dut.FlushExecute, dut.FlushDecode);
            end
            
            // Forwarding
            if (dut.ForwardAE != 2'b00 || dut.ForwardBE != 2'b00) begin
                $display("FORWARDING:");
                $display("  ForwardAE=%02b, ForwardBE=%02b", dut.ForwardAE, dut.ForwardBE);
            end
            
            $display("================================================");
        end
    end

    // Register monitoring task
    task check_register(input [4:0] reg_addr, input string reg_name);
        begin
            testRegAddress = reg_addr;
            #1;
            $display("[%0t] %s (x%0d) = 0x%08X", $time, reg_name, reg_addr, testRegData);
        end
    endtask

    // Branch/Jump detection
    always @(posedge clk) begin
        if (!rst && dut.PCSrcE) begin
            $display("[%0t] *** CONTROL TRANSFER: PC = 0x%08X -> 0x%08X ***", 
                     $time, dut.PCE, dut.PCTargetE);
        end
    end

    // Memory operation detection
    always @(posedge clk) begin
        if (!rst) begin
            if (dut.MemWriteM) begin
                $display("[%0t] *** STORE: Addr=0x%08X, Data=0x%08X, Mode=%03b ***",
                         $time, dut.ALUResultM, dut.WriteDataM, dut.AddressingControlM);
            end
            if (dut.ResultSrcM[0]) begin
                $display("[%0t] *** LOAD: Addr=0x%08X, Data=0x%08X, Mode=%03b ***",
                         $time, dut.ALUResultM, dut.ReadDataM, dut.AddressingControlM);
            end
        end
    end

    // Main test sequence
    initial begin
        $display("=== PIPELINED CPU TESTBENCH STARTED ===");
        $display("Testing 5-stage pipeline: Fetch -> Decode -> Execute -> Memory -> Writeback");
        
        // Initialize
        rst = 1;
        testRegAddress = 0;
        
        // Reset sequence
        $display("[%0t] Applying reset for 3 cycles...", $time);
        repeat(3) @(posedge clk);
        
        rst = 0;
        $display("[%0t] Reset released, CPU starting...", $time);
        
        // Let pipeline fill
        repeat(15) @(posedge clk);
        
        // Diagnostic checks
        if (dut.instrF === 32'hxxxxxxxx || dut.instrF === 32'h00000000) begin
            $display("\n*** WARNING: No valid instructions detected! ***");
            $display("Check instruction memory initialization");
        end
        
        if (dut.ALUControlD === 4'b0000 && dut.ALUControlE === 4'b0000) begin
            $display("\n*** WARNING: ALU Control signals are zero! ***");
            $display("Possible causes:");
            $display("  1. Only NOP instructions in memory");
            $display("  2. Control unit not generating signals");
            $display("  3. Instruction decode problems");
        end
        
        // Continue execution
        repeat(25) @(posedge clk);
        
        // Register file check
        $display("\n=== REGISTER FILE CHECK ===");
        check_register(0, "zero");
        check_register(1, "ra");
        check_register(2, "sp");
        check_register(3, "gp");
        check_register(4, "tp");
        check_register(5, "t0");
        check_register(6, "t1");
        check_register(7, "t2");
        
        // Final diagnosis
        $display("\n=== FINAL DIAGNOSIS ===");
        $display("After %0d cycles:", ($time - 30)/CLK_PERIOD);
        $display("  - Valid instructions: %s", 
                 (dut.instrF !== 32'hxxxxxxxx && dut.instrF !== 32'h00000000) ? "YES" : "NO");
        $display("  - Register operations: %s",
                 (dut.RD1D !== 32'hxxxxxxxx || dut.RD2D !== 32'hxxxxxxxx) ? "YES" : "NO");
        $display("  - ALU operations: %s",
                 (dut.ALUControlD !== 4'b0000 || dut.ALUControlE !== 4'b0000) ? "YES" : "NO");
        $display("  - Writeback active: %s",
                 (ResultW !== 32'hxxxxxxxx && dut.RegWriteW) ? "YES" : "NO");
        
        $display("\n=== SIMULATION COMPLETED ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #(CLK_PERIOD * 200);
        $display("*** TIMEOUT: Simulation stopped after 200 cycles ***");
        $finish;
    end

    // Performance monitoring
    integer instruction_count = 0;
    always @(posedge clk) begin
        if (!rst && !dut.StallFetch && dut.instrF !== 32'h00000000) begin
            instruction_count++;
        end
    end

    final begin
        $display("\n=== PERFORMANCE STATISTICS ===");
        $display("Instructions processed: %0d", instruction_count);
        $display("Total cycles: %0d", ($time - 30)/CLK_PERIOD);
        if (instruction_count > 0) begin
            $display("Average CPI: %.2f", real'(($time - 30)/CLK_PERIOD) / real'(instruction_count));
        end
    end

endmodule
