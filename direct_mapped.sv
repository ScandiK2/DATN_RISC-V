module direct_mapped #(
    parameter DATA_WIDTH = 32,
    parameter CACHE_LENGTH = 8,
    parameter TAG_WIDTH = 27,
    parameter SET_WIDTH = 3
)(
    input logic [DATA_WIDTH-1:0] address,
    input logic clk,
    input logic [DATA_WIDTH-1:0] datain,
    input logic WE,
	input logic reset, // Thêm reset signal
    output logic hit,
    output logic [DATA_WIDTH-1:0] dataout
);

// // if it is a read cycle then a hit then a read from cache is initiated
// //  If it is a miss, then the hardware must go and fetch the data from the next level of the memory hierarchy and fill the
// cache with it.
// y, if the operation is a write, it must write to the cache
// AND to the next level of memory hierarch (i.e. in this case, the main
// memory).


logic valids [CACHE_LENGTH-1:0];
logic [TAG_WIDTH-1:0] tags [CACHE_LENGTH-1:0];
logic [DATA_WIDTH-1:0] data [CACHE_LENGTH-1:0];

logic [SET_WIDTH-1:0] currentSet;
logic [TAG_WIDTH-1:0] currentTag;

always_comb begin
    currentSet = address[SET_WIDTH+1:2];
    currentTag = address[DATA_WIDTH-1:SET_WIDTH+2];
    hit = (valids[currentSet] && currentTag == tags[currentSet]);

    if(hit) dataout = data[currentSet];
	else dataout = 32'h00000000;  // Default value khi miss
end

// writing to cache
always_ff @(posedge clk) begin
	// Them reset de khoi tao cache
		if (reset) begin
        for (int i = 0; i < CACHE_LENGTH; i++) begin
            valids[i] <= 1'b0;
            tags[i] <= '0;
            data[i] <= '0;
			end
	end
    if(WE)begin 
        data[currentSet] <= datain;
        valids[currentSet] <= 1;
        tags[currentSet] <= currentTag;
    end
end


// V bit + tag + 32 bits data
endmodule
