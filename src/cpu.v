// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "config.v"

module cpu(
	input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

//PC -> IF/ID
wire [31:0] pc;
wire [31:0] if_pc;
wire [31:0] if_inst;

//IF/ID -> ID
wire [31:0] id_pc_i;
wire [31:0] id_inst_i;

//Register -> ID
wire [31:0] reg1_data;
wire [31:0] reg2_data;

//ID -> Register
wire [4:0] reg1_addr;
wire reg1_read_enable;
wire [4:0] reg2_addr;
wire reg2_read_enable;

//ID -> ID/EX
wire [31:0] id_pc_o;
wire [`OpCodeLen - 1:0] id_aluop;
wire [`OpSelLen - 1:0] id_alusel;
wire [`RegLen - 1:0] id_reg1, id_reg2, id_Imm;
wire [`RegAddrLen - 1:0] id_rd;
wire id_rd_enable;

//ID/EX -> EX
wire [31:0] ex_pc_i;
wire [`OpCodeLen - 1:0] ex_aluop;
wire [`OpSelLen - 1:0] ex_alusel;
wire [`RegLen - 1:0] ex_reg1, ex_reg2, ex_Imm;
wire [`RegAddrLen - 1:0] ex_rd;
wire ex_rd_enable_i;
wire ex_loading;

//EX -> EX/MEM
wire [`OpCodeLen - 1:0] ex_aluop_o;
wire [31:0] ex_rd_data;
wire [4:0] ex_rd_addr;
wire ex_rd_enable_o;

//EX/MEM -> MEM
wire [`OpCodeLen - 1:0] mem_aluop;
wire [31:0] mem_rd_data_i;
wire [4:0] mem_rd_addr_i;
wire mem_rd_enable_i;
wire [31:0] mem_addr;
wire [31:0] mem_mem_addr_i;

//MEM -> MEM/WB
wire [31:0] mem_rd_data_o;
wire [4:0] mem_rd_addr_o;
wire mem_rd_enable_o;

//MEM/WB -> Register
wire write_enable;
wire [4:0] write_addr;
wire [31:0] write_data;

// for debugging
wire [31:0] ex_pc_o;
wire [31:0] mem_pc_i;
wire [31:0] mem_pc_o;
wire [31:0] wb_pc;

wire [4:0] stall; // 4: mem/wb  3: ex/mem  2: id/ex  1: if/id  0: pc_reg
wire stall_if;
wire stall_id;
wire stall_mem;

wire id_jump;
wire jumpEnable;
wire [31:0] jumpAddress;

wire [31:0] inst_buffer;
wire ram_r_req;
wire ram_w_req;
wire [31:0] ram_addr;
wire [31:0] ram_w_data;
wire [1:0] ram_state;
wire inst_fe;
wire inst_ok;
wire [31:0] inst_pc;
wire [31:0] nxt_pc;
wire ram_done;
wire [31:0] ram_r_data;

wire rst;
assign rst = rst_in | (~rdy_in);
//assign rst = rst_in;

stallbus StallBus(
	.rst(rst),
	.rdy(rdy_in),
	.stall_if(stall_if),
	.stall_id(stall_id),
	.stall_mem(stall_mem),
	//output
	.stall(stall)
);

mem_ctrl MemCtrl(
	.clk(clk_in),
	.rst(rst),
	.ram_r_req_i(ram_r_req),
	.ram_w_req_i(ram_w_req),
	.ram_addr_i(ram_addr),
	.ram_data_i(ram_w_data),
	.ram_state_i(ram_state),
	.inst_fe(inst_fe),
	.nxt_pc(nxt_pc),
	.cpu_din(mem_din),
	.io_buffer_full(io_buffer_full),
	//output
	.inst_o(inst_buffer),
	.inst_pc(inst_pc),
	.inst_ok(inst_ok),
	.ram_done_o(ram_done),
	.ram_data_o(ram_r_data),
	.cpu_dout(mem_dout),
	.cpu_mem_a(mem_a),
	.cpu_mem_wr(mem_wr)
);

register Register(
	.clk(clk_in),
	.rst(rst),
	.write_pc(wb_pc),
	.write_enable(write_enable),
	.write_addr(write_addr),
	.write_data(write_data),
	.read_enable1(reg1_read_enable),
	.read_addr1(reg1_addr),
	.read_enable2(reg2_read_enable),
	.read_addr2(reg2_addr),
	//output
	.read_data1(reg1_data),
	.read_data2(reg2_data)
);

pc_reg PC_REG(
	.clk(clk_in),
	.rst(rst),
	.stall(stall),
	.jumpEnable(jumpEnable),
	.jumpAddress(jumpAddress),
	//output
	.pc(pc),
	.jump(id_jump)
);

IF If(
	.clk(clk_in),
	.rst(rst),
	.inst_i(inst_buffer),
	.pc_i(pc),
	.inst_ok(inst_ok),
	.inst_pc(inst_pc),
	//output
	.pc_o(if_pc),
    .inst_o(if_inst),
    .inst_fe(inst_fe),
    .nxt_pc(nxt_pc),
	.stall_if(stall_if)
);

if_id IF_ID(
	.clk(clk_in),
	.rst(rst),
	.if_pc(if_pc),
	.if_inst(if_inst),
	.stall(stall),
	.clear(jumpEnable),
	//output
	.id_pc(id_pc_i),
	.id_inst(id_inst_i)
);

id ID(
	.rst(rst),
	.pc(id_pc_i),
	.inst(id_inst_i),
	.reg1_data_i(reg1_data),
	.reg2_data_i(reg2_data), 
	.loading(ex_loading),
	.ex_rd_data(ex_rd_data),
	.ex_rd_addr(ex_rd_addr),
	.ex_rd_enable(ex_rd_enable_o),
	.mem_rd_data(mem_rd_data_o),
	.mem_rd_addr(mem_rd_addr_o),
	.mem_rd_enable(mem_rd_enable_o),
	//output
	.pc_o(id_pc_o),
	.reg1_addr_o(reg1_addr),
	.reg1_read_enable(reg1_read_enable),
	.reg2_addr_o(reg2_addr),
	.reg2_read_enable(reg2_read_enable),
	.reg1(id_reg1),
	.reg2(id_reg2),
	.Imm(id_Imm),
	.rd(id_rd),
	.rd_enable(id_rd_enable),
	.aluop(id_aluop),
	.alusel(id_alusel),
	.stall_id(stall_id)
);

id_ex ID_EX(
	.clk(clk_in),
	.rst(rst),
	.id_reg1(id_reg1),
	.id_reg2(id_reg2),
	.id_Imm(id_Imm),
	.id_rd(id_rd),
	.id_rd_enable(id_rd_enable),
	.id_aluop(id_aluop),
	.id_alusel(id_alusel),
	.id_pc(id_pc_o),
	.stall(stall),
	.clear(jumpEnable),
	//output
	.ex_pc(ex_pc_i),
	.ex_reg1(ex_reg1),
	.ex_reg2(ex_reg2),
	.ex_Imm(ex_Imm),
	.ex_rd(ex_rd),
	.ex_rd_enable(ex_rd_enable_i),
	.ex_aluop(ex_aluop),
	.ex_alusel(ex_alusel)
);

ex EX(
	.rst(rst),
	.pc(ex_pc_i),
	.reg1(ex_reg1),
	.reg2(ex_reg2),
	.Imm(ex_Imm),
	.rd(ex_rd),
	.rd_enable(ex_rd_enable_i),
	.aluop(ex_aluop),
	.alusel(ex_alusel),
	//output
	.aluop_o(ex_aluop_o),
	.jumpEnable(jumpEnable),
	.jumpAddress(jumpAddress),
	.rd_data_o(ex_rd_data),
	.rd_addr(ex_rd_addr),
	.rd_enable_o(ex_rd_enable_o),
	.loading(ex_loading),
	.pc_o(ex_pc_o),
	.mem_addr_o(mem_addr)
);
      
ex_mem EX_MEM(
	.clk(clk_in),
	.rst(rst),
	.ex_rd_data(ex_rd_data),
	.ex_rd_addr(ex_rd_addr),
	.ex_rd_enable(ex_rd_enable_o),
	.aluop_i(ex_aluop_o),
	.ex_mem_addr(mem_addr),
	.stall(stall),
	.ex_pc(ex_pc_o),
	//output
	.mem_pc(mem_pc_i),
	.aluop_o(mem_aluop),
	.mem_rd_data(mem_rd_data_i),
	.mem_rd_addr(mem_rd_addr_i),
	.mem_rd_enable(mem_rd_enable_i),
	.mem_mem_addr(mem_mem_addr_i)
);

mem MEM(
	.rst(rst),
	.rd_data_i(mem_rd_data_i),
	.rd_addr_i(mem_rd_addr_i),
	.rd_enable_i(mem_rd_enable_i),
	.mem_addr_i(mem_mem_addr_i),
	.aluop_i(mem_aluop),
	.ram_done(ram_done),
	.ram_r_data(ram_r_data),
	.pc(mem_pc_i),
	//output
	.pc_o(mem_pc_o),
	.rd_data_o(mem_rd_data_o),
	.rd_addr_o(mem_rd_addr_o),
	.rd_enable_o(mem_rd_enable_o),

	.ram_r_req_o(ram_r_req),
    .ram_w_req_o(ram_w_req),
    .ram_addr_o(ram_addr),
    .ram_w_data_o(ram_w_data),
    .ram_state(ram_state),
    .stall_mem(stall_mem)
);

mem_wb MEM_WB(
	.clk(clk_in),
	.rst(rst),
	.mem_rd_data(mem_rd_data_o),
	.mem_rd_addr(mem_rd_addr_o),
	.mem_rd_enable(mem_rd_enable_o),
	.stall(stall),
	.mem_pc(mem_pc_o),
	//output
	.wb_pc(wb_pc),
	.wb_rd_data(write_data),
	.wb_rd_addr(write_addr),
	.wb_rd_enable(write_enable)
);
endmodule