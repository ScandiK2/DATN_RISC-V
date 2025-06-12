module data_mem #(
	parameter DATA_WIDTH = 32,
	parameter STORAGE_WIDTH = 8
)(
// interface signals
	input logic [DATA_WIDTH-1:0] A,
	input logic clk,
    input logic WE,
	input logic [2:0] AddressingControl,
	input logic [DATA_WIDTH-1:0] WD,
	output logic [DATA_WIDTH-1:0] RD
);

logic [1:0] addressing_mode = AddressingControl[1:0];
logic zero_extend = AddressingControl[2];

// mem map says data mem runs from 00000 -> 1FFFF = 131071 Aesses = 2**17
//logic [STORAGE_WIDTH-1:0] ram_array [2**17-1:0];

// 128KB data  memory
logic [STORAGE_WIDTH-1:0] ram_array [0:2**17-1];
logic [16:0] addr = A[16:0];  // get least 17 bits of address

/*
initial begin
	string path;
    int file;
    file = $fopen("../../rtl_pipelined/datamem_path.txt", "r"); // this true as the working directory is the one containing the testbench
    if (file) $display("Data file opened successfully");
    else $display("File could not be opened, %0d", file);
    $fgets(path, file);
    $fclose(file);

	$display("Loading data memory...");
    $readmemh(path, ram_array, 20'h10000);
    $display("Data memory loaded....");
end
*/
initial begin
	
	// Khởi tạo dữ liệu:
	// Địa chỉ 0x0000: Dữ liệu test cho load word
    // Word 0: 0x12345678
    ram_array[0] = 8'h78;   // LSB
    ram_array[1] = 8'h56;
    ram_array[2] = 8'h34;
    ram_array[3] = 8'h12;   // MSB
    
    // Word 1: 0xDEADBEEF  
    ram_array[4] = 8'hEF;
    ram_array[5] = 8'hBE;
    ram_array[6] = 8'hAD;
    ram_array[7] = 8'hDE;
    
    // Word 2: 0xCAFEBABE
    ram_array[8] = 8'hBE;
    ram_array[9] = 8'hBA;
    ram_array[10] = 8'hFE;
    ram_array[11] = 8'hCA;
    
    // Kiểm tra load/STORE
    ram_array[16] = 8'h00;  
    ram_array[17] = 8'h00;  
    ram_array[18] = 8'h00;  
    ram_array[19] = 8'h00;  
    

    ram_array[32] = 8'hFF;  // 0x7FFF (positive max halfword)
    ram_array[33] = 8'h7F;
    ram_array[34] = 8'h00;  // 0x8000 (negative min halfword)
    ram_array[35] = 8'h80;
    ram_array[36] = 8'hFF;  // 0xFFFF (all ones halfword)
    ram_array[37] = 8'hFF;
    ram_array[38] = 8'h34;  // 0x1234 (simple pattern)
    ram_array[39] = 8'h12;
    
    for (int i = 256; i < 512; i++) begin
        ram_array[i] = 8'hAA;  // Pattern ban đầu
    end
    
    ram_array[512] = 8'h64;
    ram_array[513] = 8'h00;
    ram_array[514] = 8'h00;
    ram_array[515] = 8'h00;
    

    ram_array[516] = 8'h32;
    ram_array[517] = 8'h00;
    ram_array[518] = 8'h00;
    ram_array[519] = 8'h00;
    
    ram_array[520] = 8'hE7;
    ram_array[521] = 8'hFF;
    ram_array[522] = 8'hFF;
    ram_array[523] = 8'hFF;
end
// writing to memory (store instructions)
always @(posedge clk) begin
	if (WE) begin
		case(addressing_mode)
			2'b00 : // byte addressing
				ram_array[addr] <= WD[7:0];
			2'b01 : // half-word addressing
				begin
					ram_array[addr] <= WD[7:0];
					ram_array[addr+1] <= WD[15:8];
				end
			2'b10:  // word addressing
				begin
					ram_array[addr] <= WD[7:0];
					ram_array[addr+1] <= WD[15:8];
					ram_array[addr+2] <= WD[23:16];
					ram_array[addr+3] <= WD[31:24];
				end
			default : ram_array[addr] <= 0;
		endcase
		// $display("Data : %h, add: %h", {ram_array[3], ram_array[2], ram_array[1], ram_array[0]}, A);
	end

end

// reading from memory (load instructions)
always_comb begin
	case(addressing_mode) 
		2'b00 : // byte addressing
			if(zero_extend) // lbu
				RD = {24'b0, ram_array[addr]};
			else // lb
				RD = {{24{ram_array[addr][7]}}, ram_array[addr]};

		2'b01 : // half addressing
			if(zero_extend) // lhu
				RD = {16'b0, ram_array[addr+1] ,ram_array[addr]};
			else  // lh
				RD = {{16{ram_array[addr+1][7]}}, ram_array[addr+1], ram_array[addr]};
		
		2'b10 :  // word addressing
			// sign extend bit is don't care
			RD = {ram_array[addr+3], ram_array[addr+2], ram_array[addr+1], ram_array[addr]};
		default : RD = 0;
	endcase
	//$display("RD: %h", RD);
end

endmodule
