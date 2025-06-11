module inst_mem #(
    parameter STORAGE_WIDTH = 8
) (
    input logic [31:0] A,
    output logic [31:0] RD
);

logic [11:0] addr;
// Khai báo memory từ 0 đến 4095 (4KB)
logic [STORAGE_WIDTH-1:0] rom_array [0:4095];

/*
Cách nạp lệnh bằng file hex // Lỗi đường dẫn khi mô phỏng chưa fix được
initial begin
    string path;
    int file;
    file = $fopen("../../rtl_pipelined/instmem_path.txt", "r");
    if (file) $display("Instr file opened successfully");
    else $display("File could not be opened, %0d", file);
    $fgets(path, file);
    $display("path: %s", path);
    $fclose(file);
    

    $display("Loading instruction memory...");
    $readmemh(path, rom_array);
    $display("Instruction memory loaded....");// instr.mem to be preloaded depending on the program to be executed
end
*/
// Khởi tạo trực tiếp lệnh lưu vào trong bộ nhớ
initial begin
	// Instruction 1: addi x1, x0, 5 (0x00500093)
    rom_array[0] = 8'h93; rom_array[1] = 8'h00;
    rom_array[2] = 8'h50; rom_array[3] = 8'h00;
    
    // Instruction 2: addi x2, x0, 3 (0x00300113)
    rom_array[4] = 8'h13; rom_array[5] = 8'h01;
    rom_array[6] = 8'h30; rom_array[7] = 8'h00;
    
    // Instruction 3: add x3, x1, x2 (0x002081b3)
    rom_array[8] = 8'hb3; rom_array[9] = 8'h81;
    rom_array[10] = 8'h20; rom_array[11] = 8'h00;
    
    // Instruction 4: sub x4, x3, x2 (0x40218233)
    rom_array[12] = 8'h33; rom_array[13] = 8'h82;
    rom_array[14] = 8'h21; rom_array[15] = 8'h40;
    
    // Instruction 5: sw x3, 256(x0) (0x10302023)
    rom_array[16] = 8'h23; rom_array[17] = 8'h20;
    rom_array[18] = 8'h30; rom_array[19] = 8'h10;
    
    // Instruction 6: lw x5, 256(x0) (0x10002283)
    rom_array[20] = 8'h83; rom_array[21] = 8'h22;
    rom_array[22] = 8'h00; rom_array[23] = 8'h10;
    
    // Instruction 7: beq x3, x5, 8 (0x00518463)
    rom_array[24] = 8'h63; rom_array[25] = 8'h84;
    rom_array[26] = 8'h51; rom_array[27] = 8'h00;
    
    // Instruction 8: addi x6, x0, 99 (0x06300313)
    rom_array[28] = 8'h13; rom_array[29] = 8'h03;
    rom_array[30] = 8'h30; rom_array[31] = 8'h06;
    
    // Instruction 9: addi x7, x0, 100 (0x06400393) - target của branch
    rom_array[32] = 8'h93; rom_array[33] = 8'h03;
    rom_array[34] = 8'h40; rom_array[35] = 8'h06;
    
    // Instruction 10: jal x0, -16 (0xff0000ef) - loop back để test
    rom_array[36] = 8'hef; rom_array[37] = 8'h00;
    rom_array[38] = 8'h00; rom_array[39] = 8'hff;
    
end


always_comb begin

	logic [31:0] mapped_addr;
    
    // Map address về instruction memory base
    if (A >= 32'hbfc00000 && A < 32'hbfc01000) begin
        mapped_addr = A - 32'hbfc00000;  // Map về 0x00000000
    end else if (A >= 32'h00000000 && A < 32'h00001000) begin
        mapped_addr = A;  // Giữ nguyên nếu trong range
    end else begin
        mapped_addr = 32'h00000000;  // Default về 0
    end
	
    addr = mapped_addr[11:0] & 12'hFFC;
	// big-endian
    //RD = {rom_array[addr], rom_array[addr+1], rom_array[addr+2], rom_array[addr+3]};
	
	// little-endian
	if (addr <= 12'd4092) begin  // 4095 - 3 = 4092
		RD = {rom_array[addr+3], rom_array[addr+2], rom_array[addr+1], rom_array[addr]};
//		RD = {rom_array[addr], rom_array[addr+1], rom_array[addr+2], rom_array[addr+3]};
	end else begin
		RD = 32'h00000000;
	end

end
    
endmodule

