`timescale 1ns / 1ps
`include "config.v"

module pc_reg(
    input wire clk,
    input wire rst,
	input wire [4:0] stall,
	input wire jumpEnable,
	input wire [31:0] jumpAddress,
    output reg [31:0] pc,
	output reg jump
);
	
always @ (posedge clk) begin
    if (rst == 1) begin
        pc <= `ZeroWord;
		jump <= 0;
    end
	else if (stall[1] == 1) begin end
    else if (jumpEnable == 1) begin 
			pc <= jumpAddress;
			jump <= 1;
		end	
	else if (stall[0] == 1) begin end
	else begin
		pc <= pc + 4;
		jump <= 0;
	end
end

endmodule