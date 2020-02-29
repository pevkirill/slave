
module burst_slave_write #(
	parameter DW              = 32,
	parameter AW              = 16,
	parameter BURSTCOUNTWIDTH = 4 ,
	parameter BYTEENABLEWIDTH = 4
) (
	input                              clk_i                  , // Clock
	input                              rst_n                  , // Asynchronous reset active low
	// master --> slave
	input  logic [             AW-1:0] avms_address           ,
	input  logic [BURSTCOUNTWIDTH-1:0] avms_burstcount        ,
	input  logic                       avms_write             ,
	input  logic [             DW-1:0] avms_writedata         ,
	input  logic [BYTEENABLEWIDTH-1:0] avms_byteenable        ,
	// slave --> master
	output logic                       avms_waitrequest = '0     
);

	logic [AW-1:0][DW-1:0] memory    ;
	logic [AW-1:0]         pc_address;
	logic [DW-1:0] data_reg;
	logic                  shift_reg ;
	logic [4:0] counter;
	logic [4:0] cnt_reg;


	enum logic [1:0] {s0, s1} state;

always_ff @(posedge clk_i or negedge rst_n) begin : proc_memory
	if(~rst_n) begin
		memory <= '0;
	end else if(shift_reg) begin
		for (int i = 0; i < BYTEENABLEWIDTH; i++) begin
			if (avms_byteenable[i]) begin
				memory[pc_address][i*8+:8] <= data_reg[i*8+:8];
			end
		end
	end
end

always_ff @(posedge clk_i or negedge rst_n) begin : proc_data_reg
	if(~rst_n) begin
		data_reg <= '0;
	end else begin
		data_reg <= avms_writedata;
	end
end

always_ff @(posedge clk_i or negedge rst_n) begin : proc_shift_reg
	if(~rst_n) begin
		shift_reg <= '0;
	end else begin
		shift_reg <= avms_write;
	end
end

always_ff @(posedge clk_i or negedge rst_n) begin : proc_state
	if(~rst_n) begin
		state      <= s0;
		pc_address <= '0;
		counter    <= '0;
		cnt_reg    <= '0;
	end else begin
		case (state)
			s0 : begin 
				if (avms_write) begin
					state      <= s1;
					pc_address <= avms_address;
					counter    <= counter + 1;
					cnt_reg    <= avms_burstcount;
				end
			end
			s1 : begin 
				if (counter == cnt_reg) begin
					state      <= s0;
					counter    <= '0;
				end else if (avms_write) begin
					pc_address <= pc_address + 1;
					counter    <= counter + 1;
				end
			end
			default : state <= state;
		endcase
	end
end

endmodule
