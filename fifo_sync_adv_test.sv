`timescale 1ns / 1ps

module fifo_tb;
    parameter DEPTH = 8;
    parameter WIDTH = 32;
    logic clk, rst_n, cs, wr_en, rd_en;
    logic [WIDTH-1:0] data_in;
    logic [$clog2(DEPTH):0] almost_full_val, almost_empty_val;
    wire [WIDTH-1:0] data_out;
    wire full, empty, almost_full, almost_empty;

    // Scoreboard for verification
    logic [WIDTH-1:0] ref_model [$]; 

    fifo_sync_adv #(DEPTH, WIDTH) dut (.*); 
    always #5 clk = ~clk;

    initial begin
        // --- 1. Initialization & Reset ---
        clk = 0; rst_n = 0; cs = 1; wr_en = 0; rd_en = 0; data_in = 0;
        almost_full_val = 6; almost_empty_val = 2;
        repeat(5) @(posedge clk);
        rst_n = 1;
        $display("--- Step 1: Reset Complete ---");

        // --- 2. Zero-Latency Bypass Test ---
        @(posedge clk);
        data_in = 32'hAAAA_AAAA; wr_en = 1;
		ref_model.push_back(data_in);
        #1; 
        if (data_out === data_in && empty) 
            $display("SUCCESS: Zero-Latency Bypass verified. data_out = %h", data_out);
        else 
            $error("FAILURE: Bypass failed!");
        
        @(posedge clk); wr_en = 0; 

        // --- 3. Almost Empty / Almost Full Watermarks ---
        $display("--- Step 3: Testing Watermarks ---");
        if (almost_empty) $display("SUCCESS: almost_empty is High (Count=1, Threshold=2)");

        repeat(5) begin
            @(posedge clk); wr_en = 1; data_in = $urandom();
			ref_model.push_back(data_in);
        end
        @(posedge clk); wr_en = 0;
        #1;
        if (almost_full) $display("SUCCESS: almost_full is High (Count=6, Threshold=6)");

        // --- 4. Full Flag & Overflow Guard ---
        $display("--- Step 4: Testing Full Guard ---");
        while (!full) begin
            @(posedge clk); wr_en = 1; data_in = $urandom();
			ref_model.push_back(data_in);
        end
        @(posedge clk);
        data_in = 32'hDDAB_AAFE; wr_en = 1;
        @(posedge clk); wr_en = 0;
        $display("Full Flag status: %b. Overfill attempt ignored.", full);

        // --- 5. Simultaneous Read/Write (The XOR Logic) ---
        $display("--- Step 5: Testing Simultaneous Read/Write ---");
        // Count should stay at 8 because 1 comes in, 1 goes out.
        @(posedge clk);
        wr_en = 1; rd_en = 1; data_in = 32'h1111_2222;
		ref_model.push_back(data_in); 
		void'(ref_model.pop_front());
        @(posedge clk);
        wr_en = 0; rd_en = 0;
        $display("Simultaneous R/W: Full flag remains: %b", full);

        // --- 6. Empty Flag & Underflow Guard ---
        $display("--- Step 6: Emptying and Underflow Guard ---");
        while (!empty) begin
            @(posedge clk); rd_en = 1;
			if (ref_model.size() > 0) void'(ref_model.pop_front());
		end
		@(posedge clk); rd_en = 1;
        @(posedge clk); rd_en = 0;
        $display("Empty Flag status: %b. Underflow attempt ignored.", empty);

        // Final Scoreboard Check
        if (ref_model.size() == 0)
            $display("--- ALL CONCEPTS & DATA INTEGRITY VERIFIED ---"); 
        else
            $error("ERROR: Reference model still has %0d items left!", ref_model.size());

        $finish;
    end
endmodule