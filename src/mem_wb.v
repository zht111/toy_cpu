`include "config.v"

module mem_wb(
	input clk,
	input rst,
	input wire [`RegLen - 1 : 0] mem_rd_data,
	input wire [`RegAddrLen - 1 : 0] mem_rd_addr,
	input wire mem_rd_enable,
	input wire [4:0] stall,
	input wire [`AddrLen - 1 : 0] mem_pc,
	
	output reg [`AddrLen - 1 : 0] wb_pc,
	output reg [`RegLen - 1 : 0] wb_rd_data,
	output reg [`RegAddrLen - 1 : 0] wb_rd_addr,
	output reg wb_rd_enable
	);

always @ (posedge clk) begin
    if (rst == 1) begin
        wb_rd_data <= `ZeroWord;
        wb_rd_addr <= 5'h0;
        wb_rd_enable <= 0;
		wb_pc <= `ZeroWord;
    end
    else begin
        wb_rd_data <= mem_rd_data;
        wb_rd_addr <= mem_rd_addr;
        wb_rd_enable <= mem_rd_enable;
		wb_pc <= mem_pc;
    end
end
endmodule
