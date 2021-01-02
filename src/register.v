`include "config.v"

module register(
    input wire clk,
    input wire rst,
	
	input wire [`AddrLen - 1 : 0] write_pc,
    //write
    input wire write_enable,
    input wire [`RegAddrLen - 1 : 0] write_addr,
    input wire [`RegLen - 1 : 0] write_data,
    //read 1
    input wire read_enable1,   
    input wire [`RegAddrLen - 1 : 0] read_addr1,
    output reg [`RegLen - 1 : 0] read_data1,
    //read 2
    input wire read_enable2,   
    input wire [`RegAddrLen - 1 : 0] read_addr2,
    output reg [`RegLen - 1 : 0] read_data2
    );
    
    reg[`RegLen - 1 : 0] regs[`RegNum - 1 : 0];
    integer i;
	
//write 1
always @ (posedge clk) begin
	if (rst == 1) begin
        for (i = 0; i < `RegNum; i = i + 1)
            regs[i] = `ZeroWord;
    end
	else if (rst == 0 && write_enable == 1) begin
        if (write_addr != 5'h0) //not zero register
            regs[write_addr] <= write_data;
    end
end

//read 1
always @ (*) begin
    if (rst == 0 && read_enable1 == 1) begin
        if (read_addr1 == 5'h0)
            read_data1 = `ZeroWord;
        else if (read_addr1 == write_addr && write_enable == 1)
            read_data1 = write_data;
        else
            read_data1 = regs[read_addr1];
    end
    else begin
        read_data1 = `ZeroWord;
    end
end

//read 2
always @ (*) begin
    if (rst == 0 && read_enable2 == 1) begin
        if (read_addr2 == 5'h0)
            read_data2 = `ZeroWord;
        else if (read_addr2 == write_addr && write_enable == 1)
            read_data2 = write_data;
        else
            read_data2 = regs[read_addr2];
    end
    else begin
        read_data2 = `ZeroWord;
    end
end

endmodule
