`timescale 1ns / 1ps

module ass_uart_serdes(
    input   clk,
    input   rstb,
    input   ser_in,
    input   [6:0]   dev_adr,
    input   [7:0]   rdata,

    output          we,
    output  [6:0]   addr,
    output  [7:0]   wdata,
    output          ser_out
);
// combinational logic in "always" is better than in "assign"
/////////////////////  Rising,Falling_Edge_Detect  /////////////////////
reg [1:0]   detection;
reg         falling_detect;
//reg         rising_detect;

always@(posedge clk or negedge rstb) begin
    if(!rstb) detection <= 1'b0;
    else begin
        case(detection)
            2'b10: begin    //falling
                falling_detect <= 1'b1;
                detection[1] <= detection[0];
                detection[0] <= ser_in;
            end
            /*2'b01: begin    //rising
                rising_detect <= 1;
                detection[1] <= detection[0];
                detection[0] <= ser_in;
            end*/
            default: begin
                detection[1] <= detection[0];
                detection[0] <= ser_in;
                falling_detect <= 0;
                //rising_detect <= 0;
            end
        endcase
    end
end


//////////////////////  baudrate_gen  //////////////////////
parameter D_BAUD_FREQ = 144;       // Baudrate = 115200 (based on a 40MHz clock)
parameter D_BAUD_LIMIT = 2981;

reg [15:0]  sampling_cnt;
reg         sampling_tick;
wire        sampling;


always@(posedge clk or negedge rstb) begin
    if(!rstb) begin
        sampling_cnt <= 1'b0;
        sampling_tick <= 1'b0;
    end
    else begin
        if(sampling_cnt >= D_BAUD_LIMIT) begin
            sampling_cnt <= sampling_cnt - D_BAUD_LIMIT;
            sampling_tick <= 1'b1;
        end
        else begin
            sampling_cnt <= sampling_cnt + D_BAUD_FREQ;
            sampling_tick <= 1'b0;
        end
    end
end

assign sampling = sampling_tick;


////////////////////////  RX - TX  ////////////////////////
localparam   IDLE = 2'b0;
localparam   START = 2'b01;
localparam   DATA = 2'b10;
localparam   STOP = 2'b11;

reg [7:0]   RX, TX;
reg [3:0]   RX_data_cnt, TX_data_cnt;
reg [1:0]   RX_state, TX_state;
reg [2:0]   RX_8bit_trans, TX_8bit_trans;
reg         valid_RX;
reg         valid_TX;
reg         serial_out;
reg         ready_TX;
reg [7:0]   TX_data_in;


////////////////////////  RX  ////////////////////////
always@(posedge clk or negedge rstb) begin
    if(!rstb) begin
        RX <= 1'b0;
        RX_data_cnt <= 1'b0;
        RX_state <= 1'b0;
        RX_8bit_trans <= 1'b0;
        valid_RX <= 1'b0;
    end
    else begin
        valid_RX <= 1'b0;
        case(RX_state)
            IDLE: begin
                if(falling_detect) begin
                    RX_state <= START;
                    RX <= 1'b0;
                end
            end

            START: begin
                if(sampling) begin
                    if(RX_data_cnt == 4'd15) begin
                        RX_data_cnt <= 1'b0;
                        RX_state <= DATA;
                    end
                    else RX_data_cnt <= RX_data_cnt + 1'b1;
                end     
            end

            DATA: begin
                if(sampling) begin
                    if(RX_data_cnt == 4'd7) begin
                        RX <= {ser_in, RX[7:1]};
                        RX_data_cnt <= RX_data_cnt + 1'b1;
                    end
                    else if(RX_data_cnt == 4'd15) begin
                        RX_data_cnt <= 1'b0;
                        if(RX_8bit_trans == 3'd7) begin
                            RX_state <= STOP;
                            RX_8bit_trans <= 1'b0;
                        end
                        else RX_8bit_trans <= RX_8bit_trans + 1'b1;                        
                    end
                    else RX_data_cnt <= RX_data_cnt + 1'b1;
                end               
            end

            STOP: begin
                if(sampling) begin
                    if(RX_data_cnt == 4'd15) begin
                            RX_data_cnt <= 1'b0;
                            RX_state <= IDLE;
                            valid_RX <= 1'b1;
                    end
                    else RX_data_cnt <= RX_data_cnt + 1'b1;
                end    
            end
        endcase
    end
end


////////////////////////  TX  ////////////////////////
always@(posedge clk or negedge rstb) begin
    if(!rstb) begin
        TX <= 1'b0;
        TX_data_cnt <= 1'b0;
        TX_state <= 1'b0;
        TX_8bit_trans <= 1'b0;
        serial_out <= 1'b1;
        valid_TX <= 1'b0;
    end
    else begin
        valid_TX <= 1'b0;
        case(TX_state)
            IDLE: begin
                if(ready_TX) begin
                    TX_state <= START;
                    TX <= TX_data_in;
                    serial_out <= 1'b0;
                end
                else serial_out <= 1'b1;
            end

            START: begin
                serial_out <= 1'b0;
                if(sampling) begin
                    if(TX_data_cnt == 4'd15) begin
                        TX_data_cnt <= 1'b0;
                        TX_state <= DATA;
                        serial_out <= TX[0];        // for match the timing, it is proceeded in advance
                    end
                    else TX_data_cnt <= TX_data_cnt + 1'b1;
                end
            end

            DATA: begin
                serial_out <= TX[0];                // data have to tranfer in every clock
                if(sampling) begin
                    if(TX_data_cnt == 4'd15) begin
                        if(TX_8bit_trans == 3'd7) begin
                            TX_state <= STOP;
                            TX_8bit_trans <= 1'b0;
                            TX_data_cnt <= 1'b0;
                            TX <= 1'b0;
                            serial_out <= 1'b1;        // for match the timing, it is proceeded in advance
                        end
                        else begin
                            TX_data_cnt <= 1'b0;
                            TX_8bit_trans <= TX_8bit_trans + 1'b1;
                            TX <= TX >> 1'b1;
                        end                        
                    end
                    else TX_data_cnt <= TX_data_cnt + 1'b1;
                end                  
            end

            STOP: begin
                serial_out <= 1'b1;
                if(sampling) begin
                    if(TX_data_cnt == 4'd15) begin
                        TX_data_cnt <= 1'b0;
                        TX_state <= IDLE;
                        valid_TX <= 1'b1;        
                    end
                    else TX_data_cnt <= TX_data_cnt + 1'b1;
                end
            end
        endcase
    end
end


/////////////////  Packet FSM  /////////////////
localparam P_START   = 3'd0; // 0x00 Standby
localparam P_CMD     = 3'd1; // 0x20(Write) / 0x10(Read)
localparam P_ID      = 3'd2; // ID Check
localparam P_ADDR    = 3'd3; // save start address
localparam P_LEN     = 3'd4; // save transmission length
localparam P_WRITE   = 3'd5; // receiving Write Data and Register File Writing
localparam P_READ    = 3'd6; // read RF and trigger transmission to TX
localparam P_TX_WAIT = 3'd7; // wait until TX has finished sending everything

reg [2:0]   p_state;
reg [7:0]   cmd_reg;
reg [6:0]   cur_addr;
reg [7:0]   len_reg;
reg [7:0]   count;
reg         we_reg;
reg [6:0]   addr_reg;
reg [7:0]   wdata_reg;
reg         read_delay;

always @(posedge clk or negedge rstb) begin
    if(!rstb) begin
        p_state <= P_START;
        cmd_reg <= 8'd0;
        cur_addr <= 7'd0;
        len_reg <= 8'd0;
        count <= 8'd0;
        we_reg <= 1'b0;
        addr_reg <= 7'd0;
        wdata_reg <= 8'd0;
        ready_TX <= 1'b0;
        TX_data_in <= 8'd0;
        read_delay <= 1'b0;
    end
    else begin
        we_reg <= 1'b0;   // we usually have 0
        ready_TX <= 1'b0; // ready_TX is a 1-clock pulse
        case(p_state)
            P_START: begin
                if(valid_RX && RX == 8'h00) p_state <= P_CMD;
            end

            P_CMD: begin
                if(valid_RX) begin
                    cmd_reg <= RX;
                    p_state <= P_ID;
                end
                else cmd_reg <= 1'b0;
            end

            P_ID: begin
                if(valid_RX) begin
                    if(RX[6:0] == dev_adr) p_state <= P_ADDR;
                    else                   p_state <= P_START; // cancel if this isn't my ID
                end
            end

            P_ADDR: begin
                if(valid_RX) begin
                    cur_addr <= RX[6:0]; // save Start Address
                    p_state <= P_LEN;
                end
                else cur_addr <= 1'b0;
            end

            P_LEN: begin
                if(valid_RX) begin
                    len_reg <= RX;
                    count <= 8'd0;          // count 'zero' initialization
                    if(cmd_reg == 8'h20) begin
                        p_state <= P_WRITE; // Write mode 
                    end
                    else if(cmd_reg == 8'h10) begin
                        addr_reg <= cur_addr; // point the first address to read
                        read_delay <= 1'b0;
                        p_state <= P_READ;    // Read mode
                    end
                    else p_state <= P_START;
                end
                else len_reg <= 1'b0;
            end

            // [Write mode]: every time a byte is received on the RX (valid_RX == 1), it is sequentially stored in the RF
            P_WRITE: begin
                if(valid_RX) begin
                    if(count == len_reg - 1) begin
                        p_state <= P_START; // all the requested bytes have been wirtten -> Done!
                    end
                    else begin
                        we_reg <= 1'b1;
                        addr_reg <= cur_addr;
                        wdata_reg <= RX;
                        cur_addr <= cur_addr + 1'b1;
                        count <= count + 1'b1;
                    end
                end
                else wdata_reg <= 1'b0;
            end

            // [Read mode]: read rdata from the RF and begin transmission to the TX (wait for one RF clock cycle)
            P_READ: begin
                if(!read_delay) begin       // "read_delay" is used to sync the operation of ass_uart_rf. it's exactly 1 cycle.
                    read_delay <= ~read_delay;
                end
                else begin
                    ready_TX <= 1'b1;
                    TX_data_in <= rdata;    // from the RF
                    read_delay <= 1'b0;
                    p_state <= P_TX_WAIT;
                end
            end

            P_TX_WAIT: begin
                if(valid_TX) begin // when TX has finished transmitting 1 byte
                    count <= count + 1'b1;
                    cur_addr <= cur_addr + 1'b1;
                    if(count == len_reg - 1) begin
                        p_state <= P_START; // all the requested bytes have been sent -> Done!
                    end
                    else begin
                        addr_reg <= cur_addr + 1'b1; // to prevent a 1-clock-cycle delay
                        read_delay <= 1'b0;
                        p_state <= P_READ;        // to the next byte transmission
                    end
                end
            end
        endcase
    end
end

assign we = we_reg;
assign addr = addr_reg;
assign wdata = wdata_reg;
assign ser_out = serial_out;

endmodule