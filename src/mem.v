`include "config.v"

module mem(
    input wire rst,
	input wire [`RegLen - 1 : 0] rd_data_i,
    input wire [`RegAddrLen - 1 : 0] rd_addr_i,
    input wire rd_enable_i,
	input wire[`OpCodeLen - 1 : 0] aluop_i,
	input wire [31:0] mem_addr_i,
	input wire ram_done,
	input wire [31:0] ram_r_data,
	input wire [`AddrLen - 1 : 0] pc,
	
	output reg [`AddrLen - 1 : 0] pc_o,
    output reg [`RegLen - 1 : 0] rd_data_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr_o,
    output reg rd_enable_o,

    output reg          ram_r_req_o,
    output reg          ram_w_req_o,
    output reg [31:0] 	ram_addr_o,
    output reg [31:0]   ram_w_data_o,
    output reg [1:0]    ram_state,
    output reg          stall_mem
);

always @ (*) begin
    if (rst == 1) begin
        ram_r_req_o 	= 0;
        ram_w_req_o 	= 0;
        ram_w_data_o	= `ZeroWord;
        ram_addr_o  	= `ZeroWord;
        ram_state   	= 2'h0;
        stall_mem    	= 0;	
		rd_data_o		= `ZeroWord;
        rd_addr_o		= 5'h0;
        rd_enable_o		= 0;
		pc_o			= `ZeroWord;
    end
	else begin
		pc_o			= pc;
        rd_data_o		= rd_data_i;
        rd_addr_o		= rd_addr_i;
        rd_enable_o		= rd_enable_i;
		case (aluop_i)
			`EXE_SB: begin
                ram_r_req_o     = 0;
                ram_w_req_o     = 1;
				ram_w_data_o    = rd_data_i;
                ram_addr_o      = mem_addr_i;
                ram_state       = 2'b00;
                stall_mem       = !ram_done;
            end
			`EXE_SH: begin
                ram_r_req_o     = 0;
                ram_w_req_o     = 1;
				ram_w_data_o    = rd_data_i;
                ram_addr_o      = mem_addr_i;
                ram_state       = 2'b01;
                stall_mem       = !ram_done;
            end
			`EXE_SW: begin
                ram_r_req_o     = 0;
                ram_w_req_o     = 1;
				ram_w_data_o    = rd_data_i;
                ram_addr_o      = mem_addr_i;
                ram_state       = 2'b11;
                stall_mem       = !ram_done;
            end
			`EXE_LW: begin
                ram_r_req_o     = 1;
                ram_w_req_o     = 0;
                ram_w_data_o    = `ZeroWord;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = ram_r_data;
                ram_state       = 2'b11;
                stall_mem       = !ram_done;
            end
			`EXE_LH: begin
                ram_r_req_o     = 1;
                ram_w_req_o     = 0;
                ram_w_data_o    = `ZeroWord;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {{16{ram_r_data[7]}},ram_r_data[15:0]};
                ram_state       = 2'b01;
                stall_mem       = !ram_done;
            end
			`EXE_LHU: begin
                ram_r_req_o     = 1;
                ram_w_req_o     = 0;
                ram_w_data_o    = `ZeroWord;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {16'b0,ram_r_data[15:0]};
                ram_state       = 2'b01;
                stall_mem       = !ram_done;
            end
			`EXE_LB: begin
                ram_r_req_o     = 1;
                ram_w_req_o     = 0;
                ram_w_data_o    = `ZeroWord;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {{24{ram_r_data[7]}},ram_r_data[7:0]};
                ram_state       = 2'b00;
                stall_mem       = !ram_done;
            end
			`EXE_LBU: begin
                ram_r_req_o     = 1;
                ram_w_req_o     = 0;
                ram_w_data_o    = `ZeroWord;
                ram_addr_o      = mem_addr_i;
                rd_data_o       =  {24'b0,ram_r_data[7:0]};
                ram_state       = 2'b00;
                stall_mem       = !ram_done;
            end
			default: begin
				ram_r_req_o 	= 0;
				ram_w_req_o 	= 0;
				ram_w_data_o	= `ZeroWord;
				ram_addr_o  	= `ZeroWord;
				ram_state   	= 2'b00;
				stall_mem    	= 0;
			end
		endcase
    end
end

endmodule