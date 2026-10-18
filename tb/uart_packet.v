
`timescale 1ns / 10ps

`include "uart_define.v"

module uart_packet ( input clk);

wire [31:0] nonce[0:15];
wire [8*160-1:0] mem;
reg new_rx_data;
reg  [8*128-1:0] rfifo;

// ----------------------------------------------------------------------------------------------------------
// Write Packet
// ----------------------------------------------------------------------------------------------------------
task write_packet;
  input [7:0] dev_id;
  input [7:0] addr;
  input [7:0] len;
  integer i;
begin
  uart_master.send_serial(8'h00 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // START
  uart_master.send_serial(8'h20 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // WRITE
  uart_master.send_serial(dev_id, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // DEV_ID
  uart_master.send_serial(addr  , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // ADDR
  uart_master.send_serial(len   , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // Length
  for (i = addr; i < len+addr; i = i + 1) begin
    uart_master.send_serial(mem[8*i +: 8], `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
    $display("Write Reg[%0x] = %x", i, mem[8*i +: 8]);
  end
  #(`BAUD_115200);
  $display("Sending data is done... auto_inc");
end
endtask

// ----------------------------------------------------------------------------------------------------------
// Write a byte
// ----------------------------------------------------------------------------------------------------------
task write_byte;
  input [7:0] dev_id;
  input [7:0] addr;
  input [7:0] data;
begin
  uart_master.send_serial(8'h00 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // START
  uart_master.send_serial(8'h20 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // WRITE
  uart_master.send_serial(dev_id, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // DEV_ID
  uart_master.send_serial(addr  , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // ADDR
  uart_master.send_serial(8'h01 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // Length
  uart_master.send_serial(data  , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
  #(`BAUD_115200);
  $display("Sending data ... 1 byte");
end
endtask

// ----------------------------------------------------------------------------------------------------------
// Read Packet
// ----------------------------------------------------------------------------------------------------------
task read_packet;
  input  [  7:0] dev_id ;
  input  [  7:0] addr   ;
  input  [  7:0] len    ;
  output [127:0] dout  ;
  reg [127:0] rdata  ;
  reg [7:0] pos;
begin
  rdata = 128'b0;
  pos = addr;
  uart_master.send_serial(8'h00 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // START
  uart_master.send_serial(8'h10 , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // READ
  uart_master.send_serial(dev_id, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // DEV_ID
  uart_master.send_serial(addr  , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // ADDR
  uart_master.send_serial(len   , `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); // Length
  repeat(len) begin
    @(posedge new_rx_data) rdata = {rdata[8*0 +: 15*8], uart_master.get_serial_data};
    $display(" Reg[%0x] = %x", pos, uart_master.get_serial_data);
    pos = pos + 1;
  end
  #(`BAUD_115200);
  dout = rdata;
  $display("Reading data is done...%x", dout);
end
endtask

initial begin
  new_rx_data = 1'b0;
  forever begin
    uart_master.get_serial(`BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8);
    @(posedge clk) new_rx_data = 1;
    @(posedge clk) new_rx_data = 0;
  end // forever
end // initial


// ------------------------------------------------------------------------------------------------------
// Register Mapping for Work Format
// ------------------------------------------------------------------------------------------------------
assign mem = { // data
8'hf6, 8'h66, 8'h3e, 8'h5b, 8'h7b, 8'h7e, 8'hc8, 8'h16,
8'h00, 8'h02, 8'h6d, 8'hd8, 8'h00, 8'h02, 8'h55, 8'h5f,
8'hc1, 8'h6f, 8'he7, 8'hcb, 8'haf, 8'h81, 8'h7d, 8'h59,
8'h82, 8'hcd, 8'h10, 8'h2a, 8'h53, 8'h41, 8'hc3, 8'hca,
8'hb8, 8'h88, 8'h35, 8'h94, 8'h83, 8'h40, 8'h5b, 8'h94,
8'hc0, 8'h46, 8'h69, 8'h0c, 8'hd3, 8'h9f, 8'hff, 8'h6d,
8'hd9, 8'h75, 8'h8e, 8'h63, 8'h5c, 8'he9, 8'h17, 8'hdd,
8'h07, 8'h03, 8'h4c, 8'hc5, 8'he6, 8'h68, 8'hd7, 8'h02,
8'h00, 8'h02, 8'h6d, 8'hd8, 8'h00, 8'h02, 8'h55, 8'h5f,
8'hc1, 8'h6f, 8'he7, 8'hcb, 8'haf, 8'h81, 8'h7d, 8'h59,
8'h82, 8'hcd, 8'h10, 8'h2a, 8'h53, 8'h41, 8'hc3, 8'hca,
8'hf6, 8'h66, 8'h3e, 8'h5b, 8'h7b, 8'h7e, 8'hc8, 8'h16,
8'hb8, 8'h88, 8'h35, 8'h94, 8'h83, 8'h40, 8'h5b, 8'h94,
8'hc0, 8'h46, 8'h69, 8'h0c, 8'hd3, 8'h9f, 8'hff, 8'h6d,
8'hd9, 8'h75, 8'h8e, 8'h63, 8'h5c, 8'he9, 8'h17, 8'hdd,
8'h07, 8'h03, 8'h4c, 8'hc5, 8'he6, 8'h68, 8'hd7, 8'h02
};



endmodule