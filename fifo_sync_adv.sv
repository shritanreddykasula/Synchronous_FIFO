module fifo_sync_adv
	#(parameter fifo_depth = 8, data_width = 32)
	(
		input logic clk, rst_n, cs, wr_en, rd_en, [data_width-1:0] data_in,
		input logic [$clog2(fifo_depth):0] almost_full_val, almost_empty_val,
		output logic full, empty, almost_full, almost_empty, [data_width-1:0] data_out
	);
	
	localparam fifo_depth_log = $clog2(fifo_depth);
	logic [data_width-1:0] FIFO [fifo_depth];
	logic [fifo_depth_log:0] wr_ptr, rd_ptr;
	logic [fifo_depth_log:0] count;
	
	// --- 1. Counter & Clock Gating Logic
	always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n) begin
				count <= 0;
			end
			else if (cs && ((wr_en && !full)^(rd_en && !empty))) begin
				if(wr_en) count <= count + 1'b1;
				else count <= count - 1'b1;
			end
		end
		
	// --- 2. Pointer Logic
	always_ff @(posedge clk or negedge rst_n)
		begin
			if(!rst_n) begin
				wr_ptr <= 0;
				rd_ptr <= 0;
			end
			else if (cs) begin
				if(wr_en && !full) wr_ptr <= wr_ptr + 1'b1;
				if(rd_en && !empty) rd_ptr <= rd_ptr + 1'b1;
			end
		end
		
	// --- 3. Memory Write (Storage)
	always_ff @(posedge clk)
		begin
			if(cs && wr_en && !full) begin
				FIFO[wr_ptr[fifo_depth_log-1:0]] <= data_in;
			end
		end
		
	// --- 4. Zero-Latency Bypass & Read MUX
	always_comb
		begin
			if(empty && wr_en) begin
				data_out = data_in;
			end
			else begin
				data_out = FIFO[rd_ptr[fifo_depth_log-1:0]];
			end
		end

	// --- 5. Status & Watermark Logic
	always_comb begin
		empty = (count == 0);
		full = (count == fifo_depth);
		almost_empty = (count <= almost_empty_val);
		almost_full = (count >= almost_full_val);
	end
	
endmodule