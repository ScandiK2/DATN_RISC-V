`timescale 1ns / 1ps

module tb_pipelined_cpu;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter REG_FILE_ADDRESS_WIDTH = 5;
    parameter CLK_PERIOD = 10;

    // Testbench control signals
    logic clk;
    logic rst;
    logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress;
    logic [DATA_WIDTH-1:0] testRegData;
    logic [DATA_WIDTH-1:0] ResultW;

    // Performance monitoring
    integer instruction_count = 0;
    integer cycle_count = 0;
    
    // Tracking variables để kiểm tra hoạt động pipeline
    logic valid_instructions_detected = 0;
    logic register_operations_detected = 0;
    logic alu_operations_detected = 0;
    logic writeback_active_detected = 0;
    
    // Thêm biến để theo dõi hoạt động liên tục
    integer idle_cycles = 0;
    integer last_instruction_count = 0;

    // ✓ KHAI BÁO TẤT CẢ TÍN HIỆU PIPELINE ĐỂ HIỂN THỊ TRÊN WAVEFORM
    
    // === FETCH STAGE SIGNALS ===
    logic [31:0] PCF_wave;
    logic [31:0] instrF_wave;
    logic [31:0] PCPlus4F_wave;
    
    // === DECODE STAGE SIGNALS ===
    logic [31:0] PCD_wave;
    logic [31:0] instrD_wave;
    logic [31:0] RD1D_wave;
    logic [31:0] RD2D_wave;
    logic [3:0] ALUControlD_wave;
    logic [2:0] AddressingControlD_wave;
    logic [31:0] ExtImmD_wave;
    logic [4:0] Rs1D_wave;
    logic [4:0] Rs2D_wave;
    logic [4:0] RdD_wave;
    logic RegWriteD_wave;
    logic [1:0] ResultSrcD_wave;
    logic MemWriteD_wave;
    logic JumpD_wave;
    logic BranchD_wave;
    logic ALUSrcD_wave;
    logic JALRInstrD_wave;
    logic [31:0] PCPlus4D_wave;
    
    // === EXECUTE STAGE SIGNALS ===
    logic [3:0] ALUControlE_wave;
    logic [31:0] ALUResultE_wave;
    logic PCSrcE_wave;
    logic [31:0] PCTargetE_wave;
    logic [31:0] WriteDataE_wave;
    logic [31:0] RD1E_wave;
    logic [31:0] RD2E_wave;
    logic [31:0] PCE_wave;
    logic [31:0] ExtImmE_wave;
    logic RegWriteE_wave;
    logic [1:0] ResultSrcE_wave;
    logic MemWriteE_wave;
    logic JumpE_wave;
    logic BranchE_wave;
    logic ALUSrcE_wave;
    logic JALRInstrE_wave;
    logic [2:0] AddressingControlE_wave;
    logic [31:0] PCPlus4E_wave;
    logic [4:0] Rs1E_wave;
    logic [4:0] Rs2E_wave;
    logic [4:0] RdE_wave;
    
    // === MEMORY STAGE SIGNALS ===
    logic [31:0] ALUResultM_wave;
    logic MemWriteM_wave;
    logic [31:0] WriteDataM_wave;
    logic [2:0] AddressingControlM_wave;
    logic [31:0] ReadDataM_wave;
    logic [1:0] ResultSrcM_wave;
    logic RegWriteM_wave;
    logic [4:0] RdM_wave;
    logic [31:0] PCPlus4M_wave;
    
    // === WRITEBACK STAGE SIGNALS ===
    logic [31:0] ResultW_wave;
    logic RegWriteW_wave;
    logic [4:0] RdW_wave;
    logic [1:0] ResultSrcW_wave;
    logic [31:0] ALUResultW_wave;
    logic [31:0] ReadDataW_wave;
    logic [31:0] PCPlus4W_wave;
    
    // === HAZARD & FORWARDING SIGNALS ===
    logic StallFetch_wave;
    logic StallDecode_wave;
    logic FlushExecute_wave;
    logic FlushDecode_wave;
    logic [1:0] ForwardAE_wave;
    logic [1:0] ForwardBE_wave;
    
    // === CACHE SIGNALS ===
    logic [31:0] cacheDataE_wave;
    logic cachehitE_wave;
    logic [31:0] cacheDataM_wave;
    logic cachehitM_wave;
    logic useCacheM_wave;

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

    // ✓ ASSIGN TẤT CẢ TÍN HIỆU TỪ DUT ĐỂ HIỂN THỊ TRÊN WAVEFORM
    always_comb begin
        // FETCH STAGE
        PCF_wave = dut.PCF;
        instrF_wave = dut.instrF;
        PCPlus4F_wave = dut.PCPlus4F;
        
        // DECODE STAGE
        PCD_wave = dut.PCD;
        instrD_wave = dut.instrD;
        RD1D_wave = dut.RD1D;
        RD2D_wave = dut.RD2D;
        ALUControlD_wave = dut.ALUControlD;
        AddressingControlD_wave = dut.AddressingControlD;
        ExtImmD_wave = dut.ExtImmD;
        Rs1D_wave = dut.Rs1D;
        Rs2D_wave = dut.Rs2D;
        RdD_wave = dut.RdD;
        RegWriteD_wave = dut.RegWriteD;
        ResultSrcD_wave = dut.ResultSrcD;
        MemWriteD_wave = dut.MemWriteD;
        JumpD_wave = dut.JumpD;
        BranchD_wave = dut.BranchD;
        ALUSrcD_wave = dut.ALUSrcD;
        JALRInstrD_wave = dut.JALRInstrD;
        PCPlus4D_wave = dut.PCPlus4D;
        
        // EXECUTE STAGE
        ALUControlE_wave = dut.ALUControlE;
        ALUResultE_wave = dut.ALUResultE;
        PCSrcE_wave = dut.PCSrcE;
        PCTargetE_wave = dut.PCTargetE;
        WriteDataE_wave = dut.WriteDataE;
        RD1E_wave = dut.RD1E;
        RD2E_wave = dut.RD2E;
        PCE_wave = dut.PCE;
        ExtImmE_wave = dut.ExtImmE;
        RegWriteE_wave = dut.RegWriteE;
        ResultSrcE_wave = dut.ResultSrcE;
        MemWriteE_wave = dut.MemWriteE;
        JumpE_wave = dut.JumpE;
        BranchE_wave = dut.BranchE;
        ALUSrcE_wave = dut.ALUSrcE;
        JALRInstrE_wave = dut.JALRInstrE;
        AddressingControlE_wave = dut.AddressingControlE;
        PCPlus4E_wave = dut.PCPlus4E;
        Rs1E_wave = dut.Rs1E;
        Rs2E_wave = dut.Rs2E;
        RdE_wave = dut.RdE;
        
        // MEMORY STAGE
        ALUResultM_wave = dut.ALUResultM;
        MemWriteM_wave = dut.MemWriteM;
        WriteDataM_wave = dut.WriteDataM;
        AddressingControlM_wave = dut.AddressingControlM;
        ReadDataM_wave = dut.ReadDataM;
        ResultSrcM_wave = dut.ResultSrcM;
        RegWriteM_wave = dut.RegWriteM;
        RdM_wave = dut.RdM;
        PCPlus4M_wave = dut.PCPlus4M;
        
        // WRITEBACK STAGE
        ResultW_wave = dut.ResultW;
        RegWriteW_wave = dut.RegWriteW;
        RdW_wave = dut.RdW;
        ResultSrcW_wave = dut.ResultSrcW;
        ALUResultW_wave = dut.ALUResultW;
        ReadDataW_wave = dut.ReadDataW;
        PCPlus4W_wave = dut.PCPlus4W;
        
        // HAZARD & FORWARDING
        StallFetch_wave = dut.StallFetch;
        StallDecode_wave = dut.StallDecode;
        FlushExecute_wave = dut.FlushExecute;
        FlushDecode_wave = dut.FlushDecode;
        ForwardAE_wave = dut.ForwardAE;
        ForwardBE_wave = dut.ForwardBE;
        
        // CACHE SIGNALS
        cacheDataE_wave = dut.cacheDataE;
        cachehitE_wave = dut.cachehitE;
        cacheDataM_wave = dut.cacheDataM;
        cachehitM_wave = dut.cachehitM;
        useCacheM_wave = dut.useCacheM;
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ✓ WAVEFORM DUMP với tất cả tín hiệu đã khai báo
    initial begin
        $dumpfile("pipelined_cpu_debug.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        
        // === DUMP TẤT CẢ TÍN HIỆU PIPELINE ĐỂ HIỂN THỊ TRÊN WAVEFORM ===
        
        // TESTBENCH CONTROL
        $dumpvars(1, clk);
        $dumpvars(1, rst);
        $dumpvars(1, testRegAddress);
        $dumpvars(1, testRegData);
        
        // FETCH STAGE
        $dumpvars(1, PCF_wave);
        $dumpvars(1, instrF_wave);
        $dumpvars(1, PCPlus4F_wave);
        
        // DECODE STAGE
        $dumpvars(1, PCD_wave);
        $dumpvars(1, instrD_wave);
        $dumpvars(1, RD1D_wave);
        $dumpvars(1, RD2D_wave);
        $dumpvars(1, ALUControlD_wave);
        $dumpvars(1, AddressingControlD_wave);
        $dumpvars(1, ExtImmD_wave);
        $dumpvars(1, Rs1D_wave);
        $dumpvars(1, Rs2D_wave);
        $dumpvars(1, RdD_wave);
        $dumpvars(1, RegWriteD_wave);
        $dumpvars(1, ResultSrcD_wave);
        $dumpvars(1, MemWriteD_wave);
        $dumpvars(1, JumpD_wave);
        $dumpvars(1, BranchD_wave);
        $dumpvars(1, ALUSrcD_wave);
        $dumpvars(1, JALRInstrD_wave);
        $dumpvars(1, PCPlus4D_wave);
        
        // EXECUTE STAGE
        $dumpvars(1, ALUControlE_wave);
        $dumpvars(1, ALUResultE_wave);
        $dumpvars(1, PCSrcE_wave);
        $dumpvars(1, PCTargetE_wave);
        $dumpvars(1, WriteDataE_wave);
        $dumpvars(1, RD1E_wave);
        $dumpvars(1, RD2E_wave);
        $dumpvars(1, PCE_wave);
        $dumpvars(1, ExtImmE_wave);
        $dumpvars(1, RegWriteE_wave);
        $dumpvars(1, ResultSrcE_wave);
        $dumpvars(1, MemWriteE_wave);
        $dumpvars(1, JumpE_wave);
        $dumpvars(1, BranchE_wave);
        $dumpvars(1, ALUSrcE_wave);
        $dumpvars(1, JALRInstrE_wave);
        $dumpvars(1, AddressingControlE_wave);
        $dumpvars(1, PCPlus4E_wave);
        $dumpvars(1, Rs1E_wave);
        $dumpvars(1, Rs2E_wave);
        $dumpvars(1, RdE_wave);
        
        // MEMORY STAGE
        $dumpvars(1, ALUResultM_wave);
        $dumpvars(1, MemWriteM_wave);
        $dumpvars(1, WriteDataM_wave);
        $dumpvars(1, AddressingControlM_wave);
        $dumpvars(1, ReadDataM_wave);
        $dumpvars(1, ResultSrcM_wave);
        $dumpvars(1, RegWriteM_wave);
        $dumpvars(1, RdM_wave);
        $dumpvars(1, PCPlus4M_wave);
        
        // WRITEBACK STAGE
        $dumpvars(1, ResultW_wave);
        $dumpvars(1, RegWriteW_wave);
        $dumpvars(1, RdW_wave);
        $dumpvars(1, ResultSrcW_wave);
        $dumpvars(1, ALUResultW_wave);
        $dumpvars(1, ReadDataW_wave);
        $dumpvars(1, PCPlus4W_wave);
        
        // HAZARD & FORWARDING
        $dumpvars(1, StallFetch_wave);
        $dumpvars(1, StallDecode_wave);
        $dumpvars(1, FlushExecute_wave);
        $dumpvars(1, FlushDecode_wave);
        $dumpvars(1, ForwardAE_wave);
        $dumpvars(1, ForwardBE_wave);
        
        // CACHE SIGNALS
        $dumpvars(1, cacheDataE_wave);
        $dumpvars(1, cachehitE_wave);
        $dumpvars(1, cacheDataM_wave);
        $dumpvars(1, cachehitM_wave);
        $dumpvars(1, useCacheM_wave);
        
        // PERFORMANCE MONITORING
        $dumpvars(1, instruction_count);
        $dumpvars(1, cycle_count);
        $dumpvars(1, valid_instructions_detected);
        $dumpvars(1, register_operations_detected);
        $dumpvars(1, alu_operations_detected);
        $dumpvars(1, writeback_active_detected);
    end

    // Safe hierarchy checking
    initial begin
        #1;
        $display("=== SAFE HIERARCHY CHECK ===");
        $display("Top-level signals accessible:");
        $display("  PCF exists: %b", !$isunknown(dut.PCF));
        $display("  instrF exists: %b", !$isunknown(dut.instrF));
        $display("  instrD exists: %b", !$isunknown(dut.instrD));
        $display("  RD1D exists: %b", !$isunknown(dut.RD1D));
        $display("  RD2D exists: %b", !$isunknown(dut.RD2D));
        $display("  ALUResultM exists: %b", !$isunknown(dut.ALUResultM));
        $display("  WriteDataM exists: %b", !$isunknown(dut.WriteDataM));
        $display("  ReadDataM exists: %b", !$isunknown(dut.ReadDataM));
        $display("=================================");
    end

    // Task để hiển thị performance statistics on-demand
    task display_performance_stats();
        begin
            $display("\n=== PERFORMANCE STATISTICS (Real-time) ===");
            $display("Current time: %0t", $time);
            $display("Instructions processed: %0d", instruction_count);
            $display("Total cycles: %0d", cycle_count);
            if (instruction_count > 0) begin
                $display("Average CPI: %.2f", real'(cycle_count) / real'(instruction_count));
                $display("Instructions per cycle (IPC): %.2f", real'(instruction_count) / real'(cycle_count));
            end else begin
                $display("Average CPI: N/A (no instructions)");
                $display("Instructions per cycle (IPC): N/A");
            end
            
            // Pipeline efficiency metrics
            $display("Pipeline Status:");
            $display("  - Valid instructions detected: %s", valid_instructions_detected ? "YES" : "NO");
            $display("  - Register operations detected: %s", register_operations_detected ? "YES" : "NO");
            $display("  - ALU operations detected: %s", alu_operations_detected ? "YES" : "NO");
            $display("  - Writeback active detected: %s", writeback_active_detected ? "YES" : "NO");
            $display("  - Idle cycles: %0d", idle_cycles);
            
            // Cache performance (if applicable)
            if (cachehitE_wave || cachehitM_wave) begin
                $display("Cache Status:");
                $display("  - Cache hit in Execute: %b", cachehitE_wave);
                $display("  - Cache hit in Memory: %b", cachehitM_wave);
                $display("  - Using cache in Memory: %b", useCacheM_wave);
            end
            
            $display("============================================");
        end
    endtask

    // Tracking pipeline activity qua thời gian với real-time monitoring
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count++;
            
            // Track instruction count
            if (!dut.StallFetch && dut.instrF !== 32'h00000000 && dut.instrF !== 32'hxxxxxxxx) begin
                instruction_count++;
                idle_cycles = 0; // Reset idle counter khi có instruction
            end else begin
                idle_cycles++;
            end
            
            // Track valid instructions over time
            if (dut.instrF !== 32'hxxxxxxxx && dut.instrF !== 32'h00000000) begin
                valid_instructions_detected = 1;
            end
            
            // Track register operations over time
            if (dut.RD1D !== 32'hxxxxxxxx || dut.RD2D !== 32'hxxxxxxxx) begin
                register_operations_detected = 1;
            end
            
            // Track ALU operations over time
            if (dut.ALUControlD !== 4'b0000 || dut.ALUControlE !== 4'b0000) begin
                alu_operations_detected = 1;
            end
            
            // Track writeback activity over time
            if (ResultW !== 32'hxxxxxxxx && dut.RegWriteW) begin
                writeback_active_detected = 1;
            end
            
            // **REAL-TIME PERFORMANCE MONITORING**
            // Hiển thị stats mỗi 5 cycles
            if (cycle_count % 5 == 0) begin
                $display("[REAL-TIME] Cycle %0d: PC=0x%08X, Instr=0x%08X, CPI=%.2f", 
                         cycle_count, PCF_wave, instrF_wave,
                         instruction_count > 0 ? real'(cycle_count)/real'(instruction_count) : 0.0);
            end
            
            // Hiển thị detailed stats mỗi 10 cycles
            if (cycle_count % 10 == 0) begin
                display_performance_stats();
            end
            
            // Kiểm tra early termination nếu không có hoạt động
            if (cycle_count > 20 && idle_cycles > 10) begin
                $display("\n=== EARLY TERMINATION DETECTED ===");
                $display("No instruction activity for %0d cycles", idle_cycles);
                display_performance_stats();
                $display("Terminating simulation due to inactivity...");
                $finish;
            end
        end
    end

    // Simplified monitoring - chỉ hiển thị những thay đổi quan trọng
    always @(posedge clk) begin
        if (!rst && cycle_count <= 50) begin // Chỉ hiển thị 50 cycles đầu để tránh spam
            if (cycle_count % 5 == 0) begin // Mỗi 5 cycles
                $display("\n=== CYCLE %0d SUMMARY ===", cycle_count);
                $display("FETCH: PC=0x%08X, Instr=0x%08X", PCF_wave, instrF_wave);
                $display("DECODE: PC=0x%08X, Instr=0x%08X, RD1=0x%08X, RD2=0x%08X", 
                         PCD_wave, instrD_wave, RD1D_wave, RD2D_wave);
                $display("EXECUTE: ALUResult=0x%08X, Branch=%b, Jump=%b", 
                         ALUResultE_wave, PCSrcE_wave, JumpE_wave);
                $display("MEMORY: ALUResult=0x%08X, MemWrite=%b, ReadData=0x%08X", 
                         ALUResultM_wave, MemWriteM_wave, ReadDataM_wave);
                $display("WRITEBACK: Result=0x%08X, RegWrite=%b, Rd=%0d", 
                         ResultW_wave, RegWriteW_wave, RdW_wave);
                
                if (StallFetch_wave || StallDecode_wave || FlushExecute_wave || FlushDecode_wave) begin
                    $display("HAZARDS: StallF=%b, StallD=%b, FlushE=%b, FlushD=%b",
                             StallFetch_wave, StallDecode_wave, FlushExecute_wave, FlushDecode_wave);
                end
                
                if (ForwardAE_wave != 2'b00 || ForwardBE_wave != 2'b00) begin
                    $display("FORWARDING: ForwardAE=%02b, ForwardBE=%02b", ForwardAE_wave, ForwardBE_wave);
                end
            end
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
        if (!rst && PCSrcE_wave) begin
            $display("[%0t] *** CONTROL TRANSFER: PC = 0x%08X -> 0x%08X ***", 
                     $time, PCE_wave, PCTargetE_wave);
        end
    end

    // Memory operation detection
    always @(posedge clk) begin
        if (!rst) begin
            if (MemWriteM_wave) begin
                $display("[%0t] *** STORE: Addr=0x%08X, Data=0x%08X, Mode=%03b ***",
                         $time, ALUResultM_wave, WriteDataM_wave, AddressingControlM_wave);
            end
            if (ResultSrcM_wave[0]) begin
                $display("[%0t] *** LOAD: Addr=0x%08X, Data=0x%08X, Mode=%03b ***",
                         $time, ALUResultM_wave, ReadDataM_wave, AddressingControlM_wave);
            end
        end
    end

    // Main test sequence
    initial begin
        $display("=== PIPELINED CPU TESTBENCH STARTED ===");
        $display("Testing 5-stage pipeline: Fetch -> Decode -> Execute -> Memory -> Writeback");
        $display("Real-time performance monitoring enabled");
        
        // Initialize
        rst = 1;
        testRegAddress = 0;
        
        // Reset sequence
        $display("[%0t] Applying reset for 3 cycles...", $time);
        repeat(3) @(posedge clk);
        
        rst = 0;
        $display("[%0t] Reset released, CPU starting...", $time);
        
        // Let pipeline run for sufficient cycles với intermediate checks
        repeat(20) @(posedge clk);
        
        // Intermediate performance check
        $display("\n=== INTERMEDIATE PERFORMANCE CHECK ===");
        display_performance_stats();
        
        repeat(20) @(posedge clk);
        
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
        
        // Final performance statistics
        $display("\n=== FINAL PERFORMANCE STATISTICS ===");
        display_performance_stats();
        
        // Final diagnosis sử dụng tracking variables
        $display("\n=== FINAL DIAGNOSIS ===");
        $display("After %0d cycles:", cycle_count);
        $display("  - Valid instructions: %s", valid_instructions_detected ? "YES" : "NO");
        $display("  - Register operations: %s", register_operations_detected ? "YES" : "NO");
        $display("  - ALU operations: %s", alu_operations_detected ? "YES" : "NO");
        $display("  - Writeback active: %s", writeback_active_detected ? "YES" : "NO");
        
        $display("\n=== SIMULATION COMPLETED SUCCESSFULLY ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #(CLK_PERIOD * 200);
        $display("*** TIMEOUT: Simulation stopped after 200 cycles ***");
        display_performance_stats();
        $finish;
    end

    // Performance statistics - vẫn giữ final block nhưng không phụ thuộc vào nó
    final begin
        $display("\n=== FINAL CLEANUP STATISTICS ===");
        $display("Instructions processed: %0d", instruction_count);
        $display("Total cycles: %0d", cycle_count);
        if (instruction_count > 0) begin
            $display("Average CPI: %.2f", real'(cycle_count) / real'(instruction_count));
        end
        $display("Simulation ended at time: %0t", $time);
    end

endmodule






/*
/////////////////////////////////////////////////////////
//-------Hiển thị thêm các tín hiệu tại các stage------//
/////////////////////////////////////////////////////////

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

    // Performance monitoring
    integer instruction_count = 0;
    integer cycle_count = 0;
    
    // Tracking variables để kiểm tra hoạt động pipeline
    logic valid_instructions_detected = 0;
    logic register_operations_detected = 0;
    logic alu_operations_detected = 0;
    logic writeback_active_detected = 0;

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

    // ✓ WAVEFORM DUMP với tất cả tín hiệu yêu cầu
    initial begin
        $dumpfile("pipelined_cpu_debug.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        
        // ✓ Dump tất cả tín hiệu theo từng stage như yêu cầu
        
        // FETCH STAGE
        $dumpvars(1, dut.PCF);
        $dumpvars(1, dut.instrF);
        
        // DECODE STAGE  
        $dumpvars(1, dut.PCD);
        $dumpvars(1, dut.instrD);
        $dumpvars(1, dut.RD1D);
        $dumpvars(1, dut.RD2D);
        $dumpvars(1, dut.ALUControlD);
        $dumpvars(1, dut.AddressingControlD);
        
        // EXECUTE STAGE
        $dumpvars(1, dut.ALUControlE);
        $dumpvars(1, dut.ALUResultE);
        $dumpvars(1, dut.PCSrcE);
        $dumpvars(1, dut.PCTargetE);
        
        // MEMORY STAGE
        $dumpvars(1, dut.ALUResultM);
        $dumpvars(1, dut.MemWriteM);
        $dumpvars(1, dut.WriteDataM);
        $dumpvars(1, dut.AddressingControlM);
        $dumpvars(1, dut.ReadDataM);
        $dumpvars(1, dut.ResultSrcM);
        
        // WRITEBACK STAGE
        $dumpvars(1, dut.ResultW);
        $dumpvars(1, dut.RegWriteW);
        $dumpvars(1, dut.RdW);
        $dumpvars(1, dut.ResultSrcW);
        $dumpvars(1, dut.ALUResultW);
        $dumpvars(1, dut.ReadDataW);
        $dumpvars(1, dut.PCPlus4W);
        
        // HAZARD & FORWARDING
        $dumpvars(1, dut.StallFetch);
        $dumpvars(1, dut.StallDecode);
        $dumpvars(1, dut.FlushExecute);
        $dumpvars(1, dut.FlushDecode);
        $dumpvars(1, dut.ForwardAE);
        $dumpvars(1, dut.ForwardBE);
        
        // PIPELINE REGISTERS
        $dumpvars(1, dut.PCPlus4F);
        $dumpvars(1, dut.PCPlus4D);
        $dumpvars(1, dut.PCPlus4E);
        $dumpvars(1, dut.PCPlus4M);
        
        // ADDITIONAL EXECUTE SIGNALS
        $dumpvars(1, dut.RD1E);
        $dumpvars(1, dut.RD2E);
        $dumpvars(1, dut.PCE);
        $dumpvars(1, dut.ExtImmE);
        $dumpvars(1, dut.WriteDataE);
        
        // ADDITIONAL DECODE SIGNALS
        $dumpvars(1, dut.ExtImmD);
        $dumpvars(1, dut.Rs1D);
        $dumpvars(1, dut.Rs2D);
        $dumpvars(1, dut.RdD);
        $dumpvars(1, dut.RegWriteD);
        $dumpvars(1, dut.ResultSrcD);
        $dumpvars(1, dut.MemWriteD);
        $dumpvars(1, dut.JumpD);
        $dumpvars(1, dut.BranchD);
        $dumpvars(1, dut.ALUSrcD);
        $dumpvars(1, dut.JALRInstrD);
    end

    // Safe hierarchy checking
    initial begin
        #1;
        $display("=== SAFE HIERARCHY CHECK ===");
        $display("Top-level signals accessible:");
        $display("  PCF exists: %b", !$isunknown(dut.PCF));
        $display("  instrF exists: %b", !$isunknown(dut.instrF));
        $display("  instrD exists: %b", !$isunknown(dut.instrD));
        $display("  RD1D exists: %b", !$isunknown(dut.RD1D));
        $display("  RD2D exists: %b", !$isunknown(dut.RD2D));
        $display("  ALUResultM exists: %b", !$isunknown(dut.ALUResultM));
        $display("  WriteDataM exists: %b", !$isunknown(dut.WriteDataM));
        $display("  ReadDataM exists: %b", !$isunknown(dut.ReadDataM));
        $display("=================================");
    end

    // Tracking pipeline activity qua thời gian
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count++;
            
            // Track instruction count
            if (!dut.StallFetch && dut.instrF !== 32'h00000000 && dut.instrF !== 32'hxxxxxxxx) begin
                instruction_count++;
            end
            
            // Track valid instructions over time
            if (dut.instrF !== 32'hxxxxxxxx && dut.instrF !== 32'h00000000) begin
                valid_instructions_detected = 1;
            end
            
            // Track register operations over time
            if (dut.RD1D !== 32'hxxxxxxxx || dut.RD2D !== 32'hxxxxxxxx) begin
                register_operations_detected = 1;
            end
            
            // Track ALU operations over time
            if (dut.ALUControlD !== 4'b0000 || dut.ALUControlE !== 4'b0000) begin
                alu_operations_detected = 1;
            end
            
            // Track writeback activity over time
            if (ResultW !== 32'hxxxxxxxx && dut.RegWriteW) begin
                writeback_active_detected = 1;
            end
        end
    end

    // Detailed monitoring với tất cả tín hiệu
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n=== CYCLE %0d at time %0t ===", cycle_count, $time);
            
            // FETCH STAGE
            $display("FETCH STAGE:");
            $display("  PCF = 0x%08X", dut.PCF);
            $display("  instrF = 0x%08X %s", dut.instrF, 
                     (dut.instrF === 32'hxxxxxxxx) ? "(UNDEFINED)" : 
                     (dut.instrF === 32'h00000000) ? "(NOP/ZERO)" : "(VALID)");
            $display("  PCPlus4F = 0x%08X", dut.PCPlus4F);
            
            // DECODE STAGE
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
            $display("  RegWriteD = %b, MemWriteD = %b, JumpD = %b, BranchD = %b", 
                     dut.RegWriteD, dut.MemWriteD, dut.JumpD, dut.BranchD);
            
            // EXECUTE STAGE
            $display("EXECUTE STAGE:");
            $display("  ALUControlE = %04b", dut.ALUControlE);
            $display("  ALUResultE = 0x%08X", dut.ALUResultE);
            $display("  PCSrcE = %b", dut.PCSrcE);
            $display("  PCTargetE = 0x%08X", dut.PCTargetE);
            $display("  WriteDataE = 0x%08X", dut.WriteDataE);
            if (dut.PCSrcE) begin
                $display("  *** BRANCH TAKEN: PCTarget = 0x%08X ***", dut.PCTargetE);
            end
            
            // MEMORY STAGE
            $display("MEMORY STAGE:");
            $display("  ALUResultM = 0x%08X", dut.ALUResultM);
            $display("  MemWriteM = %b", dut.MemWriteM);
            $display("  WriteDataM = 0x%08X", dut.WriteDataM);
            $display("  AddressingControlM = %03b", dut.AddressingControlM);
            $display("  ReadDataM = 0x%08X", dut.ReadDataM);
            $display("  ResultSrcM = %02b", dut.ResultSrcM);
            if (dut.MemWriteM) begin
                $display("  *** MEMORY WRITE: Data = 0x%08X ***", dut.WriteDataM);
            end
            
            // WRITEBACK STAGE
            $display("WRITEBACK:");
            $display("  ResultW = 0x%08X %s", ResultW,
                     (ResultW === 32'hxxxxxxxx) ? "(UNDEFINED)" : "(VALID)");
            $display("  RegWriteW = %b", dut.RegWriteW);
            $display("  RdW = %0d", dut.RdW);
            $display("  ResultSrcW = %02b", dut.ResultSrcW);
            $display("  ALUResultW = 0x%08X", dut.ALUResultW);
            $display("  ReadDataW = 0x%08X", dut.ReadDataW);
            
            // HAZARD DETECTION
            if (dut.StallFetch || dut.StallDecode || dut.FlushExecute || dut.FlushDecode) begin
                $display("HAZARD DETECTED:");
                $display("  StallF=%b, StallD=%b, FlushE=%b, FlushD=%b",
                         dut.StallFetch, dut.StallDecode, dut.FlushExecute, dut.FlushDecode);
            end
            
            // FORWARDING
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
        
        // Let pipeline run for sufficient cycles
        repeat(40) @(posedge clk);
        
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
        
        // Final diagnosis sử dụng tracking variables
        $display("\n=== FINAL DIAGNOSIS ===");
        $display("After %0d cycles:", cycle_count);
        $display("  - Valid instructions: %s", valid_instructions_detected ? "YES" : "NO");
        $display("  - Register operations: %s", register_operations_detected ? "YES" : "NO");
        $display("  - ALU operations: %s", alu_operations_detected ? "YES" : "NO");
        $display("  - Writeback active: %s", writeback_active_detected ? "YES" : "NO");
        
        $display("\n=== SIMULATION COMPLETED ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #(CLK_PERIOD * 200);
        $display("*** TIMEOUT: Simulation stopped after 200 cycles ***");
        $finish;
    end

    // Performance statistics
    final begin
        $display("\n=== PERFORMANCE STATISTICS ===");
        $display("Instructions processed: %0d", instruction_count);
        $display("Total cycles: %0d", cycle_count);
        if (instruction_count > 0) begin
            $display("Average CPI: %.2f", real'(cycle_count) / real'(instruction_count));
        end
    end

endmodule
*/



//--------------------------------------------------------//
//--------TESTBENCH DƯỚI CHỈ HIỆN THỊ TÍN HIỆU CHÍNH------//
//--------------------------------------------------------//

/*
`timescale 1ns / 1ps

