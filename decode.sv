module decode #(
    parameter DATA_WIDTH = 32,
    parameter REG_FILE_ADDRESS_WIDTH = 5
)(
    input logic                   clk,
	input logic 				  reset,
    input logic [DATA_WIDTH-1:0]  instrD,
    input logic [DATA_WIDTH-1:0]  ResultW,
    input logic [4:0]             RdW,
    input logic                   RegWriteW,
    input logic [REG_FILE_ADDRESS_WIDTH-1:0] testRegAddress,

    output logic [DATA_WIDTH-1:0] testRegData,
    output logic                  RegWriteD,
    output logic [1:0]            ResultSrcD,
    output logic                  MemWriteD,
    output logic                  JumpD,
    output logic                  BranchD,
    output logic [3:0]            ALUControlD,
    output logic                  ALUSrcD,
    output logic [DATA_WIDTH-1:0] RD1D,
    output logic [DATA_WIDTH-1:0] RD2D,
    output logic [4:0]            Rs1D,
    output logic [4:0]            Rs2D,
    output logic [4:0]            RdD,
    output logic [DATA_WIDTH-1:0] ExtImmD,
    output logic                  JALRInstrD,
    output logic [2:0]            AddressingControlD
);
	logic [2:0] ImmSrcD;




control_unit control_unit(
    // inputs 
    .op(instrD[6:0]),
    .funct3(instrD[14:12]),
    .funct7(instrD[31:25]), 

    // outputs 
    .RegWriteD(RegWriteD_tmp),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .JumpD(JumpD),
    .BranchD(BranchD),
    .ALUControlD(ALUControlD),
    .ALUSrcD(ALUSrcD),
    .ImmSrcD(ImmSrcD),
    .JALRInstrD(JALRInstrD),
    .AddressingControlD(AddressingControlD)
);

register_file register_file(
    // inputs
    .clk(clk),
	.reset(reset),
    .A1(instrD[19:15]),
    .A2(instrD[24:20]),
    .A3(RdW),
    .WD3(ResultW),
    .WE3(RegWriteW),
    .testRegAddress(testRegAddress),

    // outputs
    .testRegData(testRegData),
    .RD1(RD1D),
    .RD2(RD2D)
);

extend extend(
    // inputs
    .Immediate(instrD[31:7]),
    .ImmSrcD(ImmSrcD),
    //outputs
    .ExtImmD(ExtImmD)
);
always_comb begin
    Rs1D = instrD[19:15];
    Rs2D = instrD[24:20];
    RdD = instrD[11:7];
	// Chặn ghi nếu rd == x0
	RegWriteD = (instrD[11:7] == 5'd0) ? 1'b0 : RegWriteD_tmp;
end


endmodule
