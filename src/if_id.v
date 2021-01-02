`include "config.v"

module if_id(
    input wire clk, 
    input wire rst,
	input wire [4:0] stall,
	input wire clear,
    input wire [`AddrLen - 1 : 0] if_pc,
    input wire [`InstLen - 1 : 0] if_inst,
    output reg [`AddrLen - 1 : 0] id_pc,
    output reg [`InstLen - 1 : 0] id_inst);
    
always @ (posedge clk) begin
    if (rst == 1) begin
        id_pc <= `ZeroWord;
        id_inst <= `ZeroWord;
    end
	else if (stall[1] == 1) begin end
	else if (clear == 1) begin
        id_pc <= `ZeroWord;
        id_inst <= `ZeroWord;
	end
    else begin
        id_pc <= if_pc;
        id_inst <= if_inst;
    end
end
endmodule