module tb_pipelined_cpu;

    // Parameters và signals giữ nguyên như file bạn gửi
    parameter DATA_WIDTH = 32;
    parameter REG_FILE_ADDRESS_WIDTH = 5;
    parameter CLK_PERIOD = 10;

    logic clk;
    logic rst;
    logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress;
    logic [DATA_WIDTH-1:0] testRegData;
    logic [DATA_WIDTH-1:0] ResultW;

    // Performance monitoring
    integer instruction_count = 0;
    integer cycle_count = 0;
    
    // ✓ THÊM: Tracking variables để kiểm tra hoạt động pipeline
    logic valid_instructions_detected = 0;
    logic register_operations_detected = 0;
    logic alu_operations_detected = 0;
    logic writeback_active_detected = 0;

    // DUT instantiation giữ nguyên
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

    // Waveform dump
    initial begin
        $dumpfile("pipelined_cpu_debug.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        $dumpvars(1, dut.PCF, dut.instrF, dut.PCD, dut.instrD,
                  dut.RD1D, dut.RD2D, dut.ALUControlD, dut.ALUControlE,
                  dut.ALUResultE, dut.ALUResultM, dut.ResultW);
    end

    // ✓ SỬA: Tracking pipeline activity qua thời gian
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count++;
            
            // Track instruction count
            if (!dut.StallFetch && dut.instrF !== 32'h00000000 && dut.instrF !== 32'hxxxxxxxx) begin
                instruction_count++;
            end
            
            // ✓ Track valid instructions over time
            if (dut.instrF !== 32'hxxxxxxxx && dut.instrF !== 32'h00000000) begin
                valid_instructions_detected = 1;
            end
            
            // ✓ Track register operations over time
            if (dut.RD1D !== 32'hxxxxxxxx || dut.RD2D !== 32'hxxxxxxxx) begin
                register_operations_detected = 1;
            end
            
            // ✓ Track ALU operations over time
            if (dut.ALUControlD !== 4'b0000 || dut.ALUControlE !== 4'b0000) begin
                alu_operations_detected = 1;
            end
            
            // ✓ Track writeback activity over time
            if (ResultW !== 32'hxxxxxxxx && dut.RegWriteW) begin
                writeback_active_detected = 1;
            end
        end
    end

    // Detailed monitoring (giữ nguyên từ file bạn gửi)
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n=== CYCLE %0d at time %0t ===", cycle_count, $time);
            
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
            
            // Memory Stage
            $display("MEMORY STAGE:");
            $display("  ALUResultM = 0x%08X", dut.ALUResultM);
            $display("  MemWriteM = %b", dut.MemWriteM);
            
            // Writeback Stage
            $display("WRITEBACK:");
            $display("  ResultW = 0x%08X %s", ResultW,
                     (ResultW === 32'hxxxxxxxx) ? "(UNDEFINED)" : "(VALID)");
            $display("  RegWriteW = %b", dut.RegWriteW);
            $display("  RdW = %0d", dut.RdW);
            
            // Hazard/Forwarding (giữ nguyên)
            if (dut.StallFetch || dut.StallDecode || dut.FlushExecute || dut.FlushDecode) begin
                $display("HAZARD DETECTED:");
                $display("  StallF=%b, StallD=%b, FlushE=%b, FlushD=%b",
                         dut.StallFetch, dut.StallDecode, dut.FlushExecute, dut.FlushDecode);
            end
            
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

    // Memory operation detection (giữ nguyên)
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

    // Branch/Jump detection
    always @(posedge clk) begin
        if (!rst && dut.PCSrcE) begin
            $display("[%0t] *** CONTROL TRANSFER: PC = 0x%08X -> 0x%08X ***", 
                     $time, dut.PCE, dut.PCTargetE);
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
        
        // Let pipeline run for sufficient cycles
        repeat(40) @(posedge clk);
        
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
        
        // ✓ SỬA: Final diagnosis sử dụng tracking variables
        $display("\n=== FINAL DIAGNOSIS ===");
        $display("After %0d cycles:", cycle_count);
        $display("  - Valid instructions: %s", valid_instructions_detected ? "YES" : "NO");
        $display("  - Register operations: %s", register_operations_detected ? "YES" : "NO");
        $display("  - ALU operations: %s", alu_operations_detected ? "YES" : "NO");
        $display("  - Writeback active: %s", writeback_active_detected ? "YES" : "NO");
        
        $display("\n=== SIMULATION COMPLETED ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #(CLK_PERIOD * 200);
        $display("*** TIMEOUT: Simulation stopped after 200 cycles ***");
        $finish;
    end

    // Performance statistics
    final begin
        $display("\n=== PERFORMANCE STATISTICS ===");
        $display("Instructions processed: %0d", instruction_count);
        $display("Total cycles: %0d", cycle_count);
        if (instruction_count > 0) begin
            $display("Average CPI: %.2f", real'(cycle_count) / real'(instruction_count));
        end
    end

endmodule
*/