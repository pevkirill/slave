`timescale 1ns/1ns
module test_tb;


    bit clk_i;
    bit rst_n;
    logic [4:0] master_burstcount;
    logic master_waitrequest;
    logic [31:0] master_address;
    logic master_write;
    logic [31:0] master_writedata;

    logic [31:0] control_write_base;

    bit control_go;
    // user logic inputs and outputs
    bit user_write_buffer;
    bit [32-1:0] user_buffer_data;
    logic  user_buffer_full;
    logic control_done;

    logic [3:0] avms_byteenable;

    burst_slave_write #(.DW(32), .AW(32), .BURSTCOUNTWIDTH(4), .BYTEENABLEWIDTH(4)) i_burst_slave_write (
        .clk_i                  (clk_i                  ),
        .rst_n                  (rst_n                  ),
        .avms_address           (master_address         ),
        .avms_burstcount        (master_burstcount      ),
        .avms_byteenable        (avms_byteenable        ),
        .avms_write             (master_write           ),
        .avms_writedata         (master_writedata       ),
        .avms_waitrequest       (master_waitrequest     )
    );


    burst_write_master #(
        .DATAWIDTH      (32),
        .MAXBURSTCOUNT  (16), 
        .BURSTCOUNTWIDTH(5 ),
        .BYTEENABLEWIDTH(4 ),
        .ADDRESSWIDTH   (32),
        .FIFODEPTH      (32),
        .FIFODEPTH_LOG2 (5 ),
        .FIFOUSEMEMORY  (0 )
    ) i_burst_write_master (
        .clk                   (clk_i             ),
        .reset                 (!rst_n            ),
        .control_fixed_location(1'b0              ),
        .control_write_base    (control_write_base), //'0
        .control_write_length  (32'h1c           ), //16'h100
        .control_go            (control_go        ),
        .control_done          (control_done      ),
        .user_write_buffer     (user_write_buffer ),
        .user_buffer_data      (user_buffer_data  ),
        .user_buffer_full      (user_buffer_full  ),
        .master_waitrequest    (master_waitrequest),
        .master_address        (master_address    ),
        .master_write          (master_write      ),
        .master_byteenable     (avms_byteenable   ),
        .master_writedata      (master_writedata  ),
        .master_burstcount     (master_burstcount )
    );

    always #5 clk_i = !clk_i;
    initial begin
        rst_n =0;
        repeat (10) @(posedge clk_i) #1;
        rst_n =1;
        user_buffer_data = '0;

        repeat (10) @(posedge clk_i) #1;
        control_go = 1;
        control_write_base = 32'd0;
        repeat (1) @(posedge clk_i) #1;
        control_go = 0;
        repeat (20) @(posedge clk_i) #1;
        while(!control_done) begin
            if(user_buffer_full == 0) begin
                user_write_buffer = 1;
                user_buffer_data++;
            end else begin
                user_write_buffer = 0;
            end
            repeat (1) @(posedge clk_i) #1;
        end

        repeat (10) @(posedge clk_i) #1;
        control_go = 1;
        control_write_base = 32'd12;
        repeat (1) @(posedge clk_i) #1;
        control_go = 0;
        repeat (20) @(posedge clk_i) #1;
        while(!control_done) begin
            if(user_buffer_full == 0) begin
                user_write_buffer = 1;
                user_buffer_data++;
            end else begin
                user_write_buffer = 0;
            end
            repeat (1) @(posedge clk_i) #1;
        end


        #1000;
        $stop;
    end
endmodule