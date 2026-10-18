
`timescale 1ns/10ps

module tb ();


reg clk;
reg rstb;

wire [6:0] dev_adr = 7'h5A;


initial clk = 1'b0;
always #(12.5) clk = ~clk;

initial begin
  rstb = 1'b1;
  repeat(8) @(negedge clk);
  rstb = 1'b0;
  repeat(2) @(negedge clk);
  rstb = 1'b1;
end //


uart_master uart_master (
  .clk     (clk    ),
  .ser_in  (ser_in ),
  .ser_out (ser_out)
);

// Design Under Test
ass_uart_slave dut (
  .clk     (clk     ),
  .rstb    (rstb    ),
  .ser_in  (ser_in  ),
  .ser_out (ser_out ),
  .dev_adr (dev_adr )
);


uart_packet uart_packet (.clk(clk));

reg [8*16-1:0] read_data;

initial begin
	$shm_open("wave");
	$shm_probe("ASM", tb);

end // 


// running DUT module

initial begin

  read_data = 128'b0;

  repeat(200) @(posedge clk);

  $display("Generating Write Packet...");
  uart_packet.write_packet(dev_adr, 0, 32); // work format

  #10000;

  $display("Generating Read Packet...");
  uart_packet.read_packet(dev_adr, 3, 16, read_data);

  #20000;

  $finish;


end //  initial


endmodule
