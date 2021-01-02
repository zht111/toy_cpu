`ifndef CONFIG
`define CONFIG

`define ZeroWord 32'h00000000
`define ResetEnable 1'b1
`define NOP 5'b00000
`define RegAddrLen 5
`define RegLen 32
`define RegNum 32
`define InstLen 32
`define AddrLen 32
`define RAM_SIZE 100
`define RAM_SIZELOG2 17
`define Read 1'b0
`define Write 1'b1
`define INSR 2'b01
`define RAMO 2'b10
`define HCIO 2'b11
`define NONE 2'b00
`define CacheSize 256

//OPCODE
`define OpLen 7
`define LUI		7'b0110111
`define AUIPC	7'b0010111
`define JAL		7'b1101111
`define JALR	7'b1100111

`define BEQ		7'b1100011
`define BNE		7'b1100011
`define BLT		7'b1100011
`define BGE		7'b1100011
`define BLTU	7'b1100011
`define BGEU	7'b1100011

`define LB		7'b0000011
`define LH		7'b0000011
`define LW		7'b0000011
`define LBU		7'b0000011
`define LHU		7'b0000011

`define SB		7'b0100011
`define SH		7'b0100011
`define SW		7'b0100011

`define ADDI	7'b0010011
`define SLTI	7'b0010011
`define SLTIU	7'b0010011
`define XORI	7'b0010011
`define ORI		7'b0010011
`define ANDI	7'b0010011
`define SLLI	7'b0010011
`define SRLI	7'b0010011
`define SRAI	7'b0010011

`define ADD		7'b0110011
`define SUB		7'b0110011
`define SLL		7'b0110011
`define SLT		7'b0110011
`define SLTU	7'b0110011
`define XOR		7'b0110011
`define SRL		7'b0110011
`define SRA		7'b0110011
`define OR		7'b0110011
`define AND		7'b0110011

//AluOP
`define OpCodeLen 5
`define EXE_NOP		5'h0
`define EXE_LUI		5'h1
`define EXE_AUIPC	5'h2
`define EXE_JAL		5'h3
`define EXE_JALR	5'h4
`define EXE_BEQ		5'h5
`define EXE_BNE		5'h6
`define EXE_BLT		5'h7
`define EXE_BGE		5'h8
`define EXE_BLTU	5'h9
`define EXE_BGEU	5'ha
`define EXE_LB		5'hb
`define EXE_LH		5'hc
`define EXE_LW		5'hd
`define EXE_LBU		5'he
`define EXE_LHU		5'hf
`define EXE_SB		5'h10
`define EXE_SH		5'h11
`define EXE_SW		5'h12
`define EXE_ADD		5'h13
`define EXE_SUB		5'h14
`define EXE_SLL		5'h15
`define EXE_SLT		5'h16
`define EXE_SLTU	5'h17
`define EXE_XOR		5'h18
`define EXE_SRL		5'h19
`define EXE_SRA		5'h1a
`define EXE_OR		5'h1b
`define EXE_AND		5'h1c

//AluSelect
`define OpSelLen 3
`define NOP_SEL		3'b000
`define LOGIC_OP	3'b001
`define SHIFT_OP	3'b010
`define ARITH_OP	3'b011
`define JAL_OP		3'b100
`define LS_OP		3'b101

`endif