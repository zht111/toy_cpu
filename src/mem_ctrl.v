`timescale 1ns / 1ps
`include "config.v"

module mem_ctrl (
    input wire clk,
    input wire rst, 
    input wire      	ram_r_req_i,
    input wire      	ram_w_req_i,
    input wire[31:0]	ram_addr_i,
    input wire[31:0]	ram_data_i,
    input wire[1:0] 	ram_state_i,
    input wire       	inst_fe,
    input wire[31:0]	nxt_pc,
    input wire[7:0]  	cpu_din,
	input wire			io_buffer_full,
	
    output reg[31:0] 	inst_o,
    output reg[31:0]	inst_pc,
    output reg			inst_ok,
    output reg       	ram_done_o,
    output reg[31:0] 	ram_data_o,  
    output reg[7:0]		cpu_dout,
    output reg[31:0]	cpu_mem_a,
    output reg        	cpu_mem_wr
);

reg[4:0]	stage;
reg[1:0]	Type;
reg[31:0]	ram_addr;
reg[31:0]	ram_data;
reg[31:0]	pred_pc;
reg[1:0]	wait_;

always @ (posedge clk) begin
    if (rst == 1) begin
        stage       <= 5'h0;
        ram_addr    <= `ZeroWord;
        ram_data    <= `ZeroWord;
        ram_data_o  <= `ZeroWord;
        cpu_mem_a   <= `ZeroWord;
        cpu_mem_wr  <= `Read;
        cpu_dout    <= 8'b00000000;
        Type        <= `NONE;
        inst_o      <= `ZeroWord;
        inst_pc     <= `ZeroWord;
        inst_ok     <= 0;
        ram_done_o  <= 0;
        pred_pc		<= 32'hffffffff;
		wait_		<= 2'h0;
    end
	else begin
		if (Type == `HCIO) begin
            ram_data    <= `ZeroWord;
            stage       <= 5'b10000;
            Type        <= `RAMO;
            pred_pc		<= 32'hffffffff;
			wait_ 		<= 2'h0;
        end
		else if (stage[4] == 1 && stage[3] == `Read) begin
            ram_done_o  <= 0;
            inst_ok     <= 0;
			wait_ 		<= 2'h0;
			
            if (Type == `INSR && inst_fe && nxt_pc != ram_addr) begin 
                ram_addr    <= nxt_pc;
                stage[4:0]  <= 5'b10100;
                cpu_mem_a   <= nxt_pc + 3;
                cpu_mem_wr  <= `Read;
                Type        <= `INSR;
            end else		
			begin
                case (stage[2:0])
                    3'h4: begin
                        cpu_mem_a	<= ram_addr + 2;
                        cpu_mem_wr	<= `Read;
                        stage[2:0]	<= 3'h3;
                    end
                    3'h3: begin
                        ram_data[31:24] <= cpu_din;
                        cpu_mem_a       <= ram_addr + 1;
                        cpu_mem_wr      <= `Read;
                        stage[2:0]      <= 3'h2;
                    end
                    3'h2: begin
                        ram_data[23:16] <= cpu_din;
                        cpu_mem_a       <= ram_addr + 0;
                        cpu_mem_wr      <= `Read;
                        stage[2:0]      <= 3'h1;
                    end
                    3'h1: begin
                        ram_data[15:8]  <= cpu_din;
                        if (Type == `INSR && nxt_pc == ram_addr) begin
                            pred_pc    	<= nxt_pc + 4;
                            cpu_mem_a   <= nxt_pc + 7;
                            cpu_mem_wr  <= `Read;
                        end else begin
                            pred_pc    	<= nxt_pc;
                            cpu_mem_a   <= nxt_pc + 3;
                            cpu_mem_wr  <= `Read;
                        end
                        stage[2:0]      <= 3'h0;
                    end
                    3'h0: begin
                        stage[4:0]      <= 5'h0;
                        if (Type == `INSR) begin
                            inst_pc     <= ram_addr;
                            inst_o      <= {ram_data[31:8],cpu_din};
                            inst_ok     <= 1;
                            if (!ram_r_req_i && !ram_w_req_i) begin
                                cpu_mem_wr      <= `Read;
                                Type            <= `INSR;
                                ram_addr        <= nxt_pc + 4;
                                if (pred_pc == nxt_pc + 4) begin
                                    cpu_mem_a       <= nxt_pc + 6;
                                    stage[4:0]      <= 5'b10011;
                                end else begin
                                    cpu_mem_a       <= nxt_pc + 7;
                                    stage[4:0]      <= 5'b10100;
                                end
                            end
                        end else begin
                            ram_done_o  <= 1;
                            ram_data_o  <= {ram_data[31:8],cpu_din};
                            if (inst_fe) begin
                                ram_addr        <= nxt_pc;
                                cpu_mem_wr      <= `Read;
                                Type            <= `INSR;
                                if (pred_pc == nxt_pc) begin
                                    stage[4:0]      <= 5'b10011;
                                    cpu_mem_a       <= nxt_pc + 2;
                                end else begin
                                    stage[4:0]      <= 5'b10100;
                                    cpu_mem_a       <= nxt_pc + 3;
                                end
                            end
                            else begin
                                cpu_mem_wr  <= `Read;
                                cpu_mem_a   <= `ZeroWord;
                            end
                        end
                    end
                endcase
            end
        end 
		else if (stage[4] == 1 && stage[3] == `Write) begin
            ram_done_o  <= 0;
            inst_ok     <= 0;
			if (io_buffer_full == 1) begin 
				wait_ 	<= 2'h1;
			end
			else if (wait_ == 2'h1) begin
				wait_ 	<= 2'h0;
			end 
			else begin
				if (ram_addr_i[17:16] == 2'b11) begin
					wait_ 	<= 2'h1;
				end
				case (stage[1:0])
					3'h3: begin
						cpu_dout    <= ram_data[23:16];
						cpu_mem_a   <= ram_addr + 2;
						cpu_mem_wr  <= `Write;
						stage[1:0]  <= 2'h2;
					end
					3'h2: begin
						cpu_dout    <= ram_data[15:8];
						cpu_mem_a   <= ram_addr + 1;
						cpu_mem_wr  <= `Write;
						stage[1:0]  <= 2'h1;
					end
					3'h1: begin
						cpu_dout    <= ram_data[7:0];
						cpu_mem_a   <= ram_addr + 0;
						cpu_mem_wr  <= `Write;
						stage[4:0]  <= 5'h0;
						ram_done_o  <= 1;
					end
				endcase
			end
        end
		else if (!ram_done_o && ram_r_req_i == 1) begin 
            ram_done_o  <= 0;
            inst_ok     <= 0;
			wait_ 		<= 2'h0;
            if (ram_addr_i[17:16] == 2'b11) begin
                ram_addr    <= ram_addr_i;
                cpu_mem_a   <= ram_addr_i;
                cpu_mem_wr  <= `Read;
                Type        <= `HCIO;
            end else begin
                ram_addr    <= ram_addr_i;
                cpu_mem_a   <= ram_addr_i + ram_state_i;
                cpu_mem_wr  <= `Read;
                Type        <= `RAMO;
                case (ram_state_i)
                    4'h3: begin
                        stage[4:0]  <= 5'b10100;
                    end
                    4'h1: begin
                        stage[4:0]  <= 5'b10010;
                    end
                    4'h0: begin
                        stage[4:0]  <= 5'b10001;
                    end
                endcase
            end
        end
		else if (!ram_done_o && ram_w_req_i == 1) begin
			ram_addr    <= `ZeroWord;
			ram_data    <= `ZeroWord;
			cpu_mem_a   <= `ZeroWord;
			cpu_dout	<= 8'h0;
			if (io_buffer_full == 1) begin 
				wait_ 	<= 2'h1;
			end
			else if (wait_ == 2'h1) begin
				wait_ 	<= 2'h0;
			end 
			else begin
				ram_done_o  <= 0;
				inst_ok     <= 0;
				ram_addr    <= ram_addr_i;
				ram_data    <= ram_data_i;
				cpu_mem_a   <= ram_addr_i + ram_state_i;
				cpu_mem_wr  <= `Write;
				Type        <= `RAMO;
			
				if (ram_addr_i[17:16] == 2'b11) begin
					wait_ 	<= 2'h1;
				end
				case (ram_state_i)
					4'h3: begin
						cpu_dout    <= ram_data_i[31:24];
						stage[4:0]  <= 5'b11011;
					end
					4'h1: begin
						cpu_dout    <= ram_data_i[15:8];
						stage[4:0]  <= 5'b11001;
					end
					4'h0: begin
						cpu_dout    <= ram_data_i[7:0];
						stage[4:0]  <= 5'h0;
						ram_done_o  <= 1;
					end
				endcase
			end
        end
		else if (!ram_r_req_i && !ram_w_req_i && inst_fe) begin
            ram_addr    <= nxt_pc;
            stage[4:0]  <= 5'b10100;
            cpu_mem_a   <= nxt_pc + 3;
            cpu_mem_wr  <= `Read;
            Type        <= `INSR;
            ram_done_o  <= 0;
            inst_ok     <= 0;
			wait_ 		<= 2'h0;
        end
		else begin
            cpu_mem_wr  <= `Read;
            cpu_mem_a   <= `ZeroWord;
            Type        <= `NONE;
            ram_done_o  <= 0;
            inst_ok     <= 0;
        end
    end
end
endmodule