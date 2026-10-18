`timescale 1ns / 1ps

module ass_uart_rf(
    input   clk, rstb, we,
    input   [6:0]   addr,
    input   [7:0]   wdata,

    output  [7:0]   rdata
);

parameter register_width = 8;
parameter register_depth = 128;

reg [register_width-1:0]   Register_block  [0:register_depth-1];
reg [7:0]   reg_out;

integer i;

always@(posedge clk or negedge rstb) begin
    if(!rstb) begin                                         //'for' is possible in verilog 2001
        for (i = 0; i < register_depth; i = i + 1) begin    
            Register_block[i] <= {register_width{1'b0}};    //'0' is repeated register_width times, and {1'b0}register_width (X) register_width{1'b0} (O)
        end
    end   
    else if(we) begin
        Register_block[addr] <= wdata;
        reg_out <= Register_block[addr];
    end
    else begin
        reg_out <= Register_block[addr];
    end
end

assign rdata = reg_out;

endmodule