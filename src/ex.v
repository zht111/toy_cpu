`include "config.v"

module ex(
    input wire rst,

	input wire [`AddrLen - 1 : 0] pc,
    input wire [`RegLen - 1 : 0] reg1,
    input wire [`RegLen - 1 : 0] reg2,
    input wire [`RegLen - 1 : 0] Imm,
    input wire [`RegAddrLen - 1 : 0] rd,
    input wire rd_enable,
    input wire [`OpCodeLen - 1 : 0] aluop,
    input wire [`OpSelLen - 1 : 0] alusel,

	output reg [`OpCodeLen - 1 : 0] aluop_o,
	output reg jumpEnable,
	output reg [`AddrLen - 1 : 0] jumpAddress,
    output reg [`RegLen - 1 : 0] rd_data_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr,
    output reg rd_enable_o,
	output reg [`AddrLen - 1 : 0] mem_addr_o,
	output reg [`AddrLen - 1 : 0] pc_o,
	output reg loading
    );

    reg [`RegLen - 1 : 0] res_logic;
	reg [`RegLen - 1 : 0] res_shift;
	reg [`RegLen - 1 : 0] res_arith;

    //Do the calculation
    always @ (*) begin //logic
        if (rst == 1) begin
            res_logic = `ZeroWord;
        end
        else begin
            case (aluop)
                `EXE_OR: begin
                    res_logic = reg1 | reg2;
				end
				`EXE_XOR: begin
                    res_logic = reg1 ^ reg2;
				end
				`EXE_AND: begin
                    res_logic = reg1 & reg2;
				end
				`EXE_LUI: begin
                    res_logic = Imm;
				end
                default: begin
                    res_logic = `ZeroWord;
				end
            endcase
        end
    end
	
	always @ (*) begin //shift
        if (rst == 1) begin
            res_shift = `ZeroWord;
        end
        else begin
            case (aluop)
				`EXE_SLL: begin
                    res_shift = reg1 << (reg2[4:0]);
				end
				`EXE_SRL: begin
                    res_shift = reg1 >> (reg2[4:0]);
				end
				`EXE_SRA: begin
                    res_shift = (reg1 >> (reg2[4:0])) | ({32{reg1[31]}} << (6'd32 - {1'b0,reg2[4:0]}));
				end
                default: begin
                    res_shift = `ZeroWord;
				end
            endcase
        end
    end
	
	always @ (*) begin //arith
        if (rst == 1) begin
            res_arith = `ZeroWord;
        end
        else begin
            case (aluop)
				`EXE_ADD: begin
                    res_arith = reg1 + reg2;
				end
				`EXE_SUB: begin
                    res_arith = reg1 - reg2;
				end
				`EXE_SLT: begin
                    res_arith = $signed(reg1) < $signed(reg2);
				end
				`EXE_SLTU: begin
                    res_arith = reg1 < reg2;
				end
				`EXE_AUIPC: begin
                    res_arith = pc + Imm;
				end
                default: begin
                    res_arith = `ZeroWord;
				end
            endcase
        end
    end
	
	always @ (*) begin //jal&branch
		jumpEnable = 0;
		jumpAddress = `ZeroWord;
        if (rst == 1) begin end
        else begin
            case (aluop)
				`EXE_JAL: begin
					jumpEnable = 1;
					jumpAddress = pc + Imm;
				end
				`EXE_JALR: begin
					jumpEnable = 1;
					jumpAddress = {reg1[31:1]+Imm[31:1], 1'b0};
				end
				`EXE_BGE: begin
					if ($signed(reg1) >= $signed(reg2)) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
				`EXE_BGEU: begin
					if (reg1 >= reg2) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
				`EXE_BLT: begin
					if ($signed(reg1) < $signed(reg2)) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
				`EXE_BLTU: begin
					if (reg1 < reg2) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
				`EXE_BEQ: begin
					if (reg1 == reg2) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
				`EXE_BNE: begin
					if (reg1 != reg2) begin
						jumpEnable = 1;
						jumpAddress = pc + Imm;
					end else begin end			
				end
                default: begin end
            endcase
        end
    end
	
	always @ (*) begin //l&s
        if (rst == 1) begin
            mem_addr_o = `ZeroWord;
			loading = 0;
        end
        else begin
            case (aluop)
                `EXE_SB: begin
					mem_addr_o = reg1 + Imm;
					loading = 0;
				end
				`EXE_SH: begin
					mem_addr_o = reg1 + Imm;
					loading = 0;
				end
				`EXE_SW: begin
					mem_addr_o = reg1 + Imm;
					loading = 0;
				end
				`EXE_LB: begin
					mem_addr_o = reg1 + Imm;
					loading = 1;
				end
				`EXE_LH: begin
					mem_addr_o = reg1 + Imm;
					loading = 1;
				end
				`EXE_LW: begin
					mem_addr_o = reg1 + Imm;
					loading = 1;
				end
				`EXE_LBU: begin
					mem_addr_o = reg1 + Imm;
					loading = 1;
				end
				`EXE_LHU: begin
					mem_addr_o = reg1 + Imm;
					loading = 1;
				end
				default: begin
					mem_addr_o = `ZeroWord;
					loading = 0;
				end
            endcase
        end
    end
	
    //Determine the output
    always @ (*) begin
        if (rst == 1) begin
            rd_enable_o = 0;
        end
        else begin 
			pc_o = pc;
            rd_addr = rd;
            rd_enable_o = rd_enable;
            case (alusel)
                `LOGIC_OP: begin
                    rd_data_o = res_logic; 
					aluop_o = `NOP;
				end
				`SHIFT_OP: begin
                    rd_data_o = res_shift; 
					aluop_o = `NOP;
				end
				`ARITH_OP: begin
                    rd_data_o = res_arith;
					aluop_o = `NOP;
				end
				`JAL_OP: begin
                    rd_data_o = pc + 4;
					aluop_o = `NOP;
				end
				`LS_OP: begin
                    rd_data_o = reg2;
					aluop_o = aluop;
				end
                default: begin
                    rd_data_o = `ZeroWord;
					aluop_o = `NOP;
				end
            endcase
			if(rd_enable == 1 && rd_addr == 5'b00000) rd_data_o = `ZeroWord;
        end
    end
endmodule
