`include "config.v"

module id(
    input wire rst,
    input wire [`AddrLen - 1 : 0] pc,
    input wire [`InstLen - 1 : 0] inst,
    input wire [`RegLen - 1 : 0] reg1_data_i,
    input wire [`RegLen - 1 : 0] reg2_data_i,
	
	input wire loading,
	input wire [`RegLen - 1 : 0] ex_rd_data,
    input wire [`RegAddrLen - 1 : 0] ex_rd_addr,
    input wire ex_rd_enable,
	input wire [`RegLen - 1 : 0] mem_rd_data,
	input wire [`RegAddrLen - 1 : 0] mem_rd_addr,
	input wire mem_rd_enable,

    //To Register
    output reg [`RegAddrLen - 1 : 0] reg1_addr_o,
    output reg reg1_read_enable,
    output reg [`RegAddrLen - 1 : 0] reg2_addr_o,
    output reg reg2_read_enable,

    //To next stage
	output reg [`AddrLen - 1 : 0] pc_o,
    output reg [`RegLen - 1 : 0] reg1,
    output reg [`RegLen - 1 : 0] reg2,
    output reg [`RegLen - 1 : 0] Imm,
    output reg [`RegAddrLen - 1 : 0] rd,
    output reg rd_enable,
    output reg [`OpCodeLen - 1 : 0] aluop,
    output reg [`OpSelLen - 1 : 0] alusel,
	output wire stall_id
    );

    wire [`OpLen - 1 : 0] opcode = inst[`OpLen - 1 : 0];
	wire [2:0] opc = inst[14:12];
	reg stall_r1;
	reg stall_r2;
    
	assign stall_id = stall_r1 | stall_r2;
//Decode: Get opcode, imm, rd, and the addr of rs1&rs2
always @ (*) begin
    if (rst == 1) begin
        reg1_addr_o = `ZeroWord;
        reg2_addr_o = `ZeroWord;
    end
    else begin
        reg1_addr_o = inst[19 : 15];
        reg2_addr_o = inst[24 : 20];
    end
