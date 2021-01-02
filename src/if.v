`include "config.v"

module IF(
    input wire clk,
    input wire rst,
    input wire [`AddrLen - 1 : 0] pc_i,
	input wire inst_ok,
	input wire [`InstLen - 1 : 0] inst_i,
	input wire [`AddrLen - 1 : 0] inst_pc,
	
	output reg [`AddrLen - 1 : 0] pc_o,
    output reg [`InstLen - 1 : 0] inst_o,
    output reg inst_fe,
    output reg [`AddrLen - 1 : 0] nxt_pc,
	output reg stall_if
);

reg [31:0] tag[`CacheSize - 1:0];
reg [31:0] cache[`CacheSize - 1:0];

integer i;
always @ (posedge clk) begin
    if (rst) begin
		for (i = 0; i < `CacheSize; i = i + 1) begin
            tag[i] <= 32'hffffffff;
        end
        nxt_pc <= `ZeroWord;
    end
	else begin
        if (inst_ok) begin
			tag[inst_pc[9:2]] <= inst_pc;
			cache[inst_pc[9:2]] <= inst_i;
            nxt_pc  <= pc_i + 4;
        end
		else begin
            nxt_pc <= pc_i;
        end
	end
end

always @ (*) begin
	inst_fe = tag[nxt_pc[9:2]] != nxt_pc & ~inst_ok;
    if (rst) begin
        inst_o      = `ZeroWord;
        pc_o        = `ZeroWord;
        stall_if    = 0;
    end
	else if (tag[pc_i[9:2]] == pc_i) begin
        stall_if    = 0;
        inst_o      = cache[pc_i[9:2]];
        pc_o        = pc_i;
    end
	else if (inst_ok && inst_pc == pc_i) begin
        stall_if    = 0;
        inst_o      = inst_i;
        pc_o        = pc_i;
    end
	else begin
        stall_if    = 1;
        inst_o      = `ZeroWord;
        pc_o        = `ZeroWord;
    end
end

endmodule
