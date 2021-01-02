`include "config.v"

module id_ex(
    input wire clk,
    input wire rst,
	input wire [4:0] stall,
	input wire clear,
    input wire [`RegLen - 1 : 0] id_reg1,
    input wire [`RegLen - 1 : 0] id_reg2,
    input wire [`RegLen - 1 : 0] id_Imm,
    input wire [`RegAddrLen - 1 : 0] id_rd,
    input wire id_rd_enable,
    input wire [`OpCodeLen - 1 : 0] id_aluop,
    input wire [`OpSelLen - 1 : 0] id_alusel,
	input wire [`AddrLen - 1 : 0] id_pc,
	
	output reg [`AddrLen - 1 : 0] ex_pc,
    output reg [`RegLen - 1 : 0] ex_reg1,
    output reg [`RegLen - 1 : 0] ex_reg2,
    output reg [`RegLen - 1 : 0] ex_Imm,
    output reg [`RegAddrLen - 1 : 0] ex_rd,
    output reg ex_rd_enable,
    output reg [`OpCodeLen - 1 : 0] ex_aluop,
    output reg [`OpSelLen - 1 : 0] ex_alusel
    );

always @ (posedge clk) begin
    if (rst == 1) begin
		ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_Imm <= `ZeroWord;
        ex_rd <= 5'b00000;
        ex_rd_enable <= 0;
        ex_aluop <= `NOP;
        ex_alusel <= `NOP_SEL;
		ex_pc <= `ZeroWord;
    end
	else if (stall[2] == 1) begin end
	else if (clear == 1 || stall[1] == 1) begin
		ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_Imm <= `ZeroWord;
        ex_rd <= 5'b00000;
        ex_rd_enable <= 0;
        ex_aluop <= `NOP;
        ex_alusel <= `NOP_SEL;
		ex_pc <= `ZeroWord;
	end
    else begin
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_Imm <= id_Imm;
        ex_rd <= id_rd;
        ex_rd_enable <= id_rd_enable;
        ex_aluop <= id_aluop;
        ex_alusel <= id_alusel;
		ex_pc <= id_pc;
    end
end

endmodule