end
always @(*) begin
    Imm = `ZeroWord;
    rd_enable = 0;
    reg1_read_enable = 0;
    reg2_read_enable = 0;
    rd = `ZeroWord; 
    aluop = `NOP;
    alusel = `NOP_SEL;
	pc_o = pc;
    if (opcode == `ORI) begin
		case (opc)
			3'b000: begin //ADDI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_ADD;
				alusel = `ARITH_OP;
			end
			3'b010: begin //SLTI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_SLT;
				alusel = `ARITH_OP;
			end
			3'b011: begin //SLTIU
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_SLTU;
				alusel = `ARITH_OP;
			end
			3'b100: begin //XORI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_XOR;
				alusel = `LOGIC_OP;
			end
			3'b110: begin //ORI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_OR;
				alusel = `LOGIC_OP;
			end
			3'b111: begin //ANDI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_AND;
				alusel = `LOGIC_OP;
			end
			3'b001: begin //SLLI
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_SLL;
				alusel = `SHIFT_OP;
			end
			3'b101: begin 
				if (inst[31:25] == 7'b0000000) begin //SRLI
					Imm = { {20{inst[31]}} ,inst[31:20] };
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 0;
					rd = inst[11:7];
					aluop = `EXE_SRL;
					alusel = `SHIFT_OP;
				end
				else if (inst[31:25] == 7'b0100000) begin //SRAI
					Imm = { {20{inst[31]}} ,inst[31:20] };
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 0;
					rd = inst[11:7];
					aluop = `EXE_SRA;
					alusel = `SHIFT_OP;
				end
			end
		endcase
	end
	else if(opcode == `OR) begin
		case (opc)
			3'b000: begin
				if (inst[31:25] == 7'b0000000) begin //ADD
					Imm = `ZeroWord;
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 1;
					rd = inst[11:7];
					aluop = `EXE_ADD;
					alusel = `ARITH_OP;
				end
				else if (inst[31:25] == 7'b0100000) begin //SUB
					Imm = `ZeroWord;
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 1;
					rd = inst[11:7];
					aluop = `EXE_SUB;
					alusel = `ARITH_OP;
				end
			end
			3'b001: begin //SLL
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_SLL;
				alusel = `SHIFT_OP;
			end
			3'b010: begin //SLT
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_SLT;
				alusel = `ARITH_OP;
			end
			3'b011: begin //SLTU
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_SLTU;
				alusel = `ARITH_OP;
			end
			3'b100: begin //XOR
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_XOR;
				alusel = `LOGIC_OP;
			end
			3'b101: begin 
				if (inst[31:25] == 7'b0000000) begin //SRL
					Imm = `ZeroWord;
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 1;
					rd = inst[11:7];
					aluop = `EXE_SRL;
					alusel = `SHIFT_OP;
				end
				else if (inst[31:25] == 7'b0100000) begin //SRA
					Imm = `ZeroWord;
					rd_enable = 1;
					reg1_read_enable = 1;
					reg2_read_enable = 1;
					rd = inst[11:7];
					aluop = `EXE_SRA;
					alusel = `SHIFT_OP;
				end
			end
			3'b110: begin //OR
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_OR;
				alusel = `LOGIC_OP;
			end
			3'b111: begin //AND
				Imm = `ZeroWord;
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = inst[11:7];
				aluop = `EXE_AND;
				alusel = `LOGIC_OP;
			end
		endcase
	end
	else if(opcode == `LB) begin
		case (opc)
			3'b000: begin //LB
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_LB;
				alusel = `LS_OP;
			end
			3'b001: begin //LH
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_LH;
				alusel = `LS_OP;
			end
			3'b010: begin //LW
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_LW;
				alusel = `LS_OP;
			end
			3'b100: begin //LBU
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_LBU;
				alusel = `LS_OP;
			end
			3'b101: begin //LHU
				Imm = { {20{inst[31]}} ,inst[31:20] };
				rd_enable = 1;
				reg1_read_enable = 1;
				reg2_read_enable = 0;
				rd = inst[11:7];
				aluop = `EXE_LHU;
				alusel = `LS_OP;
			end
		endcase
	end
	else if(opcode == `SB) begin
		case (opc)
			3'b000: begin //SB
				Imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7] };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_SB;
				alusel = `LS_OP;
			end
			3'b001: begin //SH
				Imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7] };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_SH;
				alusel = `LS_OP;
			end
			3'b010: begin //SW
				Imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7] };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_SW;
				alusel = `LS_OP;
			end
		endcase
	end
	else if(opcode == `BEQ) begin
		case (opc)
			3'b000: begin //BEQ
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BEQ;
				alusel = `NOP_SEL;
			end
			3'b001: begin //BNE
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BNE;
				alusel = `NOP_SEL;
			end
			3'b100: begin //BLT
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BLT;
				alusel = `NOP_SEL;
			end
			3'b101: begin //BGE
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BGE;
				alusel = `NOP_SEL;
			end
			3'b110: begin //BLTU
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BLTU;
				alusel = `NOP_SEL;
			end
			3'b111: begin //BGEU
				Imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8] ,1'b0 };
				rd_enable = 0;
				reg1_read_enable = 1;
				reg2_read_enable = 1;
				rd = 5'b00000;
				aluop = `EXE_BGEU;
				alusel = `NOP_SEL;
			end
		endcase
	end
	else if(opcode == `LUI) begin
		Imm = { inst[31:12],12'h0 };
		rd_enable = 1;
		reg1_read_enable = 0;
		reg2_read_enable = 0;
		rd = inst[11:7];
		aluop = `EXE_LUI;
		alusel = `LOGIC_OP;
	end
	else if(opcode == `AUIPC) begin
		Imm = { inst[31:12],12'h0 };
		rd_enable = 1;
		reg1_read_enable = 0;
		reg2_read_enable = 0;
		rd = inst[11:7];
		aluop = `EXE_AUIPC;
		alusel = `ARITH_OP;
	end
	else if(opcode == `JAL) begin
		Imm = { {11{inst[31]}} ,inst[31],inst[19:12],inst[20],inst[30:21],1'b0 };
		rd_enable = 1;
		reg1_read_enable = 0;
		reg2_read_enable = 0;
		rd = inst[11:7];
		aluop = `EXE_JAL;
		alusel = `JAL_OP;
	end
	else if(opcode == `JALR) begin
		Imm = { {20{inst[31]}} ,inst[31:20] };
		rd_enable = 1;
		reg1_read_enable = 1;
		reg2_read_enable = 0;
		rd = inst[11:7];
		aluop = `EXE_JALR;
		alusel = `JAL_OP;
	end
end

//Get rs1
always @ (*) begin
	stall_r1 = 0;
    if (rst == 1) begin
        reg1 = `ZeroWord;
    end
	else if (loading == 1 && ex_rd_addr == reg1_addr_o) begin
        reg1 = `ZeroWord;
		stall_r1 = 1;
    end	
    else if (reg1_read_enable == 0) begin
        reg1 = `ZeroWord;
    end
	else if (reg1_addr_o == 5'b00000) begin
        reg1 = `ZeroWord;
    end
	else if (ex_rd_enable == 1 && ex_rd_addr == reg1_addr_o) begin
        reg1 = ex_rd_data;
    end
	else if (mem_rd_enable == 1 && mem_rd_addr == reg1_addr_o) begin
        reg1 = mem_rd_data;
    end
    else begin
        reg1 = reg1_data_i;
    end
end

//Get rs2
always @ (*) begin
	stall_r2 = 0;
    if (rst == 1) begin
        reg2 = `ZeroWord;
    end
	else if (loading == 1 && ex_rd_addr == reg2_addr_o) begin
        reg2 = `ZeroWord;
		stall_r2 = 1;
    end	
    else if (reg2_read_enable == 0) begin
        reg2 = Imm;
    end
	else if (reg2_addr_o == 5'b00000) begin
        reg2 = `ZeroWord;
    end
	else if (ex_rd_enable == 1 && ex_rd_addr == reg2_addr_o) begin
        reg2 = ex_rd_data;
    end
	else if (mem_rd_enable == 1 && mem_rd_addr == reg2_addr_o) begin
        reg2 = mem_rd_data;
    end
    else begin
        reg2 = reg2_data_i;
    end
end

endmodule
