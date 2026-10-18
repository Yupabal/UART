
`ifndef __uart_header__
`define __uart_header__

`define PARITY_OFF    1'b0
`define PARITY_ON     1'b1
`define PARITY_ODD    1'b0
`define PARITY_EVEN   1'b1
`define NSTOPS_1      1'b0
`define NSTOPS_2      1'b1
`define BAUD_115200   3'b000
`define BAUD_38400    3'b001
`define BAUD_28800    3'b010
`define BAUD_19200    3'b011
`define BAUD_9600     3'b100
`define BAUD_4800     3'b101
`define BAUD_2400     3'b110
`define BAUD_1200     3'b111
`define NBITS_7       1'b0
`define NBITS_8       1'b1
// constants for status from get_serial task
`define RECEIVE_RESULT_OK     4'b1000
`define RECEIVE_RESULT_FALSESTART 4'b0001
`define RECEIVE_RESULT_BADPARITY  4'b0010
`define RECEIVE_RESULT_BADSTOP    4'b0100

`endif // __uart_header__