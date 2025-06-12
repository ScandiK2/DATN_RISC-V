module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 5
)(
    input  logic                              clk,
	input  logic 							  reset,
    input  logic [ADDRESS_WIDTH-1:0]          A1,
    input  logic [ADDRESS_WIDTH-1:0]          A2,
    input  logic [ADDRESS_WIDTH-1:0]          A3,
    input  logic [DATA_WIDTH-1:0]             WD3,
    input  logic                              WE3, 
    input  logic [ADDRESS_WIDTH-1:0] testRegAddress,

    output logic [DATA_WIDTH-1:0]             testRegData,
    output logic [DATA_WIDTH-1:0]             RD1,
    output logic [DATA_WIDTH-1:0]             RD2
);

logic [DATA_WIDTH-1:0] reg_file [2**ADDRESS_WIDTH-1:0];  

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		for (int i = 0; i < 32; i++) reg_file[i] <= 32'd0;
	end else
    if(WE3 && (A3 != 5'b0)) 
        reg_file[A3] <= WD3;
end 

always_comb begin
    RD1 = (A1 == 5'b0) ? 32'd0 : (A1 >=32) ? 32'd0 : reg_file[A1];
    RD2 = (A2 == 5'b0) ? 32'd0 : (A2 >= 32) ? 32'b0: reg_file[A2];
    testRegData = (testRegAddress == 5'd0) ? 32'd0 : reg_file[testRegAddress];

end

endmodule
