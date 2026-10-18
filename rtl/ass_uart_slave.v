`timescale 1ns / 1ps

module ass_uart_slave(
    input           clk,
    input           rstb,
    input           ser_in,
    input   [6:0]   dev_adr,

    output          ser_out
);
wire            we;
wire    [6:0]   addr;
wire    [7:0]   wdata;
wire    [7:0]   rdata;

ass_uart_serdes u_ass_uart_serdes(
    .clk(clk),
    .rstb(rstb),
    .ser_in(ser_in),
    .dev_adr(dev_adr),
    .rdata(rdata),
    .we(we),
    .addr(addr),
    .wdata(wdata),
    .ser_out(ser_out)
);

ass_uart_rf u_ass_uart_rf(
    .clk(clk),
    .rstb(rstb),
    .we(we),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata)
);

endmodule