`timescale 1ns / 1ps

module tb_pipelined_cpu_ver2;

    parameter DATA_WIDTH = 32;
    parameter REG_FILE_ADDRESS_WIDTH = 5;
    parameter CLK_PERIOD = 10;

    logic clk;
    logic rst;
    logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress;
    logic [DATA_WIDTH-1:0] testRegData;
    logic [DATA_WIDTH-1:0] ResultW;

    // Debug signals for waveform
    logic [31:0] PCF_debug, PCD_debug, instrF_debug, instrD_debug;
    logic [31:0] RD1D_debug, RD2D_debug;
    logic [3:0] ALUControlD_debug, ALUControlE_debug;
    logic [2:0] AddressingControlD_debug;
    logic [31:0] ALUResultE_debug, ALUResultM_debug;
    logic [31:0] SrcA_debug, SrcB_debug;

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
        ALUResultM_debug = dut.ALUResultM;
        // Truy cập SrcA, SrcB từ module ALU trong execute stage
        SrcA_debug = dut.execute.SrcAE;
        SrcB_debug = dut.execute.SrcBE;
    end

    // Waveform dump
    initial begin
        $dumpfile("pipelined_cpu_debug.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        $dumpvars(1, dut.PCF, dut.instrF, dut.PCD, dut.instrD,
                  dut.RD1D, dut.RD2D, dut.ALUControlD, dut.ALUControlE,
                  dut.ALUResultE, dut.ALUResultM, dut.ResultW,
                  dut.execute.SrcAE, dut.execute.SrcBE);
    end

    // Main test sequence
    initial begin
        $display("=== PIPELINED CPU TESTBENCH STARTED ===");
        rst = 1;
        testRegAddress = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset released, CPU starting...", $time);

        repeat(30) @(posedge clk);

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

    // Register monitoring task
    task check_register(input [4:0] reg_addr, input string reg_name);
        begin
            testRegAddress = reg_addr;
            #1;
            $display("[%0t] %s (x%0d) = 0x%08X", $time, reg_name, reg_addr, testRegData);
        end
    endtask

    // Detailed monitoring với tín hiệu mở rộng
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n=== CYCLE %0d at time %0t ===", ($time - 30)/CLK_PERIOD, $time);
            // Fetch Stage
            $display("FETCH STAGE: PCF = 0x%08X, instrF = 0x%08X", dut.PCF, dut.instrF);
            // Decode Stage
            $display("DECODE STAGE: PCD = 0x%08X, instrD = 0x%08X, RD1D = 0x%08X, RD2D = 0x%08X, ALUControlD = %04b, AddressingControlD = %03b",
                     dut.PCD, dut.instrD, dut.RD1D, dut.RD2D, dut.ALUControlD, dut.AddressingControlD);
            // Execute Stage
            $display("EXECUTE STAGE: ALUControlE = %04b, SrcA = 0x%08X, SrcB = 0x%08X, ALUResultE = 0x%08X, PCSrcE = %b",
                     dut.ALUControlE, SrcA_debug, SrcB_debug, dut.ALUResultE, dut.PCSrcE);
            // Memory Stage
            $display("MEMORY STAGE: ALUResultM = 0x%08X, MemWriteM = %b", dut.ALUResultM, dut.MemWriteM);
            // Writeback Stage
            $display("WRITEBACK: ResultW = 0x%08X, RegWriteW = %b, RdW = %0d", ResultW, dut.RegWriteW, dut.RdW);
            // Hazard/Forwarding
            if (dut.StallFetch || dut.StallDecode || dut.FlushExecute || dut.FlushDecode)
                $display("HAZARD DETECTED: StallF=%b, StallD=%b, FlushE=%b, FlushD=%b",
                         dut.StallFetch, dut.StallDecode, dut.FlushExecute, dut.FlushDecode);
            if (dut.ForwardAE != 2'b00 || dut.ForwardBE != 2'b00)
                $display("FORWARDING: ForwardAE=%02b, ForwardBE=%02b", dut.ForwardAE, dut.ForwardBE);
            $display("================================================");
        end
    end

    // Kiểm tra kết quả ALU so với lệnh
    always @(posedge clk) begin
        if (!rst) begin
            // Ví dụ: kiểm tra kết quả ALU cho addi x1, x0, 5 (opcode 0x00500093)
            if (dut.instrD == 32'h00500093 && dut.ALUResultE !== 32'hxxxxxxxx) begin
                if (dut.ALUResultE == 32'd5)
                    $display("[CHECK] addi x1, x0, 5: ALUResultE OK (5)");
                else
                    $display("[CHECK] addi x1, x0, 5: ALUResultE ERROR! Got 0x%08X", dut.ALUResultE);
            end
            // Có thể bổ sung thêm kiểm tra cho các lệnh khác tương tự
        end
    end

    // Timeout protection
    initial begin
        #(CLK_PERIOD * 200);
        $display("*** TIMEOUT: Simulation stopped after 200 cycles ***");
        $finish;
    end

endmodule
