`timescale 1ns / 1ps

module stallbus(
    input wire rst,
	input wire rdy,
    input wire stall_if,
	input wire stall_id,
	input wire stall_mem,
    output reg [4:0] stall);
    
always @ (*) begin
    //if (rst == 1 || rdy == 0) begin
	if (rst == 1) begin
        stall = 5'b11111;
	end
    else if (stall_mem == 1) begin
        stall = 5'b01111;
		end
	else if (stall_id == 1) begin
        stall = 5'b00011;
		end
	else if (stall_if == 1) begin
        stall = 5'b00001;
		end
	else begin
        stall = 5'b00000;
		end
end
endmodule
