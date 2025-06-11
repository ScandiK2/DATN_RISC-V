module fetch #(
    parameter DATA_WIDTH = 32,
    parameter ENABLE_ICACHE = 1
)(
    input logic clk,
    input logic reset,
    input logic enable,
    input logic  PCSrcE,
    input logic JALRinstrE,
    input logic [DATA_WIDTH-1:0]ALUResultE,
    input logic [DATA_WIDTH-1:0] PCTargetE,
    output logic [DATA_WIDTH-1:0] instrF,
    output logic [DATA_WIDTH-1:0] PCPlus4F,
    output logic [DATA_WIDTH-1:0] PCF
);
	logic hit;
	logic [DATA_WIDTH-1:0] cacheInstr;
	logic [DATA_WIDTH-1:0] memInstr;
	logic cache_write_enable;
	
PC counter(
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .ALUResultE(ALUResultE),
    .PCTargetE(PCTargetE),
    .PCSrcE(PCSrcE),
    .JALRinstr(JALRinstrE),
    .PCPlus4F(PCPlus4F),
    .PCF(PCF)
);

//assign instrF = memInstr;


inst_mem memory(
    .A(PCF),
    .RD(memInstr)
);

/*
direct_mapped cache (
    .clk(clk),
    .address(PCF),
    .datain(memInstr),
    .WE(~hit),

    .hit(hit),
    .dataout(cacheInstr)
);
*/

generate
        if (ENABLE_ICACHE) begin : icache_gen
            // Cache write logic - chỉ write khi miss và có valid data
            assign cache_write_enable = ~hit & (memInstr !== 32'hxxxxxxxx);
            
            // Direct-mapped instruction cache
            direct_mapped #(
                .DATA_WIDTH(32),
                .CACHE_LENGTH(8),
                .TAG_WIDTH(27),
                .SET_WIDTH(3)
            ) cache (
                .clk(clk),
                .reset(reset),          //  Thêm reset signal
                .address(PCF),
                .datain(memInstr),
                .WE(cache_write_enable), //  Sửa write enable logic
                .hit(hit),
                .dataout(cacheInstr)
            );
            
            //  Output selection logic 
            assign instrF = hit ? cacheInstr : memInstr;
            
        end else begin : no_icache_gen
            // Bypass cache - direct memory access
            assign instrF = memInstr;
            assign hit = 1'b0;
            assign cacheInstr = 32'h00000000;
        end
    endgenerate


/*
Nway_assos cache (
    .clk(clk),
    .address(PCF),
    .datain(memInstr),
    .WE(~hit),

    .hit(hit),
    .dataout(cacheInstr)
);
*/
//assign instrF = hit ? cacheInstr : memInstr;

endmodule
