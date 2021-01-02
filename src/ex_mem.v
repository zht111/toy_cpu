`include "config.v"

module ex_mem(
    input wire clk,
    input wire rst,
    input wire [`RegLen - 1 : 0] ex_rd_data,
    input wire [`RegAddrLen - 1 : 0] ex_rd_addr,
	input wire [`OpCodeLen - 1 : 0] aluop_i,
    input wire ex_rd_enable,
	input wire [`AddrLen - 1 : 0] ex_mem_addr,
	input wire [4:0] stall,
	input wire [`AddrLen - 1 : 0] ex_pc,
	
	output reg [`AddrLen - 1 : 0] mem_pc,
	output reg [`OpCodeLen - 1 : 0] aluop_o,
    output reg [`RegLen - 1 : 0] mem_rd_data,	
    output reg [`RegAddrLen - 1 : 0] mem_rd_addr,
	output reg [`AddrLen - 1 : 0] mem_mem_addr,
    output reg mem_rd_enable
    );

always @ (posedge clk) begin
    if (rst == 1) begin
        mem_rd_data <= `ZeroWord;
        mem_rd_addr <= 5'b00000;
		mem_mem_addr <= `ZeroWord;
        mem_rd_enable <= 0;
		mem_pc <= `ZeroWord;
		aluop_o <= `NOP;
    end
    else if(stall[3] == 0) begin
        mem_rd_data <= ex_rd_data;
        mem_rd_addr <= ex_rd_addr;
		mem_mem_addr <= ex_mem_addr;
        mem_rd_enable <= ex_rd_enable;
		mem_pc <= ex_pc;
		aluop_o <= aluop_i;
    end
end

endmodule
